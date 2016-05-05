

---扩展滚动层
local ScrollViewEx = class(...,function()
	local sp = ccui.ScrollView:create()
	sp._super_addChild = sp.addChild
	sp._super_removeChild = sp.removeChild
	sp._super_removeAllChildren = sp.removeAllChildren
	return sp
end)
regClass(...,ScrollViewEx,true)

ScrollViewEx.ALIGNMENT_LEFT = 1		-- 靠左
ScrollViewEx.ALIGNMENT_CENTER = 2	-- 靠中
ScrollViewEx.ALIGNMENT_RIGHT = 3	-- 靠右
ScrollViewEx.ALIGNMENT_TOP = 4		-- 靠上
ScrollViewEx.ALIGNMENT_BOTTOM = 5	-- 靠下

function ScrollViewEx:ctor(width,height,dir,wrap)
	self:setTouchEnabled(true)	-- 可触摸
	self:setBounceEnabled(true)	-- 回弹
	self:setDirection(tonumber(dir) or ccui.ScrollViewDir.both) -- 移动方向
	self:setAnchorPoint(cc.p(0,0))
	self:setContentSize(cc.size(tonumber(width) or 200, tonumber(height) or 100))
	self:setInnerContainerSize(self:getContentSize())

	self._halign = ScrollViewEx.ALIGNMENT_LEFT --横向对齐方式
	self._valign = ScrollViewEx.ALIGNMENT_CENTER --纵向对齐方式
	self._wrap = toboolean(wrap) --是否自动换行
	self._hpadding = 4 --对象之间的横向间隔
	self._vpadding = 4 --对象之间的纵向间隔
	self._hmargin = 10 --左右边缘缩进
	self._vmargin = 10 --上下边缘缩进
	
	self._seq_seed = 0

	self._all = {} --所有对象列表
	self._lines = {} --所有行
	self._cline = {} --当前行对象列表
	self._cx = 0 --当前x坐标位置
	self._cy = 0 --当前y坐标位置
	self._ch = 0 --当前行的高度，即当前行最大高度的元素的高度

	--- register enter event
	self:registerScriptHandler(function(event)
		if event=="enter" then
			--- schedule update event
			--- 因底层ScrollView::onEnter()事件后会调用scheduleUpdate()，将会冲掉其他方式的schedule调用
			--- 所以不能使用ScrollView::scheduleUpdateWithPriorityLua()方法
			--- 此处使用InnerContainer的scheduleUpdateWithPriorityLua()，但在每次切换场景时，InnerContainer的schedule会丢失
			--- 所以此处每次onEner时调用一次scheduleUpdateWithPriorityLua()
			self:getInnerContainer():scheduleUpdateWithPriorityLua(function(dt)
				self:onUpdate(dt)
			end, 0)
		end
	end)

end

--- 重新整理line行的位置（靠右 or 居中）
local function _alignLine(self,line,width)
	if self._halign == ScrollViewEx.ALIGNMENT_LEFT then return end --如果横向对齐方式是向左 则返回
	-- 计算物件大小
	local lw = 0 --当前行所有元素组成的宽度
	for n,chd in ipairs(line) do
		if n>1 then lw = lw + self._hpadding end
		lw = lw + chd:getBoundingBox().width
	end
	-- 放置位置
	local lcx --当前元素的起始位置
	if self._halign == ScrollViewEx.ALIGNMENT_RIGHT then -- 向右对齐
		lcx = width-lw-self._hmargin -- 字体最左侧x位置 = 容器剩余宽度 - 字体总长度 - 内边距（默认width 一定比lw大）
	else -- 居中对齐
		lcx = (width-lw)/2 --字体最左侧x位置 = （容器剩余宽度 - 字体总长度）/ 2
	end

	for n,chd in ipairs(line) do
		-- 加上行间距
		if n>1 then lcx = lcx + self._hpadding end 
		
		local px,py = chd:getPosition()
		local pahr = chd:getAnchorPoint()
		local pbox = chd:getBoundingBox()
		px = lcx + pbox.width*pahr.x -- 显示位置 = 字体最左侧 + 重心位置
		chd:setPosition(px,py)
		lcx = lcx + pbox.width
	end
end

