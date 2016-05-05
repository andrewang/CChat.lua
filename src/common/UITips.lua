
---提示语消息框
local UI = class(...,UILayer)
regClass(...,UI,true)

UI.id = "tips"

function UI:ctor(id)
	UI.super.ctor(self,id)

	self._lb_msg = self:getByName("lb_msg")
	self._default_size = self:getContentSize()
	self._default_pos = cc.p(self:getPosition())
--	print("tips default size:"..self._default_size.width..","..self._default_size.height)

	self._t_tmp = ccui.Text:create() --用于计算文本大小
	self._t_tmp:setFontName(self._lb_msg:getFontName())
	self._t_tmp:setVisible(false)
	self._t_tmp:setFontSize(self._lb_msg:getFontSize())
	self:addChild(self._t_tmp)
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
--	print("set size:"..w..","..h)
end

---设置消息内容（自动根据消息内容多少调整消息框高度和宽度）
function UI:setText(txt)
	self._lb_msg:setString(txt)
	
	self._t_tmp:setString(txt)
	local size = self._t_tmp:getContentSize()
	local w = size.width
	local h = size.height
	if w<500 then --只有一行
		self._lb_msg:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
		w = w + 61
		self:setWidth(w)
		local dx = (self._default_size.width-w)/2
		self:setPosition(self._default_pos.x+dx,self._default_pos.y)
	else
		self._lb_msg:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
		local lines = w/self._default_size.width --行数
		local ah = h * (lines-1)
		self:setHeight(self._default_size.height + ah)
		self:setPosition(self._default_pos)
	end

end

---显示消息框
--@param delay number 显示时间，到时间后自动消失
--@param pos 显示位置（默认为中间）
--@param zorder number 显示顺序
--@param mask 是否背景变黑
function UI:showTips(delay,pos,zorder,mask)
	self:show(pos,zorder,mask)

	delay = tonumber(delay) or 0
	if delay>0 then
		if not self._close_schedule_id then
			self._close_schedule_id = cc.scheduleFuncOnce(function()
				self._close_schedule_id = nil
				self:runAction(cc.Sequence:create(
					cc.FadeOut:create(1),
					cc.CallFunc:create(function()
						self:close()
					end)
				))
			end,delay-1)
		end
	end

	--注册触摸事件，拦截所有点击
	if not self._touch_listener1 then
		local listenner = cc.EventListenerTouchOneByOne:create()
		listenner:setSwallowTouches(true)
		listenner:registerScriptHandler(function(touch, event)
			if self:isVisible() then
				self:close()
				return true
			end
			return false
		end,cc.Handler.EVENT_TOUCH_BEGAN)
		local eventDispatcher = self:getEventDispatcher()
--		eventDispatcher:addEventListenerWithFixedPriority(listenner, -128*2-1)
		eventDispatcher:addEventListenerWithSceneGraphPriority(listenner,self)
		self._touch_listener1 = listenner
	end
end

function UI:close()
	if self._touch_listener1 then
		self:getEventDispatcher():removeEventListener(self._touch_listener1)
		self._touch_listener1 = nil
	end
	if self._close_schedule_id then
		cc.unscheduleFunc(self._close_schedule_id)
		self._close_schedule_id = nil
	end
	self:stopAllActions()
	self:setOpacity(255)
	UI.super.close(self)
end

function UI:onExit()
	self:stopAllActions()
	if self._close_schedule_id then
		cc.unscheduleFunc(self._close_schedule_id)
		self._close_schedule_id = nil
	end
end


