
--滑动条(竖着)
local UISlide = class(...)
regClass(..., UISlide,true)

function UISlide:ctor(slideLayer,scroll_layer)
	self._scroll_layer = scroll_layer
	self._container = self._scroll_layer:getInnerContainer()
	self._viewSize = self._scroll_layer:getContentSize()
	self._preContentSize = self._container:getContentSize()

	self._slideLayer = slideLayer
	self._slide = ccui.Helper:seekWidgetByName(self._slideLayer,"slide")
	self._slide_bg = ccui.Helper:seekWidgetByName(self._slideLayer,"slide_bg")

	self._bar_maxSize = self._slide:getContentSize()


	--注册触摸事件
	if not self._touch_listener then
		local listenner = cc.EventListenerTouchOneByOne:create()
		listenner:setSwallowTouches(false)
		listenner:registerScriptHandler(function(touch, event)
			return  self:touchBegin(touch, event)
			end,cc.Handler.EVENT_TOUCH_BEGAN)
		listenner:registerScriptHandler(function(touch, event)
			self:touchMove(touch, event)
			end,cc.Handler.EVENT_TOUCH_MOVED)
		listenner:registerScriptHandler(function(touch, event)
			self:touchEnd(touch, event)
			end,cc.Handler.EVENT_TOUCH_ENDED)

        local eventDispatcher = self._slideLayer:getEventDispatcher()
        eventDispatcher:addEventListenerWithFixedPriority(listenner, -128*2-1)
		self._touch_listener = listenner
	end

	 self._effectId = cc.scheduleFunc(function(dt)
  		self:updatePos()
        end,0)
end

function UISlide:touchBegin(touch,event)
	local loc = touch:getLocation()		
    local parent = self._slide_bg
	if parent then
		loc = cc.convertToNodeSpace(parent,loc)
	end
	local rect = self._slide:getBoundingBox()
	if cc.rectContainsPoint(rect,loc) then
	    self._slide_curPos = self._slide:getPositionY()
        self._scroll_curPos = self._container:getPositionY()
		return true
	end
	return false
	
end

function UISlide:touchMove(touch,event)
    local loc = touch:getLocation()     
    local parent = self._slide_bg
    if parent then
        loc = cc.convertToNodeSpace(parent,loc)
    end
    local  curContentSize = self._container:getContentSize()
    if loc.y <=self._slide:getContentSize().height then 
        loc.y =self._slide:getContentSize().height
    end
    if loc.y >= self._bar_maxSize.height then
    	loc.y = self._bar_maxSize.height
    end
    local offset = loc.y -  self._slide_curPos
    
    local newOff =  self._scroll_curPos+ offset / (self._bar_maxSize.height-self._slide:getContentSize().height)*(self._viewSize.height - curContentSize.height)
 	self._container:setPosition(0,newOff)
end

function UISlide:touchEnd(touch,event)

end

function UISlide:updateSlide()
	local ratio = 0.0        
	ratio = self._viewSize.height / self._preContentSize.height
	self._slide:setContentSize(cc.size(tonumber(self._bar_maxSize.width),self._bar_maxSize.height*ratio)) 
	--如果显示内容过多， slide九宫格图片显示问题 
	   --todo
	--如果要显示的内容的尺寸比视图大小小，则隐藏滑块slider
	if ratio>=1 then 
	   self._scroll_layer:setVisible(false)
	else
	   self._scroll_layer:setVisible(true)
	end
end

function UISlide:updatePos()
	if  self._scroll_layer ==nil and self._effectId then 
		cc.unScheduleFunc(self._effectId)
	end 
	--列表内容变化 改变slide大小
	local  curContentSize = self._container:getContentSize()
	if  math.abs(curContentSize.height - self._preContentSize.height) > 0.00001 then 
	    self._preContentSize = curContentSize;
	    self:updateSlide()
	end
    --设置slider的位置 (竖着)              
    local curOffset = self._container:getPositionY() 
    local sliderOffset =self._slide:getContentSize().height+ curOffset/ (self._viewSize.height - curContentSize.height) * (self._bar_maxSize.height-self._slide:getContentSize().height);
    --判断滑块是否滑出界限
    if  sliderOffset < self._slide:getContentSize().height then 
    	sliderOffset = self._slide:getContentSize().height
    end
    if  sliderOffset > self._bar_maxSize.height then 
        sliderOffset = self._bar_maxSize.height
    end
    self._slide:setPositionY(sliderOffset)
end