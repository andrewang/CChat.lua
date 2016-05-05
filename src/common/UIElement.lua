
---UI原件基类
local UIElement = class(...,function(id)
	return ccs.GUIReader:getInstance():widgetFromJsonFile(getUIJsonPath(path.removeExtName(id)))
end)
regClass(...,UIElement,true)

function UIElement.create(UI,...)
	return UI.new(UI.id,...)
end

function UIElement:ctor(id)
	self:setCascadeOpacityEnabled(true)
	self.ClassName = "UIElement"
--	self._widgets = {}
end

---通过名字获得UI控件
function UIElement:getByName(name)
--	if not self._widgets[name] then
--		self._widgets[name] = ccui.Helper:seekWidgetByName(self,name)
--	end
--	return self._widgets[name]
	return ccui.Helper:seekWidgetByName(self,name)
end

function UIElement:setClickedCallback(cb)
	if type(cb)=='function' then
		self._clickedCallback = cb
	else
		self._clickedCallback = nil
	end
end