--- 整理刚添加的元素（
local function _arrangeAdd(self,child)
	table.insert(self._all,child)

	if child._br then --强制换行
		table.insert(self._lines,self._cline) -- 把当前行对象列表保存到所有行中
		self._cline = {}
		self._cx = 0
		self._cy = self._cy + self._ch + self._vpadding
		self._ch = 0
		return
	end

	local size = self:getInnerContainerSize()
	local anchor = child:getAnchorPoint()
	local box = child:getBoundingBox()
	local w = box.width -- 元素宽度
	local h = box.height -- 元素高度

	local x = self._cx + w * anchor.x --该对象的x坐标
	local nx = self._cx + w + self._hpadding --下一个元素插入x坐标位置
	if nx+self._hmargin*2-self._hpadding>size.width then --超过画幅宽度
		if self._wrap then --自动换行
			table.insert(self._lines,self._cline)
			self._cline = {}
			x = w * anchor.x --该对象的x坐标
			self._cx = w + self._hpadding
			self._cy = self._cy + self._ch + self._vpadding
			self._ch = 0
		else --无需自动换行，则自动扩展宽度
			-- 如果是向左对齐的就直接加长容器宽度
			self._cx = nx
			size.width = nx+self._hmargin*2-self._hpadding
			self:setInnerContainerSize(size)
			-- 如果是向右对齐或者居中则需要将所有行及当前行都相应调整	
			if self._halign ~= ScrollViewEx.ALIGNMENT_LEFT then
				for _,line in ipairs(self._lines) do
					_alignLine(self,line,size.width)
				end
				_alignLine(self,self._cline,size.width)
			end
		end
	else
		self._cx = nx
	end

	if h>self._ch then --当插入对象的高超过当前行高，需调整高度
		self._ch = h
		for _,chd in ipairs(self._cline) do --重设当前行的所有元素的y坐标
			local px,py = chd:getPosition()
			local pahr = chd:getAnchorPoint()
			local pbox = chd:getBoundingBox()
			if self._valign==ScrollViewEx.ALIGNMENT_TOP then -- py 为重心距离上边距的长度
				py = self._cy + pbox.height*(1-pahr.y) -- 当靠上对齐时，py = 当前位置 + 重心到上边距离
			elseif self._valign==ScrollViewEx.ALIGNMENT_BOTTOM then
				py = self._cy + self._ch - pbox.height*pahr.y -- 当靠下对齐时，py = 当前位置 + 重心到下边距离
			else
				py = self._cy + self._ch/2 + pbox.height/2 - pbox.height*pahr.y -- 当垂直居中时， py = 当前位置 + 行的中心 + 重心到中心的距离
			end
			chd:setPosition(px,size.height-py-self._vmargin) -- 显示高度 = 容器高度 - py - 内边距
		end
	end

	-- 计算下一个y坐标的位置
	local ny = self._cy + self._ch + self._vpadding
	-- 当下一个y坐标大于当前画幅高度时
	if ny+self._vmargin*2-self._vpadding>size.height then --需自动扩展高度
		local dh = ny+self._vmargin*2-self._vpadding-size.height --所有元素需上移的高度
		for _,chd in ipairs(self._all) do
			if not chd._br then
				local px,py = chd:getPosition()
				chd:setPosition(px,py+dh) --上移
			end
		end
		size.height = ny+self._vmargin*2-self._vpadding
		self:setInnerContainerSize(size)
	end

	-- 设置当前对象的垂直位置（靠上 or 居中 or 靠下）
	local y --得出该对象的y坐标
	if self._valign==ScrollViewEx.ALIGNMENT_TOP then
		y = self._cy + h * (1-anchor.y) -- 当前y坐标 + 锚点到上边距的长度 
	elseif self._valign==ScrollViewEx.ALIGNMENT_BOTTOM then
		y = self._cy + self._ch - h*anchor.y -- 当前y坐标 + 上内边距 + 锚点到上边距的高度
	else
		y = self._cy + self._ch/2 + h/2 - h*anchor.y -- 当前y坐标 + （高度 + 内边距）/2 - 锚点到下边距高度
	end
	child:setPosition(x+self._hmargin,size.height-y-self._vmargin) -- 原件y坐标 = 画布高度 - y - 内边距？
	table.insert(self._cline,child)
	-- 如果不是考左，再执行一次_alignLine()
	if self._halign ~= ScrollViewEx.ALIGNMENT_LEFT then 
		_alignLine(self,self._cline,size.width)
	end
end

