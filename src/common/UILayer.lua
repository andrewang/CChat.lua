require("ui.UIManager")

---UI基类
local UILayer = class(...,function(id)
	return ccs.GUIReader:getInstance():widgetFromJsonFile(getUIJsonPath(path.removeExtName(id)))
end)
regClass(...,UILayer,true)

function UILayer.getTop()
	return UIManager.getTop()
end

function UILayer.get(UI)
	return UIManager.get(UI.id)
end

function UILayer.getVisible(UI)
	return UIManager.getVisible(UI.id)
end

function UILayer.getFree(UI)
	return UIManager.getFree(UI.id)
end

function UILayer.getOrCreate(UI,...)
	local id = UI.id
	local ui = UIManager.get(id)
	if ui then return ui end
	return UILayer.create(UI,...)
end

function UILayer.create(UI,...)
	local id = UI.id
	local ui = UIManager.getFree(id)
	if ui then return ui end
	ui = UI.new(id,...)
	UIManager.put(id,ui)
	return ui
end

function UILayer:ctor(id)
--	print("UI create: "..id)
	self:setCascadeOpacityEnabled(true)
	self:setPosition(self:getDefaultPos()) --默认
	self:setTouchEnabled(true)

--	self._widgets = {}
	self._dirty = true
	self._rid = newRid(id)

	self:registerScriptHandler(function(event)
		if event=="enter" then
			safeCallFunc(function()
				self:onEnter()
			end)
			safeCallFunc(function()
				self:onEnterFinish()
			end)
		elseif event=="exit" then
			safeCallFunc(function()
				self:onExit()
			end)
		elseif event=="cleanup" then
			safeCallFunc(function()
				self:onCleanup()
			end)
			self:removeAllLocalEventListeners() --UI销毁时，自动移除所有本对象注册的事件监听器
		end
	end)

	--- schedule update event
	self:scheduleUpdateWithPriorityLua(function(dt)
		self:onUpdate(dt)
	end, 0)

end

---获得UI的实例的运行时唯一id
function UILayer:getRid()
	return self._rid
end

---通过名字获得UI控件
function UILayer:getByName(name)
--	if not self._widgets[name] then
--		self._widgets[name] = ccui.Helper:seekWidgetByName(self,name)
--	end
--	return self._widgets[name]
	return ccui.Helper:seekWidgetByName(self,name)
end

---获得UI的默认坐标（左右居中，底边对齐）
function UILayer:getDefaultPos()
	local size = self:getContentSize()
	return cc.p(display.cx-size.width/2,display.cy-size.height/2)
end

---获得二级UI的默认Y坐标
function UILayer:getDefaultSecondUIPosY()
	local y = 90
	if false and display.heightWidthRatio>designHeightWidthRatio then
		local size = self:getContentSize()
		y = display.cy-size.height/2
		if y<90 then y=90 end
	end
	return y
end

---是否背景变暗
function UILayer:showMask(mask,maskcolor)
	if mask then
		if not self._mask_layer then
			self._mask_layer = cc.LayerColor:create(maskcolor or cc.c4b(0x0b,0x02,0,230),display.width,display.height)
			self:addChild(self._mask_layer,-1)
		end
		local x,y = self:getPosition()
		local scale = self:getScale()-1
		self._mask_layer:setPosition(-x-scale*self:getContentSize().width/2,-y-scale*self:getContentSize().height/2)
		self._mask_layer:setVisible(true)
	elseif self._mask_layer then
		self._mask_layer:setVisible(false)
	end
end

---显示ui
--@param pos 显示位置（默认为中间）
--@param zorder number 显示顺序（默认最顶层）
--@param mask 是否背景变暗
--@param maskcolor c4b 背景变暗颜色
function UILayer:show(pos,zorder,mask,maskcolor)
	zorder = tonumber(zorder) or UIManager.nzo()
--	print("UI "..self.id.." zorder: "..zorder)

	if not self:getParent() then
		local scene = cc.Director:getInstance():getRunningScene()
		scene:addChild(self,zorder)
	else
		self:setLocalZOrder(zorder)
	end

	if pos then
		self:setPosition(pos)
	end

	self:showMask(mask,maskcolor)
--[[
	if not self._update_timer then
		self._update_timer = cc.scheduleFunc(function(dt)
			safeCallFunc(self.onUpdate,self,dt)
		end,0.1)
	end
]]
	
	self:setVisible(true)
	if self.show_action then
		self:showByAction()
	else
		safeCallFunc(function()
			self._at_time = os.time()
			self:onShow()
			if self._dirty then
				self:onDirty()
				self._dirty = false
			end
			self:onActive()
		end)
	end
end

function UILayer:showByAction()
	if self._actioning then return end 
	self._actioning = true
    local minScale = 0.1
    local maxScale =1.1
	local size = self:getContentSize()
	local cur_pos= self:getDefaultPos()
    self:setScale(minScale)
    if self._mask_layer then
    	self._mask_layer:setScale(10)
 	end 
	self:setPosition(cc.p(cur_pos.x+(1-minScale)*size.width/2,cur_pos.y+(1-minScale)*size.height/2))
	self:runAction(cc.Sequence:create(
				cc.Spawn:create(	
					cc.ScaleTo:create(0.2,maxScale),
					cc.MoveTo:create(0.2,cc.p(cur_pos.x-(maxScale-1)*size.width/2,cur_pos.y-(maxScale-1)*size.height/2))
				),
				cc.Spawn:create(
					cc.ScaleTo:create(0.2,1.0),
					cc.MoveTo:create(0.2,cc.p(cur_pos.x,cur_pos.y))
				),
				cc.CallFunc:create(function()
					if self._mask_layer then
						self._mask_layer:setScale(1)
					end 
					self._actioning = false
					self._at_time = os.time()
					self:onShow()
					if self._dirty then
						self:onDirty()
						self._dirty = false
					end
					self:onActive()
				end)
			))

