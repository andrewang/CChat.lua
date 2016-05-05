require("ui.chat.ScrollViewChat")
require("ui.common.UICustomTips")
require("ui.common.UICustomQuery")
require("ui.chat.UIChatElement")
require("ui.chat.UIChatFriends")
---聊天
local UI = class(...,UILayer)
regClass(...,UI,true)

UI.id = "chat_main"

local TransformType = {TYPE_POP = 1, TYPE_CLAN = 2, TYPE_PER = 2}

local PER_MSG_COUNT = 20

---替换为自定义的ScrollView对象
local function replaceScrollViewChat(o_sv)
	local sv_size = o_sv:getContentSize()
	local sv = ScrollViewChat.new(sv_size.width,sv_size.height,o_sv:getDirection())
	sv:setPosition(o_sv:getPosition())
	sv:setAnchorPoint(o_sv:getAnchorPoint())
	local zorder = o_sv:getLocalZOrder()
	sv:setLocalZOrder(zorder)
	sv:setTouchEnabled(o_sv:isTouchEnabled ())
	local sv_parent = o_sv:getParent()
	if sv_parent then
		sv_parent:removeChild(o_sv)
		sv_parent:addChild(sv,zorder)
	end
	return sv
end

--- 改变形态
local function friTransformTo(obj, flag)
	obj:setVisible(true)
	if flag then
		if obj.transfLock == flag then return else obj.transfLock = flag end 
		-- img_chat_bg
		moveBy = cc.MoveTo:create(0.251,  obj.old_pos)
		fadeIn = cc.FadeIn:create(0.25)
		obj:runAction(moveBy)
		obj:runAction(fadeIn)
	else
		if obj.transfLock == flag then return else obj.transfLock = flag end 
		-- img_chat_bg
		moveBy = cc.MoveTo:create(0.251,  obj.new_pos)
		fadeOut = cc.FadeOut:create(0.25)
		obj:runAction(moveBy)
		obj:runAction(fadeOut)
	end
end

local function checkLoading(qid)
	if qid then
		local loading = UILoading:create()
		loading:setText("正在请求服务器，请稍候...")
		-- TODO 到时应改成loading
		loading:showModel()
	end
end

function UI:ctor(id)
	UI.super.ctor(self, id)
	-- self:setPositionY(90)
	self._bt_fri_unfold = self:getByName("bt_fri_unfold")
	self._bt_fri_fold = self:getByName("bt_fri_fold")
	self._img_title = self:getByName("img_title")
