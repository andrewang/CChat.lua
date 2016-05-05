---向上浮动消失消息框
local UI = class(...,UITips)
regClass(...,UI,true)

UI.id = "float_tips"

function UI:ctor(id)
	UI.super.ctor(self,id)
end

function UI:showTips(delay,pos,zorder,mask)
	self:show(pos,zorder,mask)

	local toPos = cc.pAdd(self:getDefaultPos() or pos, cc.p(0,50))
	local t = 0.5
	delay = tonumber(delay) or 2
	if not self._close_schedule_id then
		self._close_schedule_id = cc.scheduleFuncOnce(function()
			self._close_schedule_id = nil
			self:runAction(cc.Sequence:create(
				cc.Spawn:create(cc.MoveTo:create(delay-t, toPos),cc.FadeOut:create(delay-t)),
				cc.CallFunc:create(function()
					self:close()
				end)
			))
		end,t)
	end
end

function UI:setTextColor(color)
	self._lb_msg:setColor(color)
end