require("ui.common.UIElement") 

---图标框元件
local UI = class(...,UIElement)
regClass(...,UI,true)

UI.id = "icon_element"

function UI:ctor(id,iconfile,onSelectionChanged)
	UI.super.ctor(self,id)

	self._img_icon = self:getByName("img_icon")
	self._p_gray = self:getByName("p_gray")
	self._p_gray:setVisible(false)
	self._lb_cnt = self:getByName("lb_cnt")
	self._choose = self:getByName("choose")
	self._sui_flag= self:getByName("sui_flag")
	
	self._cb_selected = self:getByName("cb_selected")
	self._cb_selected:addEventListener(function(sender,eventType)
		if self._selectionChangeCallback then
			safeCallFunc(self._selectionChangeCallback,self,eventType)
		end 
	end)

	self:setIcon(iconfile)
	self:setSelectionChangedCallback(onSelectionChanged)
end

function UI:setColor(color)
	local _texture = getItemKuangSprite(color)
	self._cb_selected:loadTextures(_texture,_texture,_texture,nil,nil) 
end

function UI:setIcon(iconfile)
	if iconfile then
		self._img_icon:loadTexture(iconfile)
	end
end

function UI:setSuiFlag(type)
	if type=="zhk" or type =="cl" then
		self._sui_flag:show()
	else 
		self._sui_flag:hide()
	end 
end 

function UI:setIconScale(scale)
	self._img_icon:setScale(scale)
end

function UI:setHideCount(hide)
	self._lb_cnt:setVisible(not hide)
end

function UI:setCount(count)
	self._lb_cnt:setString("x"..count)
end

function UI:isEnabled()
	return self._cb_selected:isEnabled()
end

function UI:setEnabled(enabled)
	self._cb_selected:setEnabled(enabled)
	self._p_gray:setVisible(not enabled)
end

function UI:setSelected(sel)
	self._cb_selected:setSelectedState(sel)
	if sel then 
		self._choose:show()
	else 
		self._choose:hide()
	end 
end

function UI:isSelected()
	return self._cb_selected:getSelectedState()
end

function UI:setSelectionChangedCallback(cb)
	if type(cb)=='function' then
		self._selectionChangeCallback = cb
	else
		self._selectionChangeCallback = nil
	end
end