---重新整理所有对象的位置
function ScrollViewEx:rearrange()
	local org_pos = self:getInnerContainerPositionY() --记录当前滚动位置
	local all = self._all
	self._all = {}
	self._lines = {}
	self._cline = {}
	self._cx = 0 --当前x坐标位置
	self._cy = 0 --当前y坐标位置
	self._ch = 0 --当前行的高度，即当前行最大高度的元素的高度
	self:setInnerContainerSize(self:getContentSize())

	local count = #all
	if count>0 then
		local joins = {}
		local cur_seq = nil
		local cur_color = nil
		local cur_opacity = nil
		local cur_font_name = nil
		local cur_font_size = nil
		local cur_zorder = nil
		local cur_tag = nil
	
		for i=1,count do
			local seq = all[i]._split_seq
			if seq~=cur_seq and #joins>0 then
				local txt = table.concat(joins)
				self:addText(txt,cur_font_name,cur_font_size,cur_color,cur_opacity,cur_zorder,cur_tag,cur_seq)
				joins = {}
				cur_seq = nil
				cur_color = nil
				cur_opacity = nil
				cur_font_name = nil
				cur_font_size = nil
				cur_zorder = nil
				cur_tag = nil
			end
			
			if seq then
				table.insert(joins,all[i]:getString())
				cur_seq = seq
				cur_color = all[i]:getColor()
				cur_opacity = all[i]:getOpacity()
				cur_font_name = all[i]._font_name
				cur_font_size = all[i]._font_size
				cur_zorder = all[i]:getLocalZOrder()
				cur_tag = all[i]:getTag()
				self._super_removeChild(self,all[i],true)
			else
				_arrangeAdd(self,all[i])
			end
		end
	
		if #joins>0 then
			local txt = table.concat(joins)
			self:addText(txt,cur_font_name,cur_font_size,cur_color,cur_opacity,cur_zorder,cur_tag,cur_seq)
		end
	end
	
	self:jumpToPositionY(org_pos)
end

---增加元素
function ScrollViewEx:addChild(child,zOrder,tag)
	self._super_addChild(self,child,tonumber(zOrder) or 0, tonumber(tag) or 0)
	_arrangeAdd(self,child)
end

---指定位置插入元素
function ScrollViewEx:insertChild(index,child,zOrder,tag)
	self:lazyInsertChild(index,child,zOrder,tag)
	self:rearrange()
end

---指定位置延时模式插入元素，插入完毕后需显式调用rearrange()
function ScrollViewEx:lazyInsertChild(index,child,zOrder,tag)
	self._super_addChild(self,child,tonumber(zOrder) or 0, tonumber(tag) or 0)
	table.insert(self._all,index,child)
end

---插入换行
function ScrollViewEx:insertBreakLine(index)
	self:lazyInsertBreakLine(index)
	self:rearrange()
end

---插入换行
function ScrollViewEx:lazyInsertBreakLine(index)
	table.insert(self._all,index,{_br=true})
end

---移除指定元素
function ScrollViewEx:removeChild(child,cleaup)
	self._super_removeChild(self,child,cleaup==nil and true or toboolean(cleaup))
	table.removeValue(self._all,child)
	self:rearrange()
end

---清空所有元素
function ScrollViewEx:removeAllChildren()
	self:_super_removeAllChildren()
	self._all = {} --清空
	self:rearrange()
end

local function newLabel(text,font_name,font_size)
	local lab
	local exists = cc.FileUtils:getInstance():isFileExist(font_name)
	if exists then
		local ttfConfig = {}
		ttfConfig.fontFilePath = font_name
		ttfConfig.fontSize = font_size
		lab = cc.Label:createWithTTF(ttfConfig, text)
	else
		lab = cc.Label:createWithSystemFont(text, font_name, font_size)
	end
	lab._font_name = font_name
	lab._font_size = font_size
	return lab
end

local function handleSplitTextAndAdd(self,fontText,text,font_name,font_size,color,opacity,zorder,tag,seq)
	local width = self:getInnerContainerSize().width --空间宽度
	fontText:setString(text)
	local word_width = fontText:getContentSize().width --文字总宽度
	local left_width = width - self._hmargin*2 - self._cx --剩余宽度
	if word_width<=left_width then --够宽，则直接加入
		if color then fontText:setColor(color) end
		if opacity then fontText:setOpacity(opacity) end
		fontText._split_seq = seq --记录拆分记号，重新整理时将会合并相邻的相同记号的文本元素
		self:addChild(fontText,zorder,tag)
	else --当前行空间不足，则拆开多个
		local total = my.EtcFuns:utf8_strlen(text) --字符数量
		local left_count = math.floor(total * left_width/word_width)
		if left_count<=0 then --不够1个字空间，则按换行计算
			left_width = width - self._hmargin*2 --剩余宽度
			left_count = math.floor(total * left_width/word_width) --换行后重新计算可容纳多少个字
			if left_count<=0 then left_count=1 end --新行至少一个字，以避免死循环
		end

		local left_words = my.EtcFuns:utf8_substr(text,0,left_count)
		
		--检查是否还可以容纳更多的字符
		while left_count+1<=total do
			local add_words = my.EtcFuns:utf8_substr(text,0,left_count+1)
			fontText:setString(add_words)
			local add_width = fontText:getContentSize().width
			if add_width<=left_width then
				left_count = left_count + 1
				left_words = add_words
			else
				break
			end
		end
		
		local txt = newLabel(left_words,font_name,font_size)
		if color then txt:setColor(color) end
		if opacity then txt:setOpacity(opacity) end
		txt._split_seq = seq --记录拆分记号，重新整理时将会合并相邻的相同记号的文本元素
		self:addChild(txt,zorder,tag)

		if left_count<total then
			local cut_words = my.EtcFuns:utf8_substr(text,left_count,total-left_count)
			handleSplitTextAndAdd(self,fontText,cut_words,font_name,font_size,color,opacity,zorder,tag,seq)
		end
	end
