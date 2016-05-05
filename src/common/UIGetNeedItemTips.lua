local UI = class(...,UILayer)
regClass(...,UI,true)

UI.id = "get_need_item"

function UI:ctor(id)
	UI.super.ctor(self,id)
	self.show_action = true
	self._getwayBtn = self:getByName("btn_icon")
	self.lb_need = self:getByName("lb_need")
	self.lb_have = self:getByName("lb_have")
	self.img_icon = self:getByName("img_icon")
	self.sui_flag = self:getByName("sui_flag")
	self.lb_name = self:getByName("item_name3_0")
	self.layer_count = self:getByName("layer_count")

	self.btn_close = self:getByName("btn_close")
	self.btn_close:addTouchEventListener(function(sender,eventType)
		if eventType ~= cc.EventCode.ENDED then return end
			self:close()
	end)
	self.btn_back = self:getByName("btn_back")
	self.btn_back:addTouchEventListener(function(sender,eventType)
		if eventType ~= cc.EventCode.ENDED then return end
			self:close()
	end)

end

function UI:showUI(iid,need)
	self:showModel(nil,nil,true)

	local info=item_defs[iid]
	self.lb_name:setString(info.name)
	self.img_icon:loadTexture(getIconItemPath(iid))
	local cnt = user:getItemCount(gGetwayInfo.iid) or 0
	self.lb_need:setString("/"..need..")")
	self.lb_have:setString(cnt)
	if info.type=="zhk" or info.type == "cl" then
		self.sui_flag:show()
	else 
		self.sui_flag:hide()
	end 
	---调整数目位置
	self.layer_count:setPositionX(self.lb_name:getPositionX()+self.lb_name:getContentSize().width+5)
end