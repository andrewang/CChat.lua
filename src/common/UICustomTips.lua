
---自定义提示消息框
local UI = class(...,UILayer)
regClass(...,UI,true)

UI.id = "custom_tips"

local SV_PADDING = 10

function UI:ctor(id)
	UI.super.ctor(self,id)
	
	local size = self:getContentSize()
	self._default_size = size
	local sv = ScrollViewEx.new(size.width-20,size.height-20,ccui.ScrollViewDir.none)
	sv:setPosition(SV_PADDING,SV_PADDING)
	sv:setAnchorPoint(cc.p(0,0))
	sv:setVAlign(ScrollViewEx.ALIGNMENT_CENTER)
	self:addChild(sv)
	self._sv = sv

end

---获得面板的ScrollViewEx控件
function UI:getScrollView()
	return self._sv
end

---设置消息框宽度
function UI:setWidth(w)
	self:setSize(w,self._default_size.height)
end

---设置消息框高度
function UI:setHeight(h)
	self:setSize(self._default_size.width,h)
end

---设置消息框大小
function UI:setSize(w,h)
	w = tonumber(w) or self._default_size.width
	h = tonumber(h) or self._default_size.height
	self:setContentSize(w,h)
	self._sv:setContentSize(w-20,h-20)
	self._sv:rearrange()
	--	print("set size:"..w..","..h)
end

---显示消息框
--@param delay number 显示时间，到时间后自动消失
--@param pos 显示位置（默认为中间）
--@param zorder number 显示顺序
--@param mask 是否背景变黑
function UI:showTips(delay,pos,zorder,mask)
	UITips.showTips(self,delay,pos,zorder,mask)
end

function UI:close()
	UITips.close(self)
end