end 

---对话框模式显示消息框
--@param pos 显示位置（默认为中间）
--@param zorder number 显示顺序（默认最顶层）
--@param mask bool 是否背景变暗
--@param maskcolor c4b 背景变暗颜色
function UILayer:showModel(pos,zorder,mask,maskcolor)
	self:show(pos,tonumber(zorder) or UIManager.nzo(),mask,maskcolor)

	--注册触摸事件，拦截该ui以外的所有点击
	if not self._touch_listener then
		local listenner = cc.EventListenerTouchOneByOne:create()
		listenner:setSwallowTouches(true) --吞噬触摸，不传递给下一层
		listenner:registerScriptHandler(function(touch, event)
			local loc = touch:getLocation()
			local parent = self:getParent()
			if parent then
				loc = cc.convertToNodeSpace(parent,loc)
			end
			local rect = self:getBoundingBox()
			if not cc.rectContainsPoint(rect,loc) then
				return true --将不在自己范围内的点击吃掉
			end
			return false
		end,cc.Handler.EVENT_TOUCH_BEGAN)
		local eventDispatcher = self:getEventDispatcher()
--		eventDispatcher:addEventListenerWithFixedPriority(listenner, -128*2-1)
		eventDispatcher:addEventListenerWithSceneGraphPriority(listenner,self)
		self._touch_listener = listenner
	end
end

---关闭ui
function UILayer:close()
--[[
	if self._update_timer then
		cc.unscheduleFunc(self._update_timer)
		self._update_timer = nil
	end
]]
	if self._touch_listener then
		self:getEventDispatcher():removeEventListener(self._touch_listener)
		self._touch_listener = nil
	end
	-- if self.show_action then 
	-- 	self:runAction(cc.Sequence:create(
	-- 			cc.Spawn:create(
	-- 				cc.ScaleTo:create(0.2,0),
	-- 				cc.MoveTo:create(0.2,cc.p(display.cx,display.cy))
	-- 			),
	-- 			cc.CallFunc:create(function()
	-- 				self:setVisible(false)
	-- 				safeCallFunc(function()
	--					self._at_time = os.time()
	-- 					self:onClose()
	-- 				end)
	-- 			end)
	-- 		))
	-- else 
	-- 	self:setVisible(false)
	-- 	safeCallFunc(function()
	--		self._at_time = os.time()
	-- 		self:onClose()
	-- 	end)
	-- end 
	self:setVisible(false)
	safeCallFunc(function()
		self._at_time = os.time()
		self:onClose()
	end)

	local top = UIManager.getTop()
	if top and top~=self then --判断自己，可能会在onClose回调中再次打开自己
		safeCallFunc(function()
			if top._dirty then
				top:onDirty()
				top._dirty=false
			end
			top:onActive()
		end)
	end
end

---更新UI控件显示内容
function UILayer:updateUI(info)
end

---设置为脏数据状态
function UILayer:setDirty()
	self._dirty = true
end

--[[--
注册一个本对象事件监听器（该方法注册的时间监听器将会在该ui退出舞台时自动移除）

@param eventName string 事件名称
@param listener function 事件处理函数，函数返回false表示终止事件继续传递
@return #int 返回监听器标识，可用于移除监听器
]]
function UILayer:addLocalEventListener(eventName,listener)
	return events.addListener(eventName,listener,self._rid)
end

--[[--
移除指定监听器

@param id int 监听器标识，添加监听器时返回的标识
]]
function UILayer:removeLocalEventListener(id)
	return events.removeListener(id)
end

--[[--
移除所有本对象注册的事件监听器
]]
function UILayer:removeAllLocalEventListeners()
	events.removeListenersByTag(self._rid)
end

--[[--
分发一个事件，直到遇到某个监听器处理函数返回false时终止，否则将派发给所有注册了该事件的监听器

@param event table 事件信息，包括至少包括name字段
]]
function UILayer:dispatchEvent(event)
	events.dispatch(event)
end

--[[--
分发一个事件，直到遇到某个监听器处理函数返回false时终止，否则将派发给所有注册了该事件的监听器

@param eventName string 事件名称
@param eventData mixed 事件参数信息，将作为event.data传递
]]
function UILayer:dispatchEventName(eventName,eventData)
	local event = {name=eventName}
	if eventData then
		event.data = eventData
	end
	events.dispatch(event)
end

-----------------------------以下为事件方法-----------------------------

---打开ui事件
function UILayer:onShow()
--	print("UI show: "..self.id)
end

---数据变脏时，激活ui将会调用该函数
function UILayer:onDirty()
end

---激活ui事件（当ui进入最顶层时调用）
function UILayer:onActive()
--	print("UI active: "..self.id)
end

---定时刷新事件
function UILayer:onUpdate(dt)
--	print("UI update: "..self.id)
end

---关闭ui事件
function UILayer:onClose()
--	print("UI close: "..self.id)
end

---进入舞台事件
function UILayer:onEnter()
--	print("UI enter: "..self.id)
end

---完成进入舞台事件
function UILayer:onEnterFinish()
--	print("UI enter finish: "..self.id)
end

---离开舞台事件
function UILayer:onExit()
--	print("UI exit: "..self.id)
end

---销毁清理事件
function UILayer:onCleanup()
--	print("UI cleanup: "..self.id)
end