--	self._img_title.img_clan = self._img_titl
	self._lb_title = self:getByName("lb_title")
	self._p_bg = self:getByName("p_bg")
	self._img_chat_bg = self:getByName("img_chat_bg")
	self._bt_close = self:getByName("bt_close")
	
	self._p_input = self:getByName("p_input")
	self._tf_input = self:getByName("tf_input")
	self._bt_send = self:getByName("bt_send")
	self._bt_channel = self:getByName("bt_channel")

	self._slv_chat_pop = self:getByName("slv_chat_pop")
	self._slv_chat_pop = replaceScrollViewChat(self._slv_chat_pop)
	self._slv_chat_clan = self:getByName("slv_chat_clan")
	self._slv_chat_clan = replaceScrollViewChat(self._slv_chat_clan)
	self._slv_chat_per = self:getByName("slv_chat_per")
	self._slv_chat_per = replaceScrollViewChat(self._slv_chat_per)

	self._slv_chat_pop.sign = "bt_pop" 
	self._slv_chat_pop.sign_num = 1

	self._slv_chat_clan.sign = "bt_clan" 
	self._slv_chat_clan.sign_num = 2

	self._slv_chat_per.sign = "bt_per" 
	self._slv_chat_per.sign_num = 0

	self._cur_chat = self._slv_chat_pop -- 当前聊天频道

	-- 下方频道切换
	self._channel = self:getByName("img_channel")

	self._bt_close:addTouchEventListener( function(sender, eventType)
		if eventType ~= cc.EventCode.ENDED then return end
		self:close()
	end )

	self._bt_fri_unfold:addTouchEventListener( function(sender, eventType)
		if eventType ~= cc.EventCode.ENDED then return end
		self:swFriendsUI(true)

	end )

	self._bt_fri_fold:addTouchEventListener( function(sender, eventType)
		if eventType ~= cc.EventCode.ENDED then return end
		self:swFriendsUI(false)

	end )

	self._bt_channel:addTouchEventListener( function(sender, eventType)
		if eventType ~= cc.EventCode.ENDED then return end
		self:swChannel()
	end )

	self._bt_send:addTouchEventListener( function(sender, eventType)
		if eventType ~= cc.EventCode.ENDED then return end
		self:onClickSend()
	end )

	-- 频道选择
	local channel_list = {"bt_pop", "bt_clan", "bt_per",}
	for _, v in pairs(channel_list) do
		local item = self:getByName(v)
		item._channel_type = v
		item:addTouchEventListener( function(sender, eventType)
			if eventType ~= cc.EventCode.ENDED then return end
			self._channel:setVisible(false)
			self:selectChannel(sender._channel_type)
		end )
	end
	
	-- 保存当前聊天框位置信息
	self._p_bg.old_pos = cc.p(self._p_bg:getPositionX(), self._p_bg:getPositionY())
	self._p_bg.old_size = self._p_bg:getContentSize()
	self._p_bg.new_pos = cc.p(141, 152)
	self._p_bg.new_size = cc.size(442, 528)

	self._img_chat_bg.old_pos =cc.p(self._img_chat_bg:getPositionX(), self._img_chat_bg:getPositionY())
	self._img_chat_bg.new_pos = cc.p(162, 191)

	self.transfLock = 1 -- 变形锁，记录当前变形状态（每种状态只能变一次）
	
	-- 左侧好友列表
	self._friends = self:getByName("img_friends")
	self._slv_friends = self:getByName("slv_friends")
	self._slv_friends = replaceScrollView(self._slv_friends)
	self._slv_friends:setDirection(ccui.ScrollViewDir.vertical)
	self._slv_friends:setStyle({
		AutoWrap = true,
		HMargin = 10,
		VMargin = 2,
		HPadding = 4,
		VPadding = 4,
		VAlign = ScrollViewEx.ALIGNMENT_CENTER,
		HAlign = ScrollViewEx.ALIGNMENT_CENTER,
	})
	self._slv_friends:addEventListener(function(sender,eventType)
		if eventType==ccui.ScrollviewEventType.scrollToBottom then
			self._slv_friends:resumeListCoroutine()
		end
	end)
	self:buildFriends()

	self._friends.old_pos = cc.p(self._friends:getPositionX(), self._friends:getPositionY())
	self._friends.old_size = self._friends:getContentSize()
	self._friends.new_pos = cc.p(self._friends.old_pos.x - self._friends.old_size.width, self._friends.old_pos.y)
	self._friends.sign = "bt_per"

	-- 左侧帮派列表
	self._clans = self:getByName("img_clans")
	self._slv_clans = self:getByName("slv_clans")
	self._slv_clans = replaceScrollView(self._slv_clans)
	self._slv_clans:setDirection(ccui.ScrollViewDir.vertical)
	self._slv_clans:setStyle({
		AutoWrap = true,
		HMargin = 10,
		VMargin = 2,
		HPadding = 4,
		VPadding = 4,
		VAlign = ScrollViewEx.ALIGNMENT_CENTER,
		HAlign = ScrollViewEx.ALIGNMENT_CENTER,
	})
	self._slv_clans:addEventListener(function(sender,eventType)
		if eventType==ccui.ScrollviewEventType.scrollToBottom then
			self._slv_clans:resumeListCoroutine()
		end
	end)
	self:buildClans()
	self._clans.old_pos = cc.p(self._clans:getPositionX(), self._clans:getPositionY())
	self._clans.old_size = self._clans:getContentSize()
	self._clans.new_pos = cc.p(self._clans.old_pos.x - self._clans.old_size.width, self._clans.old_pos.y)
	self._clans.sign = "bt_clan"
	self._cur_list = nil -- 当前打开的列表

	self._my_id = user:getId()
	self._uis = { }
	self:selectChannel("bt_pop")
