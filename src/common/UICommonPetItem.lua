require("ui.common.UIElement")
require("ui.pet.UIPetFrom")

---伙伴列表元件
local UI = class(...,UIElement)
regClass(...,UI,true)

UI.id = "common_pet_item"

function UI:ctor(id,onClicked)
	UI.super.ctor(self,id)
	self:setClickedCallback(onClicked)

	self._head_icon = self:getByName("head_icon")
	self._pet_lvl = self:getByName("txt_lvl")
	self._btn_element = self:getByName("btn_element")

	self._btn_element:addTouchEventListener(function(sender,eventType)
		if eventType == cc.EventCode.ENDED and self._clickedCallback then
			safeCallFunc(self._clickedCallback,self,eventType)
		end
	end)
end

function UI:getData()
	return self._data
end

function UI:setData(data)
	self._data = data

	self._head_icon:loadTexture(getIconPetPath(data.pid))
	self._pet_lvl:setString(data.lvl)
end

function UI:setClickedCallback(cb)
	if type(cb)=='function' then
		self._clickedCallback = cb
	else
		self._clickedCallback = nil
	end
end