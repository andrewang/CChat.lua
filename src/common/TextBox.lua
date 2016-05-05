
---文本输入框
local TextBox = class(...,function()
	local layer = cc.LayerColor:create(cc.c4b(255,255,255,255))
	layer:setOpacity(180)
	layer._super_setContentSize = layer.setContentSize
	layer._super_setColor = layer.setColor
	return layer
end)
regClass(...,TextBox,true)

local DEFAULT_SIZE = cc.size(120,30)

function TextBox:ctor(placeholder,fontName,fontSize,onEnterCallback)
	self:apos(display.aCenter)
	local tf = ccui.TextField:create(placeholder,fontName,fontSize)
	tf:addTo(self)
	--	tf:setTouchEnabled(true)
	--	tf:setTouchAreaEnabled(true)
	tf:ignoreContentAdaptWithSize(false)
	tf:setColor(cc.c3b(0,0,0))
	self._on_enter_cb = onEnterCallback
	ctrl.extendsTextFieldKeyboardHandler(tf,function(txt)
		if self._on_enter_cb then
			safeCallFunc(self._on_enter_cb,txt)
		end
	end)
	self._tf = tf

	self:size(DEFAULT_SIZE)
end

function TextBox:setOnEnterCallback(cb)
	self._on_enter_cb = cb
end

function TextBox:getText()
	return self._tf:getStringValue()
end

function TextBox:setText(text)
	self._tf:setText(text)
end

function TextBox:setPlaceholder(placeholder)
	self._tf:setPlaceHolder(placeholder)
end

function TextBox:setFont(fontName,fontSize)
	self._tf:setFontName(fontName)
	self._tf:setFontSize(fontSize)
end

function TextBox:setContentSize(w,h)
	if type(w)=='table' then
		self._super_setContentSize(self,w)
	else
		self._super_setContentSize(self,w,h)
	end
	local size = self:getContentSize()
	self._tf:setTextAreaSize(size)
	self._tf:pos(size.width/2,size.height/2)
end

function TextBox:setColor(c3b)
	self._tf:setColor(c3b)
end

function TextBox:setBGColor(c3b)
	self._super_setColor(self,c3b)
end