end

--- 切换频道
function UI:swChannel()
	local flag = self._channel:isVisible()
	self._channel:setVisible(not flag)
end

function UI:selectChannel(ctype)
	self._slv_chat_clan:setVisible(false)
	self._slv_chat_per:setVisible(false)
	self._slv_chat_pop:setVisible(false)
	if self._cur_list and self._cur_list.sign ~= ctype then self:swFriendsUI(false) end
	-- 广场 隐藏人物列表，摆放到正中间
	if ctype == "bt_pop" then 
		self._cur_list = nil
		-- 动作
		self:slvTransformTo(TransformType.TYPE_POP)	
		-- 内容
		self._cur_chat = self._slv_chat_pop
		self._slv_chat_pop:setVisible(true)
		-- 标题、图标
		self._lb_title:setString("广场")
		self._img_title:loadTexture("ui/chat/chat_pop.png")
		
	-- 帮派 显示人物，更改标题
	elseif ctype == "bt_clan" then
		self._cur_list = self._clans
		self:swFriendsUI(true)
		-- 动作
		self:slvTransformTo(TransformType.TYPE_CLAN)
		-- 内容
		self._cur_chat = self._slv_chat_clan
		self._slv_chat_clan:setVisible(true)
		-- 标题、图标
		self._lb_title:setString("天宫派")
		self._img_title:loadTexture("ui/chat/chat_clan.png")
	-- 私人
	elseif ctype == "bt_per" then
		self._cur_list = self._friends
		self:swFriendsUI(true)
		self:slvTransformTo(TransformType.TYPE_PER)	
		self._cur_chat = self._slv_chat_per
		self._slv_chat_per:setVisible(true)
		
		if self:checkPrivateChatId() then 
			-- 标题、图标
			self._lb_title:setString("[选择好友]")
			self._img_title:loadTexture(getIconHeadPath(user:getNum("img")))
		else
			self._lb_title:setString(self._cur_chat._user_name)
			self._img_title:loadTexture(self._cur_chat._user_img)
		end
		return 
	end
	self:updateAndShowMsg()
end

--- 改变形态
function UI:slvTransformTo(tType)
	if tType == TransformType.TYPE_PER or tType == TransformType.TYPE_PER then
		if self.transfLock == tType then return else self.transfLock = tType end 
		-- p_bg
		local scaleToX = self._p_bg.new_size.width / self._p_bg.old_size.width
		local scaleTo = cc.ScaleTo:create(0.251, scaleToX, 1.0)
		local moveByX = self._p_bg.new_pos.x - self._p_bg.old_pos.x
		local moveBy = cc.MoveBy:create(0.251, cc.p(moveByX, 0))
		self._p_bg:runAction(scaleTo)
		self._p_bg:runAction(moveBy)
		-- img_chat_bg
		moveByX = self._img_chat_bg.new_pos.x - self._img_chat_bg.old_pos.x
		moveBy = cc.MoveBy:create(0.251, cc.p(moveByX, 0))
		self._img_chat_bg:runAction(moveBy)

	elseif tType == TransformType.TYPE_POP then
		if self.transfLock == tType then return else self.transfLock = tType end 
		-- p_bg
		local scaleTo = cc.ScaleTo:create(0.25, 1)
		local moveByX = self._p_bg.old_pos.x - self._p_bg.new_pos.x
		local moveBy = cc.MoveBy:create(0.251, cc.p(moveByX, 0))
		self._p_bg:runAction(scaleTo)
		self._p_bg:runAction(moveBy)

		-- img_chat_bg
		moveByX = self._img_chat_bg.old_pos.x - self._img_chat_bg.new_pos.x
		moveBy = cc.MoveBy:create(0.251, cc.p(moveByX, 0))
		self._img_chat_bg:runAction(moveBy)
	end
end

--- 好友列表开关
function UI:swFriendsUI(flag)
	if self._cur_list then
		self._bt_fri_fold:setVisible(flag)
		self._bt_fri_unfold:setVisible(not flag)
		friTransformTo(self._cur_list, flag)
		self:slvTransformTo((flag and 2 or 1))
	end
