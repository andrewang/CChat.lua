local UIProgress = class(..., function()
	return cc.Node:create()
end)
regClass(..., UIProgress,true)

--[[
	进度条内容定义模板:
	{
		width:进度条宽
		height:进度条高
		show_text: 是否显示进度文本, 可以为空
		direction: 进度条方向, 0:从左至右， 1：从右至左。 默认为0， 可以为空
		bar:"ui/common/bar.png" --不能为空， 必须赋值， 进度条图片
		bg:"ui/common/bg.png" --可以为空， 为空则不创建底板
		bg_x:x,
		bg_y:y,
		mask:"ui/common/mask.png" --定义进度条的遮罩， 可以为空, 为空则默认使用bar作为遮罩
		others:{ --其他内容定制, 格式为一连串的数组, 仅支持图片
			{"ui/common/xxx.png", x, y},
			{"ui/common/xxx.png", x, y}
		}	
	}
--]]
function UIProgress:ctor(def)
	self.def = def
	if def.bg then
		local bg = display.newSprite(def.bg)
		bg:setAnchorPoint(display.aLeftBottom)
		if def.bg_x and def.bg_y then
			bg:setPosition(def.bg_x, def.bg_y)
		end
		self:addChild(bg)
	end

	local def_mask = def.mask or def.bar
	self.mask = display.newScale9Sprite(def_mask, 0, 0, cc.size(def.width, def.height))
	self.mask:setAnchorPoint(display.aLeftBottom)
	local clipper = cc.ClippingNode:create()
	clipper:setStencil(self.mask)--设置裁剪模板 
	clipper:setInverted(false)--设置底板不可见 
	clipper:setAlphaThreshold(0.1)
	self:addChild(clipper, 1)

	local bar = display.newScale9Sprite(def.bar, 0, 0, cc.size(def.width, def.height))
	bar:setAnchorPoint(display.aLeftBottom)
	clipper:addChild(bar)

	local others = def.others
	if others and #others > 0 then
		for _, tbl in ipairs(others) do
			local img = display.newSprite(tbl[1])
			img:setAnchorPoint(display.aLeftBottom)
			img:setPosition(tbl[2] or 0, tbl[3] or 0)
			self:addChild(img)
		end
	end
	
	self:setPercent(0)
end

function UIProgress:setPercent(percent)
	if self.def.show_text then
		-- 进度值显示
	end

	local dx = -(1-percent/100)*self.def.width
	if self.def.direction == 1 then
		dx = -dx
	end

	self.mask:setPosition(dx, 0)
end