end

---添加文本元素，支持自动换行
function ScrollViewEx:addText(text,font_name,font_size,color,opacity,zorder,tag,seq,br)
	if not text or #text==0 then return end

	if string.find(text,"\n",1,true) then --有换行符
		local texts = string.split(text,"\n")
		local tc = #texts
		for i=1,tc do
			self:addText(texts[i],font_name,font_size,color,opacity,zorder,tag,seq,i==tc and br or true)
		end
		return
	end

	font_size = font_size or 20
	if not seq then
		self._seq_seed = self._seq_seed + 1
		seq = self._seq_seed
	end
	if self._wrap then --需自动换行，则拆成多个
		local tmp = newLabel(text, font_name, font_size) --用于计算文本宽度
		handleSplitTextAndAdd(self,tmp,text,font_name,font_size,color,opacity,zorder,tag,seq)
	else --不自动换行，直接加入
		local txt = newLabel(text,font_name,font_size)
		if color then txt:setColor(color) end
		if opacity then txt:setOpacity(opacity) end
		txt._split_seq = seq --记录拆分记号，重新整理时将会合并相邻的相同记号的文本元素
		self:addChild(txt,zorder,tag)
	end
	if br then
		self:addBreakLine()
	end
end

---指定位置插入文本元素，支持自动换行
function ScrollViewEx:insertText(index,text,font_name,font_size,color,opacity,zorder,tag,br)
	self:lazyInsertText(index,text,font_name,font_size,color,opacity,zorder,tag,br)
	self:rearrange()
end

---指定位置延时模式插入文本元素，插入完毕后需显式调用rearrange()
function ScrollViewEx:lazyInsertText(index,text,font_name,font_size,color,opacity,zorder,tag,br)
	if not text or #text==0 then return end

	if string.find(text,"\n",1,true) then --有换行符
		local texts = string.split(text,"\n")
		local tc = #texts
		for i=1,tc do
			self:lazyInsertText(index,texts[i],font_name,font_size,color,opacity,zorder,tag,i==tc and br or true)
			index = index + 2
		end
		return
	end

	index = tonumber(index) or 1
	font_size = font_size or 20
	self._seq_seed = self._seq_seed + 1
	local seq = self._seq_seed

	local txt = newLabel(text,font_name,font_size)
	if color then txt:setColor(color) end
	if opacity then txt:setOpacity(opacity) end
	txt._split_seq = seq --记录拆分记号，重新整理时将会合并相邻的相同记号的文本元素

	self._super_addChild(self,txt,tonumber(zorder) or 0, tonumber(tag) or 0)
	table.insert(self._all,index,txt)
	if br then
		table.insert(self._all,index+1,{_br=true})
	end
end

---删除指定第n个强制换行元素，n默认为1
function ScrollViewEx:removeBreakLine(n)
	n = tonumber(n) or 1
	local find = false
	for i,chd in ipairs(self._all) do
		if chd._br then
			if n<=1 then
				table.remove(self._all,i)
				find = true
				break
			else
				n = n - 1
			end
		end
	end
	if find then
		self:rearrange()
	end
end

---删除指定第n行的所有元素，n默认为1
function ScrollViewEx:removeLine(n)
	n = tonumber(n) or 1
	if #self._all==0 then return end

	local fromIndex=1 --当前行其实位置
	local toIndex=#self._all --当前行结束位置
	local line=1 --当前行
	for i,chd in ipairs(self._all) do
		toIndex = i
		if chd._br then --是换行符
			if line==n then
				break
			else
				fromIndex = i + 1
				line = line + 1
			end
		end
	end

	if line==n and toIndex>=fromIndex then
		for i=1,toIndex-fromIndex+1 do
			local chd = table.remove(self._all,fromIndex)
			if not chd._br then
				self._super_removeChild(self,chd,true)
			end
		end
		self:rearrange()
	end
