---聊天
local UI = class(...,UIElement)
regClass(...,UI,true)

UI.id = "chat_fri_element"

function UI:ctor(id, onClicked)
	UI.super.ctor(self,id)
	self:setClickedCallback(onClicked)
	self._lb_name = self:getByName("lb_name")
	self._bt_element = self:getByName("bt_fri")
	self._bt_element:addTouchEventListener(function(sender,eventType)
		if eventType ~= cc.EventCode.ENDED then return end
		if self._clickedCallback then
			safeCallFunc(self._clickedCallback,self,eventType)
		end
	end)
end

function UI:onClose()
	
end

function UI:setClickedCallback(cb)
	if type(cb)=='function' then
		self._clickedCallback = cb
	else
		self._clickedCallback = nil
	end
end

function UI:setName(name)
	self._lb_name:setString(name)
end

function UI:setData(data)
	self._data = data
end

function UI:getData()
	return self._data
end

function UI:setColor(color)
	self._lb_name:setColor(color)
end
