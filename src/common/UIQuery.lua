
---询问消息框
local UI = class(...,UILayer)
regClass(...,UI,true)

UI.id = "query"

function UI:ctor(id)
	UI.super.ctor(self,id)

	self._lb_msg = self:getByName("lb_msg")

	self._lb_ok = self:getByName("lb_ok")
	self._lb_cancel = self:getByName("lb_cancel")
	self._ok_cap = self._lb_ok:getString()
	self._cancel_cap = self._lb_cancel:getString()

	self._bt_ok = self:getByName("bt_ok")
	self._bt_ok:addTouchEventListener(function(sender,eventType)
		if eventType ~= cc.EventCode.ENDED then return end
		self:close()
		if self._onOK then safeCallFunc(self._onOK) end
	end)

	self._bt_cancel = self:getByName("bt_cancel")
	self._bt_cancel:addTouchEventListener(function(sender,eventType)
		if eventType ~= cc.EventCode.ENDED then return end
		self:close()
		if self._onCancel then safeCallFunc(self._onCancel) end
	end)
end

---设置消息内容
function UI:setText(txt)
	self._lb_msg:setString(txt)
end

---设置是否隐藏确定按钮
function UI:setHideOKButton(hide)
	self._bt_ok:setVisible(not hide)
end

---设置是否隐藏取消按钮
function UI:setHideCancelButton(hide)
	self._bt_cancel:setVisible(not hide)
end

---恢复按钮标题
function UI:resetButtonCaption()
	self._lb_ok:setString(self._ok_cap)
	self._lb_cancel:setString(self._cancel_cap)
end

---设置按钮标题
function UI:setButtonCaption(okCap,cancelCap)
	if type(okCap)=="string" then
		self._lb_ok:setString(okCap)
	end
	if type(cancelCap)=="string" then
		self._lb_cancel:setString(cancelCap)
	end
end

---设置按钮事件回调函数
function UI:setButtonCallback(onOK,onCancel)
	self._onOK = type(onOK)=="function" and onOK or nil
	self._onCancel = type(onCancel)=="function" and onCancel or nil
end

---对话框模式显示消息框
--@param onOK function 点击确定回调
--@param onCancel function 点击取消回调
--@param mask bool 是否背景变暗
--@param zorder number 显示顺序
function UI:showQuery(onOK,onCancel,mask,zorder)
	self:showModel(nil,zorder,mask)
	self:setButtonCallback(onOK,onCancel)
end

function UI:onClose()
	self:resetButtonCaption()
	self:setHideOKButton(false)
	self:setHideCancelButton(false)
	-- self._onOK = nil
	-- self._onCancel = nil
end