end

---获得总行数
function ScrollViewEx:getLineCount()
	if #self._all==0 then return 0 end

	local line=1 --当前行
	local empty = true --当前行是否为空
	for i,chd in ipairs(self._all) do
		if chd._br then --是换行符
			line = line + 1
			empty = true
		elseif empty then
			empty = false
		end
	end

	if empty then line = line - 1 end
	return line
end

---添加强制换行元素
function ScrollViewEx:addBreakLine()
	_arrangeAdd(self,{_br=true})
end

---添加空白元素
function ScrollViewEx:addSpace(width,height,br)
	local space = cc.Node:create()
	if height then
		space:setContentSize(width,height)
	else
		space:setContentSize(width)
	end
	self:addChild(space)
	if br then
		self:addBreakLine()
	end
end

---指定位置插入空白元素
function ScrollViewEx:insertSpace(index,width,height,br)
	local space = cc.Node:create()
	if height then
		space:setContentSize(width,height)
	else
		space:setContentSize(width)
	end
	self:lazyInsertChild(index,space)
	if br then
		self:insertBreakLine(index+1)
	else
		self:rearrange()
	end
end

---获得指定元素所在位置
function ScrollViewEx:indexOf(child)
	return table.contains(self._all,child)
end

---设置元素在当前行的垂直对齐方式
function ScrollViewEx:setVAlign(align)
	self._valign = tonumber(align) or ScrollViewEx.ALIGNMENT_CENTER
	self:rearrange()
end
function ScrollViewEx:getVAlign()
	return self._valign
end

---设置元素在当前行的水平对齐方式
function ScrollViewEx:setHAlign(align)
	self._halign = tonumber(align) or ScrollViewEx.ALIGNMENT_CENTER
	self:rearrange()
end
function ScrollViewEx:getHAlign()
	return self._halign
end

---横向的对象之间的间隔（列间隔）
function ScrollViewEx:setHPadding(padding)
	self._hpadding = tonumber(padding) or 0
	self:rearrange()
end
function ScrollViewEx:getHPadding()
	return self._hpadding
end

---纵向的对象之间的间隔（行间隔）
function ScrollViewEx:setVPadding(padding)
	self._vpadding = tonumber(padding) or 0
	self:rearrange()
end
function ScrollViewEx:getVPadding()
	return self._vpadding
end

---左右边缘缩进
function ScrollViewEx:setHMargin(margin)
	self._hmargin = tonumber(margin) or 0
	self:rearrange()
end
function ScrollViewEx:getHMargin()
	return self._hmargin
end

---上下边缘缩进
function ScrollViewEx:setVMargin(margin)
	self._vmargin = tonumber(margin) or 0
	self:rearrange()
end
function ScrollViewEx:getVMargin()
	return self._vmargin
end

---是否自动换行
function ScrollViewEx:setAutoWrap(wrap)
	self._wrap = toboolean(wrap)
	self:rearrange()
end
function ScrollViewEx:isAutoWrap()
	return self._wrap
end

---启动显示列表的携程
function ScrollViewEx:startListCoroutine(handler)
	self._list_coro = coroutine.create(handler)
	self._do_listing = true
end

---恢复显示更多列表项的携程
function ScrollViewEx:resumeListCoroutine()
	if self._list_coro then
		self._do_listing = true
	end
end

---暂停显示列表的携程
function ScrollViewEx:pauseListCoroutine()
	self._do_listing = nil
end

function ScrollViewEx:onUpdate(dt)
	if self._list_coro and self._do_listing then
		local ret = coroutine.resume(self._list_coro)
		if not ret or coroutine.status(self._list_coro)=='dead' then --携程已结束或出现错误
			self._list_coro = nil
			self._do_listing = nil
		end
	end
end

function ScrollViewEx:jumpToItem(item)
	local items = self:getChildren()
	local idx = table.contains(items, item)
	if not idx then return end

	local percent = (idx/#items) * 100
	self:jumpToPercentVertical(percent)
end

--- 设置格式
function ScrollViewEx:setStyle(t)
	if type(t) ~= "table" then return end
	local succNum = 0	
	for k, v in pairs(t) do
		if ScrollViewEx["set"..k] then 
			ScrollViewEx["set"..k](self, v)
			succNum = succNum + 1
--		elseif self.__index["set"..k] then 
--			self["__index"]["set"..k](self, v)
		else
			print("Error: Could not find ScrollView:set"..k .. " function.")
		end
	end
	return succNum
end