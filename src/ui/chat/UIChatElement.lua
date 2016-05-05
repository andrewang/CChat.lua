--- 聊天条目元件
local UI = class(...,UIElement)
regClass(...,UI,true)

UI.id = "chat_element"
local FONT_SIZE = 20

local function autoInit(self, nameList)
	for i, v in ipairs(nameList) do
		self["_"..v] = self:getByName(v);
	end
end

function UI:ctor(id)
	UI.super.ctor(self,id)
--	self:setPositionY(90)
	autoInit(self, {
		"root",
		"img_chat", "bt_head_left", "bt_head_right", 
		"lb_name", "lb_title", "lb_time",
	})
	self._startX = self._lb_name:getPositionX()
	self._startY = self._lb_name:getPositionY()
	
	self._isFstLine = true
	self._bgW = self._img_chat:getBoundingBox().width
	self._rootH = self._root:getBoundingBox().height
	self._rootW = self._root:getBoundingBox().width
	self._all = {}
end

function UI:newLabel(text, t)
	t = t or {}
	self.font_name = t.font_name or DEFAULT_FONT_NAME
	self.font_size = t.font_size or FONT_SIZE
	self.color = t.color
	self.opacity = t.opacity

	local lab
	local exists = cc.FileUtils:getInstance():isFileExist(self.font_name)
	if exists then
		local ttfConfig = {}
		ttfConfig.fontFilePath = self.font_name
		ttfConfig.fontSize = self.font_size
		lab = cc.Label:createWithTTF(ttfConfig, text)
	else
		lab = cc.Label:createWithSystemFont(text, self.font_name, self.font_size)
	end
	lab._font_name = self.font_name
	lab._font_size = self.font_size

	if self.color then lab:setColor(self.color) end
	if self.opacity then lab:setOpacity(self.opacity) end

	return lab
end

function UI:moveUpOneLine(text_h)
	local bgH = self._img_chat:getBoundingBox().height
	bgH = bgH + text_h
	self._rootH = self._rootH + text_h
	self._root:setContentSize(cc.size(self._rootW, self._rootH))
	self._img_chat:setContentSize(cc.size(tonumber(self._bgW), tonumber(bgH)))
	self._lb_name:setPositionY(self._lb_name:getPositionY() + text_h)
	self._lb_title:setPositionY(self._lb_title:getPositionY() + text_h)
	self._bt_head_left:setPositionY(self._bt_head_left:getPositionY() + text_h)
	self._bt_head_right:setPositionY(self._bt_head_right:getPositionY() + text_h)
	self._startY = self._startY + text_h
	for _, v in ipairs(self._all) do
		v:setPositionY(v:getPositionY() + text_h)
	end
end

function UI:pushTxt(txt)
	self:moveUpOneLine(self.font_size);
	if self._isFstLine then 
		self._startX = self._startX + self.font_size
		self._isFstLine = false
	end
	self._startY = self._startY - self.font_size 
	self._img_chat:addChild(txt)
	txt:setPosition(self._startX, self._startY)
	txt:setAnchorPoint(cc.p(0, 0.5))
	table.insert(self._all,txt)
end

--- 聊天入口函数
function UI:showMsg(o)
	if type(o) == "table" then 
		self._lb_name:setString(o.name)
		self._lb_title:setString(o.title)
		self._lb_time:setString(o.time)
		self:setText(o.say)

		self["_bt_head_" .. (o.isMe and "right" or "left")]:setVisible(true)
	else
		print("could not analyse what you said")
	end
end

function UI:setText(str, style)

	local txt = self:newLabel(str, style)
	local str_width = txt:getContentSize().width
	local input_width = self._bgW - self.font_size * 2

	-- 判断够宽则直接加入
	if str_width < input_width then 
		self:pushTxt(txt)
	else -- 当前行空间不足，拆开多个
		local left_count = math.floor(#str * input_width / str_width)
		if left_count > 0 then 
			left_str = str:sub(1, left_count)
			txt = self:newLabel(left_str, style)
			self:pushTxt(txt)
			self:setText(str:sub(left_count+1, style))
		end
	end
end

function UI:onClose()
	
end
