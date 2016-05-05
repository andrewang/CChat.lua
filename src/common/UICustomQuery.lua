require("ui.common.UIQuery")

---自定义询问消息框
local UI = class(...,UIQuery)
regClass(...,UI,true)

UI.id = "custom_query"

function UI:ctor(id)
	UI.super.ctor(self,id)

	local o_sv = self:getByName("sv")
	local sv = replaceScrollView(o_sv)
	sv:setDirection(ccui.ScrollViewDir.none)
	sv:setTouchEnabled(false)
	sv:setBounceEnabled(false)
	sv:setVAlign(ScrollViewEx.ALIGNMENT_CENTER)
	sv:setHAlign(ScrollViewEx.ALIGNMENT_CENTER)
	self._sv = sv

end

---设置消息内容
function UI:setText(txt)
	self._sv:addChild(ccui.Text:create(txt,DEFAULT_FONT_NAME,26))
end

---获得内容显示区域ScrollView
function UI:getScrollView()
	return self._sv
end

function UI:onClose()
	UI.super.onClose(self)
	self._sv:removeAllChildren()
end

