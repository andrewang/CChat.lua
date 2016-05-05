
---点击空白处关闭窗口的对话框
local UI = class(...,UILayer)
regClass(...,UI,true)

function UI:ctor(id)
	UI.super.ctor(self,id)

	self.show_action = true
end

function UI:showOutClickDialog(onClose,nomask)
	if nomask then 
		self:show(nil,nil,false)
	else 
		self:show(nil,nil,true)
    end 
	self._on_close_func = onClose

	-- if self._remove_listener_schedule_id then
	-- 	cc.unscheduleFunc(self._remove_listener_schedule_id)
	-- 	self._remove_listener_schedule_id = nil
	-- end

	--注册触摸事件，拦截所有点击
	if not self._touch_listener1 then
		local listenner = cc.EventListenerTouchOneByOne:create()
		listenner:setSwallowTouches(true)
		listenner:registerScriptHandler(function(touch, event)
			return true
		end,cc.Handler.EVENT_TOUCH_BEGAN)
		listenner:registerScriptHandler(function(touch, event)
			local loc = touch:getLocation()
			local parent = self:getParent()
			if parent then
				loc = cc.convertToNodeSpace(parent,loc)
			end
			local rect = self:getBoundingBox()
			--not cc.rectContainsPoint(rect,loc) and 
			if not self._pause and not self._actioning then --将不在自己范围内的点击，则关闭
				if self:isVisible() then
					self:close()
					return true
				end
			end
			return false
		end,cc.Handler.EVENT_TOUCH_ENDED)
		local eventDispatcher = self:getEventDispatcher()
		-- eventDispatcher:addEventListenerWithFixedPriority(listenner, -128*2-self:getLocalZOrder())
		eventDispatcher:addEventListenerWithSceneGraphPriority(listenner,self)
		self._touch_listener1 = listenner
	end
end

function UI:setPause(flag)
	self._pause = flag
end 

function UI:close()
	if self._touch_listener1 then
		-- self._remove_listener_schedule_id = cc.scheduleFuncOnce(function()
		-- 	if not self:isVisible() and self._touch_listener1 then
				self:getEventDispatcher():removeEventListener(self._touch_listener1)
				self._touch_listener1 = nil
		-- 	end
		-- end,0.1)
	end
	UI.super.close(self)
end

function UI:onClose()
	if self._on_close_func then self._on_close_func() end
end

