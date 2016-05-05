
---任务对话框
local UI = class(...,UILayer)
regClass(...,UI,true)

UI.id = "talk"

function UI:ctor(id)
	UI.super.ctor(self,id)

	self:loadComponents()
end

function UI:loadComponents()
--	self._lb_word = self:getByName("lb_word")
--	self._img_card = self:getByName("img_card")
	self._lb_word = ccui.Helper:seekWidgetByName(self,"lb_word")
	self._img_card = ccui.Helper:seekWidgetByName(self,"img_card")

	self._talk_width = self:getContentSize().width
	self._lb_word_pos = cc.p(self._lb_word:getPosition())
	self._img_card_pos = cc.p(self._img_card:getPosition())
	self._img_card_scaleX = self._img_card:getScaleX()
end

function UI:setSide(right)
	if right then
		self._lb_word:setPosition(self._talk_width-self._lb_word_pos.x,self._lb_word_pos.y)
		self._img_card:setPosition(self._talk_width-self._img_card_pos.x,self._img_card_pos.y)
		self._img_card:setScaleX(self._img_card_scaleX * -1)
	else
		self._lb_word:setPosition(self._lb_word_pos)
		self._img_card:setPosition(self._img_card_pos)
		self._img_card:setScaleX(self._img_card_scaleX)
	end
end

---设置角色形象在左边
function UI:setLeft()
	self:setSide(nil)
end

---设置角色形象在右边
function UI:setRight()
	self:setSide(true)
end

---设置对话内容
function UI:setWord(word)
	self._lb_word:setString(word or "……")
end

---设置对话角色形象
function UI:setCard(id)
	self._img_card:loadTexture(getCardPath(id))
end

---显示对话框
--@param onClose function 关闭对话框时的回调函数
--@param zorder number 显示顺序
--@param mask 是否背景变暗
--@param maskcolor c4b 背景变暗颜色
function UI:showTalk(onClose,zorder,mask,maskcolor)
	self:show(nil,zorder,mask,maskcolor)

	self._on_close = onClose

	if self._remove_listener_schedule_id then
		cc.unscheduleFunc(self._remove_listener_schedule_id)
		self._remove_listener_schedule_id = nil
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
		eventDispatcher:addEventListenerWithFixedPriority(listenner, -128*2-1)
		self._touch_listener1 = listenner
	end
end

function UI:close()
	if self._touch_listener1 then
		self._remove_listener_schedule_id = cc.scheduleFuncOnce(function()
			if not self:isVisible() and self._touch_listener1 then
				self:getEventDispatcher():removeEventListener(self._touch_listener1)
				self._touch_listener1 = nil
			end
		end,1)
	end

	UI.super.close(self)

	if self._on_close then
		self._on_close()
	end
	self:setLeft()
end