end

function UI:checkPrivateChatId()
	local sign_num = self._cur_chat.sign_num
	local per_id = self._cur_chat._per_id
	if sign_num == 0 and (not per_id or per_id == "") then 
		showTips("请选择私聊对象!", 3)
		return true
	end	
end

function UI:onClickSend()
	local str = str or self._tf_input:getString()
	if not str or str == "" then
		showTips("请输入你要发送的消息内容!", 3)
		return
	end 
	self._tf_input:setString("")
	local sign_num = self._cur_chat.sign_num
	local per_id = self._cur_chat._per_id
	if self:checkPrivateChatId() then return end
	
	local t_send = {
		to = per_id, 
		msg = str 
	}
	t_send["type"] = sign_num
	
	local function onSendReply(dm, isRet)
		local loading = UILoading:getVisible()
		if loading then loading:close() end
		if isRet and dm.code~=0 then
			showTips(dm.msg)
		else
			--print(tostring(dm))
			--self:showMsg(str, "小公民",  os.date("%H小时%M分前"), true)
		end
		return true
	end
	checkLoading(network.sendRequest("QCMD_CHAT_MSG", t_send, "ACMD_RET", onSendReply))
	
end

--- 更新并显示信息
function UI:updateAndShowMsg()
	local sv = self._cur_chat
	local minid =(sv._minid and tonumber(sv._minid) > 0) and tonumber(sv._minid) or nil
	local maxid =(sv._maxid and tonumber(sv._maxid) > 0) and tonumber(sv._maxid) or nil
	local ids = { }
	-- 需更行状态的消息id列表
	local msgs
	local isDesc = nil
	if sv:isEmpty() then
		-- 获取新的信息，按时间从小到大顺序排列
		msgs = chatmsg.queryNewChatMsg(sv.sign_num, maxid, sv.sign_num == 0 and sv._per_id or nil)
		isDesc = nil
		print(tostring(msgs))
	else
		-- 获取历史信息，按时间从大到小顺序排列
		msgs = chatmsg.queryChatMsg(sv.sign_num, PER_MSG_COUNT, minid, sv.sign_num == 0 and sv._per_id or nil)
		isDesc = true
	end

	local corofunc = isDesc == true and "topListCoroutine" or "bottomListCoroutine"
	local count = #msgs
	if count > 0 then
		sv[corofunc](sv, function()
			local cur_time = os.time()
			for i = 1, count do
				local row = msgs[i]
				print(tostring(row))
				local id = row.id
				local time = row.tm
				local fid = row.fid
				local fna = row.fna
				local tid = row.tid
				local tna = row.tna
				local msg = row.msg
				local sta = row.sta

				if not minid or id < minid then minid = id end
				if not maxid or id > maxid then maxid = id end
				if sta == 1 then table.insert(ids, id) end
				local str_time = ""
				if cur_time - time > 0 then
					local t_time = getTime(cur_time - time)
					if t_time.day > 0 then str_time = str_time .. t_time.day .. "天" end
					if t_time.hour > 0 then str_time = str_time .. t_time.hour .. "小时" end
					if t_time.min > 0 then str_time = str_time .. t_time.min .. "分" end
					if #str_time > 0 then str_time = str_time .. "前" end
				end
				self:showMsg(fna, msg, "称谓", str_time, self._my_id == fid, isDesc)
				if not isDesc then sv:jumpToBottom() end
				if i == 4 or(i > 4 and(i - 4) % 2 == 0) or i == count then 
					sv:pauseListCoroutine() 
					if isDesc then 
						sv:rearrange() 
					elseif #ids > 0 then
						sv._minid = minid
						sv._maxid = maxid
						chatmsg.updateChatMsg(sv.sign_num, ids)
					end
				end
				coroutine.yield()
			end
		end )
	end
end

--- 发送信息
function UI:showMsg(name, say, title, time, isMe, isDesc)
	local element = UIChatElement:create()
	element:showMsg({name = name, say = say, title = title, time = time, isMe = isMe})
	if isDesc then 
		self._cur_chat:lazyInsertChild(element)
	else
		self._cur_chat:addChild(element)
	end
