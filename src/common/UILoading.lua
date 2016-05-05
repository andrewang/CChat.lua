require("ui.common.UILayer")

---Loading提示框
local UI = class(...,UILayer)
regClass(...,UI,true)

UI.id = "tips_loading"

function UI:ctor(id)
	UI.super.ctor(self,id)
	self._img = self:getByName("img")
end

function UI:onShow()
	self._img:setRotation(0)
	self._img:runAction(cc.RepeatForever:create( cc.Sequence:create(
		cc.RotateTo:create(0.15,180),
		cc.RotateTo:create(0.15,360),
		cc.CallFunc:create(function()		
			self._img:setRotation(0)
			end)
		)))
end 

function UI:setText(txt)

end 

function UI:onClose()
end 


