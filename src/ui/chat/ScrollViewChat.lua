local ScrollViewChat = class( ... , function()
	local sp = ccui.ScrollView:create()
	sp._super_addChild = sp.addChild
	sp._super_removeChild = sp.removeChild
	sp._super_removeAllChildren = sp.removeAllChildren
	return sp
end)
regClass(..., ScrollViewChat, true)

local SC = ScrollViewChat
ScrollViewChat.ALIGNMENT_LEFT = 1		-- 靠左
ScrollViewChat.ALIGNMENT_CENTER = 2	-- 靠中
ScrollViewChat.ALIGNMENT_RIGHT = 3	-- 靠右
ScrollViewChat.ALIGNMENT_TOP = 4		-- 靠上
ScrollViewChat.ALIGNMENT_BOTTOM = 5	-- 靠下

local function checkInherit(sign)
	if not sign then print("Error: the element addChild just now is not inherit from UIElement") end 
end

function SC:ctor(width,height,dir,wrap)
	self:setTouchEnabled(true)
	self:setBounceEnabled(true) -- 回弹
	self:setDirection(tonumber(dir) or ccui.ScrollViewDir.both) -- 移动方向
	self:setAnchorPoint(cc.p(0, 0))
	self:setContentSize(cc.size(tonumber(width) or 200, tonumber(height) or 100))
	self:setInnerContainerSize(self:getContentSize())

	self._halign = SC.ALIGNMENT_LEFT	-- 横向对齐方式
	self._valign = SC.ALIGNMENT_CENTER	-- 纵向对齐方式
	self._wrap = toboolean(wrap)		-- 是否自动换行
	self._hpadding = 4					-- 对象之间的横向间隔
	self._vpadding = 4					-- 对象之间的纵向间隔
	self._hmargin = 10					-- 左右边缘缩进
	self._vmargin = 10					-- 上下边缘缩进
	self._all = {}		-- 所有对象列表
	self._all_height = 0		-- 总高度
	self._add_height = 0		-- 当前增加高度
	self._isNeedMove = false	-- 是否需要移动到顶端	
	self._coro_lists = {}		-- 携程列表

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
	local sc = self
	self:addEventListener(function(sender,eventType)
		if eventType==ccui.ScrollviewEventType.scrollToTop then
			self:resumeListCoroutine("_top_list_coro")
		end
		if eventType==ccui.ScrollviewEventType.scrollToBottom then
			self:resumeListCoroutine("_bottom_list_coro")
		end
	end)

end

---启动显示列表的携程
function SC:startListCoroutine(handler)
	self._list_coro = coroutine.create(handler)
	self._list_lock = true
end

--- 顶部滚动携程
function SC:topListCoroutine(handler)
	local cn = "_top_list_coro"
	table.insert(self._coro_lists, cn)
	self[cn] = coroutine.create(handler)
	self[cn.."_lock"] = true
end

--- 底部滚动携程
function SC:bottomListCoroutine(handler)
	local cn = "_bottom_list_coro"
	table.insert(self._coro_lists, cn)
	self[cn] = coroutine.create(handler)
	self[cn.."_lock"] = true
end

---恢复显示更多列表项的携程
function SC:resumeListCoroutine(eventType)
	if self._list_coro then
		self._list_lock = true
	end

	if eventType then 
		if self[eventType] then self[eventType.."_lock"] = true end
	end
end

---暂停显示列表的携程
function SC:pauseListCoroutine()
	self._list_lock = nil
	for _, v in ipairs(self._coro_lists) do
		if self[v] then self[v.."_lock"] = nil end
	end
end

--- 自动更新
function SC:onUpdate(dt)
	if self._list_coro and self._list_lock then
		local ret = coroutine.resume(self._list_coro)
		if not ret or coroutine.status(self._list_coro)=='dead' then --携程已结束或出现错误
			self._list_coro = nil
			self._list_lock = nil
		end
	end

	for _, v in ipairs(self._coro_lists) do
		if self[v] and self[v.."_lock"] == true then
			local status = coroutine.status(self[v])
			local ret = coroutine.resume(self[v])
			if status ~= 'dead' and not ret then print("there are some error in " .. v .. "'s function ") end
			if not ret or status == 'dead' then
				print(v .. " is dead")
				self[v] = nil 
				self[v.."_lock"] = nil
			end
		end
	end
end

--- 重新整理所有对象的位置
function SC:rearrange()
	local all = self._all
	self._all_height = 0
	self._add_height = 0
	local size = self:getContentSize()

	for _, child in ipairs(all) do
		self._all_height = child._rootH + self._vpadding + self._all_height
	end

	if self._all_height > size.height then 
		size.height = self._all_height
		self:setInnerContainerSize(size)
		self._remain_height = self._all_height
	else
		self._remain_height = size.height -- 剩余画布
		self:setInnerContainerSize(size)
	end

	for _, child in ipairs(all) do
		self._add_height = child._rootH	+ self._vpadding
		self._remain_height = self._remain_height - self._add_height
		child:setPosition(cc.p(0, self._remain_height))
	end
end

--- 增加元素
function SC:addChild(child, zOrder, tag)
	checkInherit(child.ClassName)
	self._super_addChild(self,child,tonumber(zOrder) or 0, tonumber(tag) or 0)
	self:adjustCanvas(child._rootH)
	table.insert(self._all, child)
	child:setPositionX(0)
	child:setPositionY(0)
	if self._isNeedMove then 
		child:runAction(cc.MoveBy:create(0.25, self._moveBy))
		self._isNeedMove = false
	end
end

--- 插入元素
-- @param child object 插入对象
-- @param index number 插入位置 1 开始
function SC:insertChild(child, index, zOrder, tag)
	self:lazyInsertChild(child, index, zOrder, tag)
	self:rearrange()
end

--- 延时插入模式，插入完毕需要显示调用rearrange()
function SC:lazyInsertChild(child, index, zOrder, tag)
	checkInherit(child.ClassName)
	self._super_addChild(self, child, tonumber(zOrder) or 0, tonumber(tag) or 0)
	index = index or 1
	table.insert(self._all, index, child)
end

--- 调整画布
function SC:adjustCanvas(childH)
	local size = self:getInnerContainerSize()
	self._add_height = childH + self._vpadding
	self._all_height = self._all_height + self._add_height
	-- 当超出显示范围时，加长画布
	if self._all_height > size.height then 
		size.height = self._all_height
		self:setInnerContainerSize(size)
		for _, v in ipairs(self._all) do 
			v:setPositionY(v:getPositionY() + self._add_height - self._remain_height)
		end
		self._remain_height = 0
	else -- 还没超出范围，先添加到顶端
		self._isNeedMove = true
		self._remain_height = self._remain_height or size.height
		self._remain_height = self._remain_height - self._add_height
		self._moveBy = cc.p(0, self._remain_height)
	end

	
end

--- 删除指定元素
function SC:removeChild(child, cleanup)
	self._super_removeChild(self, child, cleaup == nil and true or toboolean(cleaup))
	table.removeValue(self._all, child)
	self:rearrange()
end

--- 清空所有元素
function SC:removeAllChildren()
	self:_super_removeAllChildren()
	self._all = {}
	self:rearrange()
end

--- 滚动到某位置
function SC:rollToBottom()
	
end

--- 判断是否SC为空
function SC:isEmpty()
	return #self._all > 0 and true or false
end