end

function UI:onClose()
--	for k, v in pairs(self._uis) do 
--		v:close()
--	end
--	self:removeFromParent()
end

--- 打造好友列表
function UI:buildFriends()
	local cms = chatmsg.queryNewPrivateChatMsgStat()
	-- 当前未读私聊信息统计
	local function onFriends(dm, isRet)
		local loading = UILoading:getVisible()
		if loading then loading:close() end
		if isRet then showTips(dm.msg) return true end
		local sv = self._slv_friends
		sv:removeAllChildren()

		local function clickUser(sender, eventType)
			self:onClickFriend(sender, eventType)
		end
		local friends = dm.friends
		local count = #friends

		if count > 0 then
			sv:startListCoroutine( function()
				for i = 1, count do
					local friend = friends[i]
					local element = UIChatFriends:create(clickUser)
					element:setName(friend.n)
					element:setData(friend)
					if friend.o == 0 then element:setColor(cc.c3b(0x80,0x80,0x80)) end
					sv:addChild(element)
					-- 每次加载6个
					if i == 16 or(i > 16 and(i - 16) % 8 == 0) then sv:pauseListCoroutine() end
					coroutine.yield()
				end
			end )
		else
			local str = {"你", "目", "前", "还", "没", "有", "好", "友",}
			for k, v in pairs(str) do
				local text = ccui.Text:create(v, DEFAULT_FONT_NAME, 20)
				text:setColor(cc.c3b(0x80,0x80,0x80))
				sv:addChild(text)
			end
		end
		return true
	end

	local qid = network.sendRequest("QCMD_FRIENDS", { }, "ACMD_FRIENDS", onFriends)
	checkLoading(qid)
end

--- 
function UI:onClickFriend(sender, eventType)
	print(tostring(sender:getData()))
	local data = sender:getData()
	-- 切换头像、标题
	self._lb_title:setString(data.n)
	self._img_title:loadTexture(getIconHeadPath(data.f))
	-- 清空私聊框
	self._cur_chat:removeAllChildren()
	self._cur_chat._minid = nil
	self._cur_chat._maxid = nil
	self._cur_chat._per_id = data.i
	self._cur_chat._user_name = data.n
	self._cur_chat._user_img = getIconHeadPath(data.f)
	self:updateAndShowMsg()
end

--- 打造帮众列表
function UI:buildClans()

	local function onFriends(dm, isRet)
		local loading = UILoading:getVisible()
		if loading then loading:close() end
		if isRet then showTips(dm.msg) return true end
		local sv = self._slv_clans
		sv:removeAllChildren()

		local function clickUser(sender, eventType)
			self:onClickclan(sender, eventType)
		end
		local friends = dm.users
		local count = #friends

		if count > 0 then
			sv:startListCoroutine( function()
				for i = 1, count do
					local friend = friends[count - i + 1]
					local element = UIChatFriends:create(clickUser)
					element:setName(friend.name)
					element:setData(friend)
					if friend.duty == 1 then element:setColor(cc.c3b(0x69,0xBF,0xF5)) end
					sv:addChild(element)
					-- 每次加载6个
					if i == 16 or(i > 16 and(i - 16) % 8 == 0) then sv:pauseListCoroutine() end
					coroutine.yield()
				end
			end )
		else
			local str = {"你", "目", "前", "还", "没", "有", "帮", "派",}
			for k, v in pairs(str) do
				local text = ccui.Text:create(v, DEFAULT_FONT_NAME, 20)
				text:setColor(cc.c3b(0x80,0x80,0x80))
				sv:addChild(text)
			end
		end
		return true
	end

	local qid = network.sendRequest("QCMD_CLAN_MEMBERS", {cid = user:getStr("clan"),from = 0,count =100,sort =2},
	"ACMD_CLAN_MEMBERS",onFriends)
	checkLoading(qid)
end

--- 
function UI:onClickclan(sender, eventType)
	print(tostring(sender:getData()))
	local data = sender:getData()

end