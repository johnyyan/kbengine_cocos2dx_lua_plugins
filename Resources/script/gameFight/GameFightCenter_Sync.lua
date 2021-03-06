
GameFightCenter = {};
local p = GameFightCenter;

p.Layer = nil;
p.GrayLayer = nil;
p.BlackLayer = nil;
p.NextLabel  = nil;
p.BarrageLayer = nil;--弹幕层
p.msgBack = true;
p.m_bInPlayBoss = false; --是否在播放boss战
p.Cost = {};
p.ButtonMark = nil;
p.ui = nil;
p.uiLayer = nil;
p._buySt ={};

local m_LeftLable  = nil;
local m_RightLable = nil;

--战斗的英雄数据存储
local m_BattleSprite = {};

local m_BattleDate = {};
local m_RoundDate = {};
local m_Sprite_2_UI = {};
local m_SkillTimeMask = nil;	--异步资源加载时间挫
local m_SyncArmatureTb = {};	--异步骨骼加载列表
local m_DataActionTime = nil;
local m_LoopWalkTime   = nil;
local m_bInitMap = false;
local m_bStop = false;
local handTime = nil;
local x_speed_1 = 10;
local x_speed_2 = 20;	
local m_yOffest = 382;

local m_NowStageId = -1;
local m_tInfo = nil;
local m_nRoundTime = 0;


--账号注销回调函数
function p.gameLoginOut()
	p.Layer = nil;
	p.GrayLayer = nil;
	p.BlackLayer = nil;
	p.NextLabel  = nil;
	p.BarrageLayer = nil;--弹幕层
	p.msgBack = true;
	p.Cost = {};
	p.ButtonMark = nil;
	p.ui = nil;
	p.uiLayer = nil;
	p._buySt ={};

	m_LeftLable  = nil;
	m_RightLable = nil;

	--战斗的英雄数据存储
	m_BattleSprite = {};

	m_BattleDate = {};
	m_RoundDate = {};
	m_Sprite_2_UI = {};
	m_SkillTimeMask = nil;	--异步资源加载时间挫
	m_SyncArmatureTb = {};	--异步骨骼加载列表
	m_DataActionTime = nil;
	m_LoopWalkTime   = nil;
	m_bInitMap = false;
	m_bStop = false;
	handTime = nil;
	x_speed_1 = 10;
	x_speed_2 = 20;	
	m_yOffest = 382;

	m_NowStageId = -1;
	m_tInfo = nil;
	m_nRoundTime = 0;
	m_bInPlayBoss = false;
end

--是否显示战斗相关日志
function p:IsShowLog()
	return false;
end

--创建战斗Layer
function p:FightSceneLayer()
	if p.Layer == nil then
		p.Layer = CCLayer:create()
		if nil == p.Layer then
			cclog("****************create fight layer faild!");
			return nil;
		end
		local function onNodeEvent(event)
			if event == "enter" then
				p:MapImageInit();
				--第一次战斗(巅峰之战)
				local nFlag = UserData.bDataByteValue(UserData.UserGuideNum,30) --UserData.bDataByteValue(UserData.FunctionFirstOpen,FUN_FLAG.FIRST_LOGIN)
				if nFlag ~= 0 then
					-- p:BattleRequest();
					GameFightContract.BattleMainRequest(true);
				end
			elseif event == "exit" then
				p.Layer = nil;
			end
		end
		p.Layer:registerScriptHandler(onNodeEvent)
    end
	return p:create();
end

--巅峰战报
function p.ShowFirstBattle()
	--第一次战斗(巅峰之战)
	local nFlag = UserData.bDataByteValue(UserData.UserGuideNum,30)--UserData.bDataByteValue(UserData.FunctionFirstOpen,FUN_FLAG.FIRST_LOGIN)
	if nFlag == 0 then
		--巅峰战斗
		GameFightMusic.PlayFightBackMusic()
		
		OpenLayer(UI_TAG.UI_LOGINFIGHT,0,112);
		GameFightContract._BattleType = 0;
		
		-- p:ParsingBattle(GameFightInfoBase.FirstBattleLog());
		
		p:ChangeMapImage(41999, GameFightInfoBase.FirstBattleLog(), false, 0);
		
		local nNewStep = UserData.SetDataByteValue(UserData.UserGuideNum,30)
		NetReq.ReqSaveGuildIndex(nNewStep,UIGuide.SendGuildCall)
		UserData.UserGuideNum = nNewStep;
	end
end

-- 战斗界面被隐藏
function p.BattleLayerClose()
	cclog("***战斗界面被隐藏了***");
end

-- 战斗开始结束回调接口
function p.BattleBeginCall(isCanClick)
	local pButton = tolua.cast(p.ui.Button_79, "Button");
	if isCanClick == true then
		p.m_bInPlayBoss = false;
		pButton:setBright(true);
		UISetVisible(pButton,true);
	elseif isCanClick == false then
		p.m_bInPlayBoss = true;
		pButton:setBright(false);
		pButton:setTouchEnabled(false);
	end
	
end

--
function p.AddClickListener()
	--切换地图
	local function changeMap()
		OpenLayer(UI_TAG.UI_STAGEINFO);
		p.SetBShowBattle(false)
		MainBtn.ResetCurTab()
		--OpenLayer(UI_TAG.UI_STAGESELECT,0);
		--local nStage = math.floor((UserData.LatestStageId - 40000)/100);
		--UIStageSel.OnShow(nStage)
		local pImage = tolua.cast(p.ui.Image_Icon,"ImageView");
		if pImage ~= nil then
			pImage:setVisible(false)
		end
	end

	--快速战斗
	local function SpeedFight()
		if p.msgBack == true then
			local vipData = CfgData.cfg_VipLevel[UserData.VipLevel];
			if UserData.QuickBattleTime <= vipData.fight then
				--需要购买
				local timeT = CfgData.cfg_TimePrice[UserData.QuickBattleTime + 1]
				if CheckT(timeT) then
					local mes = string.format(ZhTextSet_30020,timeT.fight,UserData.QuickBattleTime)
					local tTable = recursionAnalyzeSuperHtmlString(nil,mes)
					local function pCall(p1)
						NetReq.ReqSpeedFight(p.SpeedFightCallback);
						p.Cost.Diomand = p1;
						p.msgBack = false;
					end
					--先注释掉，后开启。不要删除
					--if UserData.Diamond < timeT.fight then
						--砖石不足
					--	TipsManager.ShowTips(ZhTextSet_10033);
					--else
						TipsManager.ShowConfirmBox(ZhTextSet_30019, tTable,pCall,timeT.fight)
					--end
				else
					TipsManager.ShowTips(ZhTextSet_30330);
				end
			else
				--有免费次数
				-- NetReq.ReqSpeedFight(p.SpeedFightCallback);
				-- p.msgBack = false;
				-- p.Cost.Diomand = 0;
				TipsManager.ShowTips(ZhTextSet_30329);
			end
			
		end
	end

	--战斗设置
	local function battleSet()
		OpenLayer(UI_TAG.UI_BATTLESET,0,112);
	end
	
	--文字战报
	local function textBattleLog()
		GameFightTextBattle.OpenTextBattleLog();
	end

	ui_add_click_listener(p.ui.Button_79,function(sender,eventType)
		local nNum = 0;
		local nItem202 = UserData.GetItemInfo(202)
		if nItem202 ~= nil then
			nNum = nItem202.MutilNum;
		end
		
		if UserData.ChallengeTime > 0 or nNum > 0 then
			local nItemId = UserData.LatestStageId;
			local cfg = CfgData.cfg_Stage[nItemId];
			if cfg ~= nil then
				if cfg.monster_lv >= UserData.TeamLevel + 9 then
					TipsManager.ShowTips(ZhTextSet_20075);
				else
				--挑战boss
					TipsManager.ShowConfirmBox(ZhTextSet_30331,ZhTextSet_20059,p.enterStageBoss)
				end
			end
			
		else
			p.bugBossTimeFun();
		end
		
		
	end
	); --挑战BOSS
	if p.m_bInPlayBoss == false then
		local pButton = tolua.cast(p.ui.Button_79, "Button");
		if pButton ~= nil then
			if UserData.OnhookStageId ~= UserData.LatestStageId then 
				--支持扫荡BOSS
				if UserData.VipLevel >= 1 then
					local str = ZhTextSet_10208
					str = str.."BOSS";
					pButton:setTitleText(str);
					pButton:setBright(true);
					pButton:setTouchEnabled(true);
					ui_add_click_listener(pButton, function(sender,eventype)
						local function pCallback()
							p.SweepStageBoss(UserData.OnhookStageId);
						end
						--扫荡boss
						local t = recursionAnalyzeSuperHtmlString(nil,ZhTextSet_30302);
						TipsManager.ShowConfirmBox(ZhTextSet_30301,t,pCallback);
					end)
				else
					local str = ZhTextSet_30125;
					str = str.."BOSS";
					pButton:setTitleText(str);
					pButton:setBright(false);
					pButton:setTouchEnabled(false);
				end
			else
				pButton:setBright(true);
				pButton:setTouchEnabled(true);
				local str = ZhTextSet_30125;
				str = str.."BOSS";
				pButton:setTitleText(str);
			end
		end
	end
	

	--注册按钮事件
	ui_add_click_listener(p.ui.Button_40_0,changeMap); 	--切换地图
	ui_add_click_listener(p.ui.Button_40_1,SpeedFight); --快速战斗
	ui_add_click_listener(p.ui.Button_40,battleSet); 	--战斗设置
	ui_add_click_listener(p.ui.Button_40_2,textBattleLog); --文字战报
end

--购买BOSS挑战次数
function p.bugBossTimeFun()
	local tTable = CfgData.cfg_TimePrice[UserData.BuyChallengeTime+1]
	if CheckT(tTable) then
		local nCoin = tTable.boss;
		local nTime = UserData.BuyChallengeTime + 1;

		local str = string.format(ZhTextSet_20071,nCoin,nTime)
		local TRecTable ={};
		TRecTable = recursionAnalyzeSuperHtmlString(nil,str);
		TipsManager.ShowConfirmBox(ZhTextSet_20018,TRecTable,p.buyConfirm,nTime,nCoin)
	end
end

--扫荡关卡BOSS
function p.SweepStageBoss(nItemId)
	if nItemId > UserData.LatestStageId then
		--未开启
		TipsManager.ShowTips(ZhTextSet_10201);
	else
		local nNum = 0;
		local nItem202 = UserData.GetItemInfo(202)
		if nItem202 ~= nil then
			nNum = nItem202.MutilNum;
		end
		
		if UserData.ChallengeTime > 0 or nNum > 0 then
			NetReq.SweepStageBoss(nItemId, p.SweepStageBossCallFunc);
		else
			TipsManager.ShowTips(ZhTextSet_20003);
		end
	end
end

function p.SweepStageBossCallFunc(logMesg, pHttpMsg)
	local pHttp = tolua.cast(pHttpMsg, "CCHttpMessage");
	if pHttp == nil then
		cclog("**************严重错误***************");
		return;
	end
	
	local pNDTransData = pHttp:GetMessageBuffer();
	if pNDTransData ~= nil then
		if MsgClassConvern.HttpMessageHead(pNDTransData) then
			local tDrop ={};
			MsgClassConvern.CommonDrop(tDrop,pNDTransData,4)
			
			local message={}
			table.insert(message, {message=ZhTextSet_10202, color=COLOR_TYPE.White})
			
			for k,v in pairs(tDrop.tItem) do
				UserData.AddGoodsItemNum(v);
				local cfg = CfgData.cfg_item[v.typeId]
				if v.typeId == 203 then
					local str = cfg.name .. "+"
					str = str..tostring(v.MutilNum);
					table.insert(message, {message=str, color=COLOR_TYPE.Orange,Itemtype = v.typeId})
				end
			end
			
			if tDrop.Exp > 0 then
				--AddCoin(tDrop.Coin);
				local str = ZhTextSet_30332 .. "+"
				str = str..tostring(tDrop.Exp);
				table.insert(message, {message=str, color=COLOR_TYPE.Green})
			end
			
			--金币
			if tDrop.Coin > 0 then
				AddCoin(tDrop.Coin);
				local str = ZhTextSet_30313 .. "+"
				str = str..tostring(tDrop.Coin);
				table.insert(message, {message=str, color=COLOR_TYPE.Green})
			end
			
			--装备
			for k,v in pairs(tDrop.tEquip) do
				UserData.addEquipItem(v);
			end
			
			if UserData.ChallengeTime > 0 then
				UserData.ChallengeTime = UserData.ChallengeTime - 1;
			else
				UserData.DeleteGoodsItem(202,1);
			end
			
			--刷新挑战次数
			--p.SetFightNumLabel();	
			local pLable = tolua.cast(p.ui["Label_fightnum"], "Label");
			if pLable ~= nil then
				if UserData.ChallengeTime > 0 then
					pLable:setText(tostring(UserData.ChallengeTime).. ZhTextSet_30334);
				else
					--
					--显示券的数量
					local item = UserData.GetItemInfo(202);
					if CheckT(item) then
						if item.MutilNum > 0 then
							local str = string.format(ZhTextSet_30333,item.MutilNum)
							pLable:setText(str);
						else
							pLable:setText("0");
						end
					else
						pLable:setText("0");
					end
				end
			end
			p.ShowGetInfo(tDrop.tEquip,message);
		end
	end
end

function p.ShowGetInfo(tDEquip,message)
	for k,v in pairs(tDEquip) do
		local itemA = CfgData.cfg_equip[v.EquipmentType];
		local strName = GetAddWordEquipName(v);

		local nowcolor =  GetQualityColor(v.nQuality)
		strName = strName.."*1";
		table.insert(message, {message=strName,color = nowcolor})
	end
	OpenLayer(UI_TAG.UI_COMTIP,0,110);
	UIComTip.showMessage(message);
end

function p.buyConfirm(p1,p2)
	if p1 ~= nil and p2 ~= nil then
		if tonumber(p2) <= UserData.Diamond then
			NetReq.BuyBossTime(p1,p2,p.buyTimeMsgCall)
			p._buySt.nTime = p1;
			p._buySt.nCoin = p2;
		else
			TipsManager.ShowTips(ZhTextSet_20019);
		end
		--p._msgBack = false;
	end
end

function p.buyTimeMsgCall(logMesg, pHttpMsg)
	local pHttp = tolua.cast(pHttpMsg, "CCHttpMessage");
	if pHttp == nil then
		cclog("**************严重错误***************");
		return;
	end
	local pNDTransData = pHttp:GetMessageBuffer();
	if pNDTransData ~= nil then
		if MsgClassConvern.HttpMessageHead(pNDTransData) then
			UserData.ChallengeTime = UserData.ChallengeTime + 1;
			UserData.BuyChallengeTime = UserData.BuyChallengeTime + 1;
			UserData.Diamond = UserData.Diamond - p._buySt.nCoin
			
			local pLabel = tolua.cast(p.ui.Label_fightnum,"Label");
			if pLabel ~= nil then
				pLabel:setText(tostring(UserData.ChallengeTime).. ZhTextSet_30334);
			end
			-- 数据统计
			TalkingData:onPurchase("购买boss挑战次数", 1, p._buySt.nCoin)
			
			p._buySt ={};
			p._msgBack = true;		
		end
	end
end

function p.ShowLogText(bTextLog)
	local str = ""
	if bTextLog then
		str = ZhTextSet_30335
	else
		str = ZhTextSet_30336
	end
	local pLabel = tolua.cast(p.ui.Label_50_3, "Label")
	if pLabel ~= nil then
		pLabel:setText(str);
	end
end

--UI Cocostudio 的窗口
function p:create()
	if p.uiLayer == nil then
		p.uiLayer = TouchGroup:create()
		p.ui = ui_delegate(GUIReader:shareReader():widgetFromJsonFile("UserUI/action_1.json"))
		p.uiLayer:addWidget(p.ui.nativeUI);
		if p.ui.Panel_77 ~= nil then
			p.Layer:setPosition(ccp(0,-110));
			p.ui.Panel_77:addNode(p.Layer, 0);
			
			p.BarrageLayer = BarrageLayer.create(500);
			if p.BarrageLayer ~= nil then
				p.BarrageLayer.menuLayer:setPosition(ccp(0,320));
				p.ui.Panel_77:addNode(p.BarrageLayer.menuLayer, 100);
			end
		end
		p:UpdateBattlePro(85);
		p.AddClickListener();
		p.SetValue();
		p.DanmuTabClick();
		p.SetUIDefaultText();
		--p.SetButtonMark();
	end
    return p.uiLayer;
end

--设置默认文字
function p.SetUIDefaultText()
	tolua.cast(p.ui.Label_13,"Label"):setText(UIDefaultText_10012);
	tolua.cast(p.ui.Label_58,"Label"):setText(UIDefaultText_10002);
	tolua.cast(p.ui.Label_12_0_1_2,"Label"):setText(UIDefaultText_10001);
	tolua.cast(p.ui.Label_12_0_1_3,"Label"):setText(UIDefaultText_10003);
	tolua.cast(p.ui.Label_12_0_2,"Label"):setText(UIDefaultText_10004);
	tolua.cast(p.ui.Label_12_0_1,"Label"):setText(UIDefaultText_10005);
	tolua.cast(p.ui.Label_12_0,"Label"):setText(UIDefaultText_10006);
	tolua.cast(p.ui.Label_12_0_1_4,"Label"):setText(UIDefaultText_10007);
	tolua.cast(p.ui.Label_50,"Label"):setText(UIDefaultText_10008);
	tolua.cast(p.ui.Label_50_1,"Label"):setText(UIDefaultText_10009);
	tolua.cast(p.ui.Label_50_2,"Label"):setText(UIDefaultText_10010);
	tolua.cast(p.ui.Label_50_3,"Label"):setText(UIDefaultText_10011);
	tolua.cast(p.ui.Button_79,"Button"):setTitleText(UIDefaultText_10059);
end

function p.DanmuTabClick()
	ui_add_click_listener(p.ui.Image_11, function(sender,eventType)
		if UserData.danmuOn then
			tolua.cast(p.ui.Image_11,"ImageView"):loadTexture("res/UserUI/button/tbstage1.png");
		else
			tolua.cast(p.ui.Image_11,"ImageView"):loadTexture("res/UserUI/button/tbstage2.png");
		end
		
		UserData.danmuOn = not UserData.danmuOn;
		if UserData.danmuOn then
			UserDataConfig.Set_Key_Value("danmuOn", "1",UserDataConfig.DataType_STRING);
			tolua.cast(p.ui.Label_13,"Label"):setVisible(true);
			tolua.cast(p.ui.Label_14,"Label"):setVisible(false);
		else
			UserDataConfig.Set_Key_Value("danmuOn", "0",UserDataConfig.DataType_STRING);
			tolua.cast(p.ui.Label_13,"Label"):setVisible(false);
			tolua.cast(p.ui.Label_14,"Label"):setVisible(true);
		end
		UserDataConfig.UserDateFlush();
    end)
end

function p.SetValue()
	local name = UserDataConfig.Get_Key_Value("danmuOn",UserDataConfig.DataType_STRING);
	if name == "1" or name == nil then
		UserData.danmuOn = true;
		tolua.cast(p.ui.Image_11,"ImageView"):loadTexture("res/UserUI/button/tbstage2.png");
		tolua.cast(p.ui.Label_13,"Label"):setVisible(true);
		tolua.cast(p.ui.Label_14,"Label"):setVisible(false);
	else
		UserData.danmuOn = false;
		tolua.cast(p.ui.Image_11,"ImageView"):loadTexture("res/UserUI/button/tbstage1.png");
		tolua.cast(p.ui.Label_13,"Label"):setVisible(false);
		tolua.cast(p.ui.Label_14,"Label"):setVisible(true);
	end
end


--显示一条弹幕
function p.AccordOneWordLabel(word)
	--弹幕是否开启
	if UserData.danmuOn then
		if p.BarrageLayer ~= nil then
			p.BarrageLayer.AccordOneWordLabel(word);
		end
	end
end

function p.UIAction()
	p.RunActionOut(p.ui.Button_40);
	p.RunActionOut(p.ui.Button_40_0);
	p.RunActionOut(p.ui.Button_40_1);
	p.RunActionOut(p.ui.Button_40_2);
end

--弹出效果扩展
function p.RunActionOut(pObj)
	local arry = CCArray:create();
	local pScale_2 = CCScaleTo:create(0.18, 1.10);
	arry:addObject(pScale_2);
	local pScale_3 = CCScaleTo:create(0.08, 1.0);
	arry:addObject(pScale_3);

	local seq = CCSequence:create(arry);
	pObj:setScale(0.5);
	pObj:runAction(seq);
end

--显示隐藏战斗界面
function p.SetBShowBattle(bShow)
	if p.uiLayer ~= nil then
		p.uiLayer:setVisible(bShow);
	else
		cclog("***SetBShowBattle Error ***");
	end
end

function p.FightBattleIsShow()
	if p.uiLayer ~= nil then
		return p.uiLayer:isVisible();
	else
		cclog("***FightBattleIsShow Error ***");
	end	
	return false;
end

function p.BattleSaveCallback(logMesg, pHttpMsg)
	local pHttp = tolua.cast(pHttpMsg, "CCHttpMessage");
	if pHttp == nil then
		cclog("**************严重错误***************");
		return;
	end
	
	local pNDTransData = pHttp:GetMessageBuffer();
	if pNDTransData ~= nil then
		if MsgClassConvern.HttpMessageHead(pNDTransData) then
			MsgClassConvern.ReadHead(pNDTransData,2);
			UserData.AutoSellEquip = pNDTransData:readInt();
			UserData.AutoSellEquipQuality = pNDTransData:readInt();
		end
	end
end

--快速战斗协议返回
function p.SpeedFightCallback(logMesg, pHttpMsg)
	local pHttp = tolua.cast(pHttpMsg, "CCHttpMessage");
	if pHttp == nil then
		cclog("**************严重错误***************");
		return;
	end
	
	local pNDTransData = pHttp:GetMessageBuffer();
	if pNDTransData ~= nil then
		if MsgClassConvern.HttpMessageHead(pNDTransData) then
			local function pCreateHeroCall()
				-- if UserData.bNeedCreateRole	== 1 or UserData.bNeedCreateRole_Sec == 1 then
					-- local function pCreateProfess()
						-- OpenLayer(UI_TAG.SELECT_PROFESSION,0,UI_ZORDER.AllWin);
						-- UISelectProfession.SetShowType(1)
					-- end
					-- CreateAllInitHero(pCreateProfess)
				-- end	
			end
		
			local BattleResult = {};
		
			MsgClassConvern.OutLineBatteInfo(BattleResult,pNDTransData, 2);
			OpenLayer(UI_TAG.UI_OUTLINERESULT,0,101);
			UIOutLineResult.SetInfo(BattleResult,true,pCreateHeroCall);
			
			p:ShowBattleInfo(m_tInfo);
			UserData.QuickBattleTime = UserData.QuickBattleTime +1;
			UserData.Diamond = UserData.Diamond - p.Cost.Diomand;
			--数据统计
			TalkingData:onPurchase("快速战斗", 1, p.Cost.Diomand)
		end
	end
	p.msgBack = true;
end

--显示技能的名称
function p:ShowSkillName(nSkillId, isEnemy)
	if nSkillId == 10010 then
		return;
	end
	local pSprite = CCSprite:create("image/skill_message.png");
	if pSprite ~= nil then
		pSprite:setCascadeOpacityEnabled(true);
		local winSize = CCDirector:sharedDirector():getWinSize();
		local size = pSprite:getContentSize();
		if isEnemy then
			pSprite:setPosition(ccp(winSize.width, winSize.height*9/10));
		else
			pSprite:setPosition(ccp(0, winSize.height*9/10));
		end
		
		local skillName = CfgData["cfg_skill"][nSkillId]["name"];
		local skillType = CfgData["cfg_skill"][nSkillId]["type"];
		local skillFonts = nil;
		if skillType == 1 then --攻击技能
			skillFonts = "fonts/yellowSkill.fnt";
		elseif skillType == 2 then --增益技能
			skillFonts = "fonts/greenSkill.fnt";
		else
			cclog("***************技能字体配置错误---------------"..skillName);
		end
			
		local pLable = nil;
		if skillFonts ~= nil then
			pLable = CCLabelBMFont:create(skillName, skillFonts);
		else
			pLable = CCLabelTTF:create(skillName, "Arial", 22)
		end
		--[[
		local pLable = CCLabelTTF:create(skillName, "Arial", 22)
		if skillType == 1 then --攻击技能
			pLable:setColor(ccc3(255,215,0))
		elseif skillType == 2 then --增益技能
			pLable:setColor(ccc3(124,252,0))			
		end
		--]]
		
		pLable:setAnchorPoint(ccp(0,0));
		local lableSize = pLable:getContentSize();
		local x = (size.width - lableSize.width)/2;
		local y = (size.height - lableSize.height)/2;
		pLable:setPosition(ccp(x,y));
		pSprite:addChild(pLable, 1);
		p.Layer:addChild(pSprite,1000);
		
		local array2 = CCArray:create();
		local xOffset    = winSize.width/4;
		local xOffset_to = winSize.width*3/4;
		if isEnemy then
			xOffset    = -winSize.width/4;
			xOffset_to = -winSize.width*3/4;
		end
		
		
		array2:addObject(CCMoveBy:create(0.05, ccp(xOffset, 0)));
		array2:addObject(CCFadeIn:create(0.1));
		array2:addObject(CCDelayTime:create(0.8));
		array2:addObject(CCFadeOut:create(0.5));
		-- array2:addObject(CCMoveBy:create(0.1, ccp(xOffset_to, 0)));
		array2:addObject(CCRemoveSelf:create(true));
		local pAction = CCSequence:create(array2);	
		pSprite:runAction(pAction);
	end
end

--显示下一个战斗
function p.ShowNextGate(nStageID, bShow, strTitle)
	
	if bShow then
		local str     = CfgData["cfg_Stage"][nStageID]["name"];
		local strName = ZhTextSet_30337 ..str.."BOSS";
		if strTitle ~= nil then
			strName = strTitle;
		end
		local winSize = CCDirector:sharedDirector():getWinSize();
		if p.NextLabel == nil then
			p.NextLabel = CCLabelTTF:create(strName, "Arial", 24);
			p.NextLabel:setAnchorPoint(ccp(0,0));
			local lableSize = p.NextLabel:getContentSize();
			local x = (winSize.width - lableSize.width)/2;
			local y = winSize.height - 0;
			p.NextLabel:setPosition(ccp(x,y));
			
			local bgSprite = CCSprite:create("res/UserUI/images/equipnamebg.png");
			bgSprite:setAnchorPoint(ccp(0,0));
			local spriteSize = bgSprite:getContentSize();
			x = (lableSize.width - spriteSize.width)/2;
			y = -20;
			bgSprite:setPosition(ccp(x,y));
			bgSprite:setTag(1);
			p.NextLabel:addChild(bgSprite, -1);
			
			p.Layer:addChild(p.NextLabel,1000);
		else
			p.NextLabel:stopAllActions();
			p.NextLabel:setVisible(true);
			p.NextLabel:setString(strName);
			p.NextLabel:setAnchorPoint(ccp(0,0));
			local lableSize = p.NextLabel:getContentSize();
			local x = (winSize.width - lableSize.width)/2;
			local y = winSize.height - 0;
			p.NextLabel:setPosition(ccp(x,y));
			
			local bgSprite = tolua.cast(p.NextLabel:getChildByTag(1), "CCSprite");
			if bgSprite ~= nil then
				bgSprite:setAnchorPoint(ccp(0,0));
				local spriteSize = bgSprite:getContentSize();
				x = (lableSize.width - spriteSize.width)/2;
				y = -20;
				bgSprite:setPosition(ccp(x,y));
			end
		end
		--Action
		local array2 = CCArray:create();
		array2:addObject(CCShow:create());
		array2:addObject(CCMoveBy:create(0.5, ccp(0, -100)));
		local pAction = CCSequence:create(array2);	
		p.NextLabel:runAction(pAction);
	else
		if p.NextLabel ~= nil then
			if p.NextLabel:isVisible() then
				local array2 = CCArray:create();
				array2:addObject(CCMoveBy:create(0.5, ccp(0, 100)));
				array2:addObject(CCHide:create());
				local pAction = CCSequence:create(array2);	
				p.NextLabel:runAction(pAction);
			end
		end
	end

end


--更新血条
--nTag实体ID;
--nHp 剩余HP;
function p:UpdateHp(nTag, nHp)
	p:ShowHpAction(nTag, nHp);
end

--获取战斗英雄名字
function p:GetHeroNameByTagId(nTag)
	local strName = "";
	local tInfo = nil;
	local nMaxHp = nil;
	for i,v in ipairs(m_BattleSprite) do
		for j,d in ipairs(v) do
			if d.nId == nTag then
				strName=d.sName;
				break;
			end
		end
	end
	return strName
end

-- 显示血条动作
function p:ShowHpAction(nTag, nNowHp)

	local tArmatureSprite = SpriteArmaturePool:GetArmature(nTag);
	if tArmatureSprite ~= nil then
		
		local tInfo = nil;
		local nMaxHp = nil;
		for i,v in ipairs(m_BattleSprite) do
			for j,d in ipairs(v) do
				if d.nId == nTag then
					nMaxHp = d.nMaxHp;
					tInfo = d;
				end
			end
			if nMaxHp ~= nil then
				break;
			end
		end
		
		if nMaxHp == nil then
			cclog("******************** 显示血条动作 ShowHpAction 错误");
			return;
		end
		
		if tArmatureSprite.ProgressTimer == nil then
			-- tArmatureSprite:CreateProgressTimer("image/hp_green.png", "image/hp_red.png","image/heroxp-progress-bg.png");
			-- tArmatureSprite:CreateProgressTimer2("image/blue.png", "image/red.png","image/hp_img.png", tInfo.sName, tInfo.nLevel);
			local logImage = "image/cirle.png";
			local strName  = tInfo.sName;
			local nLevel   = tInfo.nLevel;
			if tArmatureSprite.IsEnemy then
				if tInfo.nRace > 36000 then
					--Boss
					logImage = "image/cirle_3.png";
					nLevel = "";
				end
			else
				strName  = "";
				nLevel   = "";
				local nIndex = 0;
				for k,v in pairs(UserData.tIdleHeroList) do
					nIndex = nIndex + 1;
					if tonumber(k) == tArmatureSprite.SpriteTag then
						break;
					end
				end
				if nIndex ~= 0 then
					logImage = "image/"..nIndex.."p.png";
				else
					cclog("***严重的错误***");
				end
			end
			tArmatureSprite:CreateProgressTimer3("image/blue_hp.png", "image/red_hp.png","image/black_hp.png", logImage, strName, nLevel);
		end
		
		local nPrecent = math.floor(nNowHp/nMaxHp*100);
		local nNowPre  = tArmatureSprite.ProgressTimer:getPercentage();
		tArmatureSprite.ProgressTimer:setPercentage(nPrecent);
		tArmatureSprite.ProgressTimerRed:setPercentage(nPrecent);
		tArmatureSprite.ProgressTimerRed:runAction(CCProgressFromTo:create(1.0, nNowPre, nPrecent));
		
		--
		local array = CCArray:create();
		array:addObject(CCShow:create());
		local pMove = CCMoveBy:create(0.02, ccp(0,-20));
		array:addObject(pMove);
		array:addObject(pMove:reverse());
		local pMove = CCMoveBy:create(0.03, ccp(10,10));
		array:addObject(pMove);
		array:addObject(pMove:reverse());
		local pMove = CCMoveBy:create(0.05, ccp(-8, 8));
		array:addObject(pMove);
		array:addObject(pMove:reverse());
		array:addObject(CCDelayTime:create(1.0));
		array:addObject(CCHide:create());
		local pAction = CCSequence:create(array);
		
		tArmatureSprite.ProgressTimer:setCascadeOpacityEnabled(true);
		tArmatureSprite.ProgressTimer:runAction(pAction);
		--]]
	end
end

-- 显示战斗信息
function p:ShowBattleInfo(tInfo)
	p.BattleBeginCall(true)
	if tInfo ~= nil then
		m_tInfo = tInfo;
		-- Label_nextexp_2
		local levelCfg = CfgData.cfg_leave[UserData.TeamLevel];
		if levelCfg ~= nil then
			local nMaxExp = tonumber(levelCfg.term_experience);
			local nNowExp = tonumber(UserData.TeamExp);
			local nNeedExp = nMaxExp - nNowExp;
			local nNeedOur = math.floor(nNeedExp/tInfo.ExpPeHour*100)/100;
			local pLable = tolua.cast(p.ui["Label_nextexp_2"], "Label");
			if pLable ~= nil then
				local str = "";
				local nMin = nNeedOur-math.floor(nNeedOur);
				local nHour = math.mod(nNeedOur, 24);
				local nDay  = math.floor(nNeedOur/24);
				if nDay > 0 then
					str = nDay..ZhTextSet_30306;
				end
				if nHour >= 1 then
					str= str..math.floor(nHour)..ZhTextSet_50108;
				end
				if nMin > 0 then
					nMin = nMin*60;
					str = str..math.floor(nMin+0.5)..ZhTextSet_30308
				end
				
				if str == "" then
					str = ZhTextSet_30338
				end
				pLable:setText(str);
			end
		end
		-- Label_timelong
		-- cclog(tInfo.FightTime)  --战斗时间
		local pLable = tolua.cast(p.ui["Label_timelong"], "Label");
		if pLable ~= nil then
			local showStr = "";
			local tab = os.date("*t", tInfo.FightTime);
			if tab.hour-8 > 0 then
				showStr = (tab.hour-8)..ZhTextSet_50108
				showStr = showStr..string.format("%02d",tab.min)..ZhTextSet_30308;
			else
				if tab.min > 0 then
					showStr = string.format("%02d",tab.min)..ZhTextSet_30308;
				end
			end

			if tab.sec > 0 then
				showStr = showStr..tab.sec..ZhTextSet_30309;
			end
			-- local showStr = (string.format("%02d:%02d:%02d", tab.hour-8, tab.min, tab.sec));
			pLable:setText(tostring(showStr));
		end
		
		-- Label_fightnum
		-- cclog(tInfo.BattleNum)  --战斗次数
		local pButton = tolua.cast(p.ui.Button_79, "Button");
		if pButton ~= nil then
			if UserData.OnhookStageId ~= UserData.LatestStageId then 
				--支持扫荡BOSS
				if UserData.VipLevel >= 1 then
					local str = ZhTextSet_10208
					str = str.."BOSS";
					pButton:setTitleText(str);
					pButton:setBright(true);
					pButton:setTouchEnabled(true);
					ui_add_click_listener(pButton, function(sender,eventype)
							local function pCallback()
								p.SweepStageBoss(UserData.OnhookStageId);
							end
							--扫荡boss
							local t = recursionAnalyzeSuperHtmlString(nil,ZhTextSet_30302);
							TipsManager.ShowConfirmBox(ZhTextSet_30301,t,pCallback);
						end)
				else
					local str = ZhTextSet_30125;
					str = str.."BOSS";
					pButton:setTitleText(str);
					pButton:setBright(false);
					pButton:setTouchEnabled(false);
				end
			else
				pButton:setBright(true);
				pButton:setTouchEnabled(true);
				local str = ZhTextSet_30125;
				str = str.."BOSS";
				pButton:setTitleText(str);
			end
		end
		
		local pLable = tolua.cast(p.ui["Label_fightnum"], "Label");
		if pLable ~= nil then
			if UserData.ChallengeTime > 0 then
				pLable:setText(tostring(UserData.ChallengeTime).."次");
			else
				--
				--显示券的数量
				local item = UserData.GetItemInfo(202);
				if CheckT(item) then
					if item.MutilNum > 0 then
						local str = string.format(ZhTextSet_30333,item.MutilNum)
						pLable:setText(str);
					else
						pLable:setText("0");
					end
				else
					pLable:setText("0");
				end
			end
		end
		
		-- Label_coinnum
		-- cclog(tInfo.CoinPHour)  --战斗金币
		local pLable = tolua.cast(p.ui["Label_coinnum"], "Label");
		if pLable ~= nil then
			pLable:setText(tostring(tInfo.CoinPHour));
		end
		
		-- Label_expnum
		-- cclog(tInfo.ExpPeHour)  --战斗经验
		local pLable = tolua.cast(p.ui["Label_expnum"], "Label");
		if pLable ~= nil then
			pLable:setText(tostring(tInfo.ExpPeHour));
		end
		
		-- Label_dropch
		-- cclog(tInfo.DropRate)   --装备掉率
		local pLable = tolua.cast(p.ui["Label_dropch"], "Label");
		if pLable ~= nil then
			local fValue = tInfo.DropRate/100;
			pLable:setText(fValue.."%");
		end
		
		-- Label_8
		-- cclog(tInfo.SafetyVal)  --战斗安全
		local pLable = tolua.cast(p.ui["Label_8"], "Label");
		if pLable ~= nil then
			pLable:setZOrder(1);
			pLable:setText(ZhTextSet_30339 ..tostring(tInfo.SafetyVal).."%");
		end
		p:UpdateBattlePro(tInfo.SafetyVal);
		
		local bShow = false;
		if tInfo.SafetyVal == 100 then
			local nValue = UserData.bDataByteValue(UserData.UserGuideNum,7) --切换地图引导还没做
			if nValue == 0 or UserData.LatestStageId <= 40105  then
				bShow = true;
			end
		end
		
		local pImage = tolua.cast(p.ui.Image_Icon,"ImageView");
		if pImage ~= nil then
			pImage:setVisible(false);
		end
		MainBtn.SetMainBtnBattleInfo(tInfo.SafetyVal)
		
		--装备双倍
		p.ui.Image_activity1:setVisible(false)
		if tInfo.EquipRate == 1 then
			p.ui.Image_activity1:setVisible(true)
		end
		--经验双倍
		p.ui.Image_activity2:setVisible(false)
		if tInfo.ExpRate == 1 then
			p.ui.Image_activity2:setVisible(true)
		end
		--金币双倍
		p.ui.Image_activity3:setVisible(false)
		if tInfo.CoinRate == 1 then
			p.ui.Image_activity3:setVisible(true)
		end
		
	end
end

function p.SetButtonMark()
	spriteExportJson = "res/armature/City/Effectbuttonmark/Effectbuttonmark.ExportJson";
	CCArmatureDataManager:sharedArmatureDataManager():addArmatureFileInfo(spriteExportJson);
	local ButtonMark = CCArmature:create("Effectbuttonmark");
	ButtonMark:getAnimation():play("Animation1");
	ButtonMark:setPosition(ccp(0,0));
	ButtonMark:setScale(0.75);
	p.ButtonMark = ButtonMark;
	
	local pBone = tolua.cast(ButtonMark:getBone("Layer3"),"CCBone");
	if pBone ~= nil then
		local pNode = pBone:getDisplayRenderNode();
		if pNode ~= nil then
			local pParti = tolua.cast(pNode, "CCParticleSystemQuad");
			if pParti ~= nil then
				pParti:setPositionType(kCCPositionTypeRelative);
			end
		end
	end
	
	pBone = tolua.cast(ButtonMark:getBone("Layer5"),"CCBone");
	if pBone ~= nil then
		local pNode = pBone:getDisplayRenderNode();
		if pNode ~= nil then
			local pParti = tolua.cast(pNode, "CCParticleSystemQuad");
			if pParti ~= nil then
				pParti:setPositionType(kCCPositionTypeRelative);
			end
		end
	end
	p.ui.Button_40_0:addNode(ButtonMark);
end

-- 更新战斗安全度进度条
function p:UpdateBattlePro(nPersent)
	local pImage = tolua.cast(p.ui["Image_10"], "ImageView");
	local pBtn = tolua.cast(p.ui["Button_79"], "Button");
	local pLab = tolua.cast(p.ui["Label_80"], "Label");
	
	if pImage ~= nil then
		local size = pImage:getSize();
		if pImage:getNodeByTag(1) == nil or pImage:getNodeByTag(2)==nil then
			local pProcess = CCProgressTimer:create(CCSprite:create("UserUI/images/progressjd.png"));
			pProcess:setType(kCCProgressTimerTypeBar);
			pProcess:setMidpoint(ccp(0, 0));
			pProcess:setBarChangeRate(ccp(1, 0));
			pProcess:setPosition(ccp(0, 0));
			pProcess:setPercentage(nPersent);
			pImage:addNode(pProcess, 0, 1);
			
			local pProcess = CCProgressTimer:create(CCSprite:create("UserUI/images/progressjdbg.png"));
			pProcess:setType(kCCProgressTimerTypeBar);
			pProcess:setMidpoint(ccp(0, 0));
			pProcess:setScale(-1);
			pProcess:setBarChangeRate(ccp(1, 0));
			pProcess:setPosition(ccp(0, 0));
			pProcess:setPercentage(100-nPersent);
			pImage:addNode(pProcess, 0, 2);
			
			local pSprite = CCSprite:create("UserUI/images/progressnumbg.png");
			--
				local pLable = CCLabelTTF:create(" ", "Arial", 20);
				pLable:setAnchorPoint(ccp(0,0));
				local lableSize = pLable:getContentSize();
				local sprSize = pSprite:getContentSize();
				local x = math.floor(size.width*nPersent/100 - size.width/2);
				local y = (sprSize.height - lableSize.height)/2+2;
				pLable:setPosition(ccp(x,y));
				
				--pBtn:setPositionX(x);
				
				pLab:setText(tostring(nPersent).."%");
				
				pSprite:addChild(pLable,0, 1);
			--]]
			pSprite:setPosition(ccp(0, 20));
			--pImage:addNode(pSprite, 0, 3);
			
		else
			local pProcess = tolua.cast(pImage:getNodeByTag(1), "CCProgressTimer");
			if pProcess ~= nil then
				pProcess:setPercentage(nPersent);
			end
			
			local pProcess = tolua.cast(pImage:getNodeByTag(2), "CCProgressTimer");
			if pProcess ~= nil then
				pProcess:setPercentage(100-nPersent);
			end
			local x = math.floor(size.width*nPersent/100 - size.width/2);
			--pBtn:setPositionX(x);
			
			pLab:setText(tostring(nPersent).."%");
			--[[local pSprite = tolua.cast(pImage:getNodeByTag(3), "CCSprite");
			if pSprite ~= nil then
				local x = math.floor(size.width*nPersent/100 - size.width/2);
				pSprite:setPosition(ccp(x, 20));
				pBtn:setPositionX(x);
				--
				--Label
				local pLable = tolua.cast(pSprite:getChildByTag(1), "CCLabelTTF");
				if pLable ~= nil then
					pLable:setString(tostring(nPersent).."%");
					pLable:setAnchorPoint(ccp(0,0));
					local lableSize = pLable:getContentSize();
					local sprSize = pSprite:getContentSize();
					local x = (sprSize.width - lableSize.width)/2;
					local y = (sprSize.height - lableSize.height)/2+2;
					pLable:setPosition(ccp(x,y));
					
				end
				
			end--]]
		end		
	end
end

--进入关卡boss挑战
function p.enterStageBoss()
	local nItemId = UserData.LatestStageId;
	if nItemId > UserData.LatestStageId then
		--未开启
		TipsManager.ShowTips(ZhTextSet_10201);
	else
		local nNum = 0;
		local nItem202 = UserData.GetItemInfo(202)
		if nItem202 ~= nil then
			nNum = nItem202.MutilNum;
		end
		
		if UserData.ChallengeTime > 0 or nNum > 0 then
			GameFightContract.StageBossReq(nItemId)
			GameFightCenter.SetBShowBattle(true)
		else
			TipsManager.ShowTips(ZhTextSet_20003);
		end
	end
end


-- 战斗网络请求
function p:BattleRequest()
	local function pCallback(logMesg, pHttpMsg)

		local pHttp = tolua.cast(pHttpMsg, "CCHttpMessage");
		if pHttp == nil then
			cclog("**************严重错误***************");
			return;
		end
	
		local pNDTransData = pHttp:GetMessageBuffer();
		if pNDTransData ~= nil then
			if MsgClassConvern.HttpMessageHead(pNDTransData) then
				local nHeader = pNDTransData:readInt();   
				local nHeader2 = pNDTransData:readInt();
				local strLen = pNDTransData:readInt();
				local battleStr = pNDTransData:readString(strLen);
				p:ParsingBattle(battleStr);
			end
		end
	end
	NetReq.ReqBattle(pCallback);
end

-- 战斗字符串解析
function p:ParsingBattle(battleStr, nStageId, fTimeValue, bChangePos)
	
	--删除所有精灵
	SpriteArmaturePool:RemoveAllArmature();
	--保存战斗数据
	if false then
		local pGameUpdate = CGameUpdate:sharedGameUpdate();
		if pGameUpdate ~= nil then
			local nSysPlatFrom = pGameUpdate:getSysPlatform();
			if nSysPlatFrom == 3 then --WIN32
				local fileWritePath = CCFileUtils:sharedFileUtils():getWritablePath();
				local savePath = fileWritePath.."res/fight_bak/";
				pGameUpdate:createDirectory(savePath);
				local fileName = savePath..os.date("%Y_%m_%d_%H_%M_%S")..".txt";
				FileOperate:WriteToFile(fileName, "w", battleStr);
			else --IOS Android
				local fileWritePath = CCFileUtils:sharedFileUtils():getWritablePath();
				local savePath = fileWritePath.."fight_bak/";
				pGameUpdate:createDirectory(savePath);
				local fileName = savePath..os.date("%Y_%m_%d_%H_%M_%S")..".txt";
				FileOperate:WriteToFile(fileName, "w", battleStr);
			end
		end
	end
	
	m_BattleSprite = nil;
	m_BattleSprite = {};
	--
	local xOffset = 0;
	local yOffset = m_yOffest;
	
	--战斗数据分割(英雄数据/战斗数据)
	local battleTb = Split(battleStr, "#", false);
	
	--英雄数据
	local heroTb = Split(battleTb[1], "|", false);
	
	--清空异步加载的骨骼数据
	m_SyncArmatureTb  = {};
	
	--攻击方英雄数据
	m_BattleSprite[1] = {};
	local tAttackTb = Split(heroTb[1], "&", false);
	for i,v in ipairs(tAttackTb) do
		if v~="" then
			local heroInfo = Split(v, "_", false);
			local tHero = {};
			tHero.IsEnemy = false;
			tHero.nId 	= tonumber(heroInfo[1]);	--实体ID
			tHero.sName = heroInfo[2];				--昵称
			tHero.nLevel = tonumber(heroInfo[3]);	--等级
			tHero.nRace = tonumber(heroInfo[4]);	--种族
			tHero.nRole	= tonumber(heroInfo[5]);	--职业
			tHero.nWeap = tonumber(heroInfo[6]);	--武器
			tHero.nArmor= tonumber(heroInfo[7]);	--防具
			tHero.nMaxHp= tonumber(heroInfo[8]);	--血量上限
			tHero.nSkillStoneId  = tonumber(heroInfo[9]);	--技能石配置ID
			tHero.nSkillStoneLev = tonumber(heroInfo[10]);	--技能石等级
			
			table.insert(m_BattleSprite[1], tHero);
			
			-- 骨骼资源异步加载列表
			if bChangePos ~= nil then
				if bChangePos then
					table.insert(m_SyncArmatureTb,{tHero.nRace, tHero.nRole});
				end
			end
		end
	end
	

	
	--被攻击方英雄数据
	m_BattleSprite[2] = {};
	local tBeAttackTb = Split(heroTb[2], "&", false);
	for i,v in ipairs(tBeAttackTb) do
		if v~="" then
			local heroInfo = Split(v, "_", false);
			local tHero = {};
			tHero.IsEnemy = true;
			tHero.nId 	= tonumber(heroInfo[1]);	--实体ID
			tHero.sName = heroInfo[2];				--昵称
			tHero.nLevel = tonumber(heroInfo[3]);	--等级
			tHero.nRace = tonumber(heroInfo[4]);	--种族
			if tHero.nRace > 35000 then
				--是怪物
				tHero.sName = CfgData["cgf_monster"][tHero.nRace]["name"];
			end
			tHero.nRole	= tonumber(heroInfo[5]);	--职业
			tHero.nWeap = tonumber(heroInfo[6]);	--武器
			tHero.nArmor= tonumber(heroInfo[7]);	--防具
			tHero.nMaxHp= tonumber(heroInfo[8]);	--血量上限
			tHero.nSkillStoneId  = tonumber(heroInfo[9]);	--技能石配置ID
			tHero.nSkillStoneLev = tonumber(heroInfo[10]);	--技能石等级
			table.insert(m_BattleSprite[2], tHero);
			
			-- 骨骼资源异步加载列表
			if bChangePos == nil or not bChangePos then
				table.insert(m_SyncArmatureTb,{tHero.nRace, tHero.nRole});
			end
		end
	end
	
	--
	if bChangePos then
		p:InitBattleSpite(m_BattleSprite[2], false, xOffset, yOffset);
	else
		p:InitBattleSpite(m_BattleSprite[1], false, xOffset, yOffset);
	end
	
	--初始化文字战报英雄数据
	GameFightTextBattle.InitTextBattleInfo(m_BattleSprite);
	
	--战斗回合数据
	m_BattleDate = nil;
	m_BattleDate = {};
	for i=2 ,#battleTb do
		local tbRound = {};
		local tRoundTb = Split(battleTb[i], "/", false);
		for i,v in ipairs(tRoundTb) do
			if v~="" then
				--单次行动数据
				local tb = p:SingleMessage(v);
				table.insert(tbRound, tb);
			end
		end
		table.insert(m_BattleDate, tbRound);
	end
	
	--地图跑动
	m_bStop = false;
	if not m_bInitMap then
		p:RuningMapInit(yOffset);
		m_bInitMap = true;
	end
	
	--
	if fTimeValue == nil or fTimeValue <= 0 then
		--进入战斗
		--等待异步加载骨骼资源完毕
		local function funcBack()
			if nStageId ~= 42000 then
				p:DoFightBegin();
			else
				p:DoFightOppBegin();
			end
			p:StartGameFight();
			
			--
			GameFightTextBattle.AddBattleTextStr(ZhTextSet_30340,22, ccc3(0,0,0));
		end
		SkillResourcesLoad:AsyncLoadModuleArmature(m_SyncArmatureTb, funcBack);
	else
		--角色单纯跑步走路
		p:HeroRunOrWalk(fTimeValue);
	end
end

-- 一个战斗回合数据解析
function p:SingleMessage(strMessage)
	local tb = {}
	local battleTb = Split(strMessage, "|", false);
	
	--行动部分
	if battleTb[1] ~= "" then
		tb[1] = {};
		local tMoveData = Split(battleTb[1], "&", false);
		for i, v in ipairs(tMoveData) do
			if v ~= "" then
				tb[1][i] = {};
				local tMoveData1 = Split(v, "_", false);
				-- 攻击者实体ID
				tb[1][i].nAttackId = tonumber(tMoveData1[1]);
				-- 技能ID
				tb[1][i].nSkillId = tonumber(tMoveData1[2]);
				-- 被击者实体ID
				tb[1][i].nBeAttackId = {tonumber(tMoveData1[3])};
				-- 攻击结果
				tb[1][i].nAttackType = tonumber(tMoveData1[4]);
				-- 伤害数值
				local tDamageHurt = Split(tMoveData1[5], ",", true);
				if #tDamageHurt > 0 then
					tb[1][i].nDamageHurt = tDamageHurt;
				else
					tb[1][i].nDamageHurt = {};
					table.insert(tb[1][i].nDamageHurt, tonumber(tMoveData1[5]));
				end
				-- 附加状态串
				tb[1][i].sAdditional = tMoveData1[6];
			end
		end
	end
	
	--状态部分
	if battleTb[2] ~= "" then
		tb[2] = {};
		local tMoveData = Split(battleTb[2], "&", false);
		for i, v in ipairs(tMoveData) do
			if v ~= "" then
				tb[2][i] = {};
				local tMoveData1 = Split(v, "_", false);
				-- 攻击者实体ID
				tb[2][i].nAttackId = tonumber(tMoveData1[1]);
				-- 技能ID
				tb[2][i].nSkillId = tonumber(tMoveData1[2]);
				-- 被击者实体ID
				tb[2][i].nBeAttackId = {tonumber(tMoveData1[3])};
				-- 攻击结果
				tb[2][i].nAttackType = tonumber(tMoveData1[4]);
				-- 伤害数值
				tb[2][i].nDamageHurt = tonumber(tMoveData1[5]);
				-- 附加状态串
				tb[2][i].sAdditional = tMoveData1[6];
			end
		end
	end
	return tb;
end

-- 开始战斗
function p:DoFightBegin()
	if handTime ~= nil then
		Scheduler.unscheduleGlobal(handTime);
		handTime = nil;
	end
	m_bStop = false;
	GameFightMusic.PlayWalkOnMap(false);
	GameFightMusic.PlayRunOnMap(true);
	
	local function listenerRun()
		local function listenerMove()
			
			local winSize = CCDirector:sharedDirector():getWinSize();
			local function callBack()
				SpriteArmaturePool:SetAllSpriteStateMachibe("normal");
				p:BeginFightTimer();
				m_bStop = true;
				GameFightMusic.PlayWalkOnMap(false);
				GameFightMusic.PlayRunOnMap(false);
			end
			p:ShowEnemy(winSize, m_yOffest, callBack);
		end
		Scheduler.performWithDelayGlobal(listenerMove, 1);
		SpriteArmaturePool:SetAllSpriteStateMachibe("move");
		x_speed_1 = 20;
		x_speed_2 = 25;	
		GameFightMusic.PlayWalkOnMap(true);
		GameFightMusic.PlayRunOnMap(false);
	end
	x_speed_1 = 35;
	x_speed_2 = 45;
	
	Scheduler.performWithDelayGlobal(listenerRun, 1);
	SpriteArmaturePool:SetAllSpriteStateMachibe("run");
end

-- 竞技场时候不跑图
function p:DoFightOppBegin()
	
	m_bStop = true;
	if handTime ~= nil then
		Scheduler.unscheduleGlobal(handTime);
		handTime = nil;
	end
	
	GameFightMusic.PlayWalkOnMap(false);
	GameFightMusic.PlayRunOnMap(false);
	
	local function listenerRun()
		-- local function listenerMove()
			local winSize = CCDirector:sharedDirector():getWinSize();
			local function callBack()
				SpriteArmaturePool:SetAllSpriteStateMachibe("normal");
				p:BeginFightTimer();
			end
			p:ShowEnemy(winSize, m_yOffest, callBack);
		-- end
		-- Scheduler.performWithDelayGlobal(listenerMove, math.random(1,2));
		-- SpriteArmaturePool:SetAllSpriteStateMachibe("move");
		-- x_speed_1 = 20;
		-- x_speed_2 = 25;
	end
	-- x_speed_1 = 35;
	-- x_speed_2 = 45;
	
	Scheduler.performWithDelayGlobal(listenerRun, math.random(1,2));
	-- SpriteArmaturePool:SetAllSpriteStateMachibe("run");
	SpriteArmaturePool:SetAllSpriteStateMachibe("normal");
	
	p.SetAllMapPos(-180, m_yOffest);
	
end

-- 角色地图只进行跑步
function p:HeroRunOrWalk(fTimeValue)
	
	if handTime ~= nil then
		Scheduler.unscheduleGlobal(handTime);
		handTime = nil;
	end
	m_bStop = false;
	
	x_speed_1 = 35;
	x_speed_2 = 45;
	
	GameFightMusic.PlayWalkOnMap(false);
	GameFightMusic.PlayRunOnMap(true);
	SpriteArmaturePool:SetAllSpriteStateMachibe("run");
	
	local isRunBool = true;
	local nWalkValu = 5;
	
	
	if m_LoopWalkTime ~= nil then
		Scheduler.unscheduleGlobal(m_LoopWalkTime);
		m_LoopWalkTime = nil;
	end
	--获取系统时间
	-- cclog("---搜索怪物时间:%d---",fTimeValue);
	local fBeginTime = os.time() + fTimeValue;
	local function loopFunc()
		
		nWalkValu = nWalkValu - 1;
		if nWalkValu < 0 then
			if isRunBool then
				x_speed_1 = 20;
				x_speed_2 = 25;
				nWalkValu = math.random(3,5);
				GameFightMusic.PlayWalkOnMap(true);
				GameFightMusic.PlayRunOnMap(false);
				SpriteArmaturePool:SetAllSpriteStateMachibe("move");
			else
				x_speed_1 = 35;
				x_speed_2 = 45;
				nWalkValu = math.random(1,2);
				
				GameFightMusic.PlayWalkOnMap(false);
				GameFightMusic.PlayRunOnMap(true);
				SpriteArmaturePool:SetAllSpriteStateMachibe("run");
			end
			
			isRunBool = not isRunBool;
		end

		local fNowTime = os.time();		
		if fBeginTime <= fNowTime then
			Scheduler.unscheduleGlobal(m_LoopWalkTime);
			m_LoopWalkTime = nil;
			GameFightContract.BattleMainRequest(true);
		end
	end
	m_LoopWalkTime = Scheduler.scheduleGlobal(loopFunc, 1.0);

end

--如果是在走路执行战斗直接进入
function p:InHeroWalkRunBattle()
	if m_LoopWalkTime ~= nil then
		Scheduler.unscheduleGlobal(m_LoopWalkTime);
		m_LoopWalkTime = nil;
		GameFightContract.BattleMainRequest(true);
		return false;
	end
	return  true;
end

--地图初始化
function p:MapImageInit()

    local sprite = CCSprite:create("map/1_1.png");
	sprite:setAnchorPoint(ccp(0,0))
	sprite:setTag(10000);
    p.Layer:addChild(sprite,0);
	
    local sprite_ex = CCSprite:create("map/1_1.png");
	sprite_ex:setAnchorPoint(ccp(0,0))
	sprite_ex:setTag(10001);
    p.Layer:addChild(sprite_ex, 1);
	
    local sprit2 = CCSprite:create("map/1_2.png");
	sprit2:setAnchorPoint(ccp(0,0))
	sprit2:setTag(10002);
    p.Layer:addChild(sprit2,5);
	
    local sprite2_ex = CCSprite:create("map/1_2.png");
	sprite2_ex:setAnchorPoint(ccp(0,0))
	sprite2_ex:setTag(10003);
    p.Layer:addChild(sprite2_ex,5);

    local sprit3 = CCSprite:create("map/1_3.png");
	sprit3:setAnchorPoint(ccp(0,0))
	sprit3:setTag(10004);
    p.Layer:addChild(sprit3,1000);
	

    local sprite3_ex = CCSprite:create("map/1_3.png");
	sprite3_ex:setAnchorPoint(ccp(0,0))
	sprite3_ex:setTag(10005);
    p.Layer:addChild(sprite3_ex,1000);
	
    local sprit44 = CCSprite:create("map/1_4.png");
	sprit44:setAnchorPoint(ccp(0,0))
	sprit44:setTag(10009);
    p.Layer:addChild(sprit44,10);
	

    local sprite44_ex = CCSprite:create("map/1_4.png");
	sprite44_ex:setAnchorPoint(ccp(0,0))
	sprite44_ex:setTag(10010);
    p.Layer:addChild(sprite44_ex,10);
	
	--	
    local sprite4 = CCSprite:create();
	sprite4:setContentSize(CCSizeMake(640,512));
	sprite4:setAnchorPoint(ccp(0,0))
	sprite4:setTag(10006);
    p.Layer:addChild(sprite4, 999);

	--	
    local sprite5 = CCSprite:create();
	sprite5:setContentSize(CCSizeMake(640,512));
	sprite5:setAnchorPoint(ccp(0,0))
	sprite5:setTag(10007);
    p.Layer:addChild(sprite5, 1001);
	
    local sprite6 = CCSprite:create();
	sprite6:setContentSize(CCSizeMake(640,512));
	sprite6:setAnchorPoint(ccp(0,0))
	sprite6:setTag(10008);
    p.Layer:addChild(sprite6, 2);

    local sprite7 = CCSprite:create();
	sprite7:setContentSize(CCSizeMake(640,512));
	sprite7:setAnchorPoint(ccp(0,0))
	sprite7:setTag(10011);
    p.Layer:addChild(sprite7, 6);
	
end

--
function p:getPos(x1, x2, w, sped)
	if x1 < -w then
		x1,x2 = x2,x1;
	end
	x1 = x1 - sped*0.1;
	x2 = x1 + w;
	return x1, x2;
end

-- 地图初始化
function p:RuningMapInit(yOffset)

	--速度	
	local xOffset_1 = x_speed_1*0.1;
	local xOffset_2 = x_speed_2*0.1;
	
	local x_w_1 = 0;
	----------1
	local sprite = tolua.cast(p.Layer:getChildByTag(10000), "CCSprite");
	if sprite ~= nil then
		x_w_1 = sprite:getContentSize().width;
		sprite:setPosition(ccp(0,yOffset))
	end
	local sprite_ex = tolua.cast(p.Layer:getChildByTag(10001), "CCSprite");
	if sprite_ex ~= nil then
		sprite_ex:setPosition(ccp(x_w_1-xOffset_1,yOffset));
	end

	----------2
	local sprit2 = tolua.cast(p.Layer:getChildByTag(10002), "CCSprite");
	if sprit2 ~= nil then
		sprit2:setPosition(ccp(0,yOffset))
	end
	local sprite2_ex = tolua.cast(p.Layer:getChildByTag(10003), "CCSprite");
	if sprite2_ex ~= nil then
		sprite2_ex:setPosition(ccp(x_w_1-xOffset_2,yOffset));
	end
	----------3
	local sprit3 = tolua.cast(p.Layer:getChildByTag(10004), "CCSprite");
	if sprit3 ~= nil then
		sprit3:setPosition(ccp(0,yOffset));
	end
	local sprite3_ex = tolua.cast(p.Layer:getChildByTag(10005), "CCSprite");
	if sprite3_ex ~= nil then
		sprite3_ex:setPosition(ccp(x_w_1-xOffset_2,yOffset));
	end
	-----------4
	local sprit44 = tolua.cast(p.Layer:getChildByTag(10009), "CCSprite");
	if sprit44 ~= nil then
		sprit44:setPosition(ccp(0,yOffset));
	end
	local sprit44_ex = tolua.cast(p.Layer:getChildByTag(10010), "CCSprite");
	if sprit44_ex ~= nil then
		sprit44_ex:setPosition(ccp(x_w_1-xOffset_2,yOffset));
	end
	
	------------
	local sprite4 = tolua.cast(p.Layer:getChildByTag(10006), "CCSprite");
	if sprite4 ~= nil then
		sprite4:setPosition(ccp(0,yOffset));
	end

	local sprite5 = tolua.cast(p.Layer:getChildByTag(10007), "CCSprite");
	if sprite5 ~= nil then
		sprite5:setPosition(ccp(0,yOffset));
	end

	local sprite6 = tolua.cast(p.Layer:getChildByTag(10008), "CCSprite");
	if sprite6 ~= nil then
		sprite6:setPosition(ccp(0,yOffset));
	end
	
	local function runMapTime()
		
		if m_bStop then
			return;
		end
		local x1,y1 = sprite:getPosition();
		local x2,y2 = sprite_ex:getPosition();
		------------------------------------		
		x1,x2 = p:getPos(x1, x2, x_w_1, x_speed_1);
		if x1 >= 640 then
			sprite:setZOrder(1);
			sprite_ex:setZOrder(0);
		end
		sprite:setPosition(ccp(x1,yOffset));
		if x2 >= 640 then
			sprite:setZOrder(0);
			sprite_ex:setZOrder(1);
		end
		sprite_ex:setPosition(ccp(x2,yOffset));		
		--------------------------
		--*******************************************************
		local x1,y1 = sprit2:getPosition();
		local x2,y2 = sprite2_ex:getPosition();
		------------------------------------
		x1,x2 = p:getPos(x1, x2, x_w_1, x_speed_2);
		sprit2:setPosition(ccp(x1,yOffset));
		sprite2_ex:setPosition(ccp(x2,yOffset));		
		--------------------------
		--*******************************************************
		local x1,y1 = sprit3:getPosition();
		local x2,y2 = sprite3_ex:getPosition();
		------------------------------------
		x1,x2 = p:getPos(x1, x2, x_w_1, x_speed_2);
		sprit3:setPosition(ccp(x1,yOffset));
		sprite3_ex:setPosition(ccp(x2,yOffset));		
		--------------------------
		
		--*******************************************************
		local x1,y1 = sprit44:getPosition();
		local x2,y2 = sprit44_ex:getPosition();
		------------------------------------
		x1,x2 = p:getPos(x1, x2, x_w_1, x_speed_2);
		sprit44:setPosition(ccp(x1,yOffset));
		sprit44_ex:setPosition(ccp(x2,yOffset));		
		--------------------------
		
	end
	-- Scheduler.scheduleGlobal(runMapTime, 0);
	Scheduler.scheduleNode(p.Layer, runMapTime, 0);
end

-- 设置地图位置
function p.SetAllMapPos(xOffset, yOffset)
	if p.Layer ~= nil then
		

		local sprite = tolua.cast(p.Layer:getChildByTag(10000), "CCSprite");
		local sprite_ex = tolua.cast(p.Layer:getChildByTag(10001), "CCSprite");
		if sprite ~= nil and sprite_ex ~= nil then
			local nWidth = sprite:getContentSize().width;
			sprite:setPosition(ccp(xOffset,yOffset));
			sprite_ex:setPosition(ccp(xOffset+nWidth,yOffset));
		end
		
		--------------------------
		local sprit2 = tolua.cast(p.Layer:getChildByTag(10002), "CCSprite");
		local sprite2_ex = tolua.cast(p.Layer:getChildByTag(10003), "CCSprite");
		if sprit2 ~= nil and sprite2_ex ~= nil then
			local nWidth = sprit2:getContentSize().width;
			sprit2:setPosition(ccp(xOffset,yOffset));
			sprite2_ex:setPosition(ccp(xOffset+nWidth,yOffset));
		end
		--------------------------
		local sprit3 = tolua.cast(p.Layer:getChildByTag(10004), "CCSprite");
		local sprite3_ex = tolua.cast(p.Layer:getChildByTag(10005), "CCSprite");
		if sprit3 ~= nil and sprite3_ex ~= nil then
			local nWidth = sprit3:getContentSize().width;
			sprit3:setPosition(ccp(xOffset,yOffset));
			sprite3_ex:setPosition(ccp(xOffset+nWidth,yOffset));		
		end
		--------------------------
		local sprit44 = tolua.cast(p.Layer:getChildByTag(10009), "CCSprite");
		local sprite44_ex = tolua.cast(p.Layer:getChildByTag(10010), "CCSprite");
		if sprit44 ~= nil and sprite44_ex ~= nil then
			local nWidth = sprit44:getContentSize().width;
			sprit44:setPosition(ccp(xOffset,yOffset));
			sprite44_ex:setPosition(ccp(xOffset+nWidth,yOffset));		
		end
	end
end

--切换地图
function p:ChangeMapImage(nStageId, battleStr, isBoss, fTimeValue, bChangePos)
	if p.Layer ~= nil then

		local nMapId = CfgData["cfg_Stage"][nStageId]["pic"];
		local strName = CfgData["cfg_Stage"][nStageId]["name"];
		p:SetMapName(strName);
		MainBtn.SetMapName(strName);
		
		if m_NowStageId ~= nMapId or isBoss then
			local function func()

				-- 设置战斗场景特效
				GameSceneEffect.StartGameEffect(nMapId);
				
				--切换地图贴片
				local pSprite = tolua.cast(p.Layer:getChildByTag(10000), "CCSprite");
				if pSprite ~= nil then
					local strMap = "map/"..nMapId.."_1.png";
					local texture = CCTextureCache:sharedTextureCache():addImage(strMap);
					pSprite:setTexture(texture);
				end
				local pSprite = tolua.cast(p.Layer:getChildByTag(10001), "CCSprite");
				if pSprite ~= nil then
					local strMap = "map/"..nMapId.."_1.png";
					local texture = CCTextureCache:sharedTextureCache():addImage(strMap);
					pSprite:setTexture(texture);
				end		 
				local pSprite = tolua.cast(p.Layer:getChildByTag(10002), "CCSprite");
				if pSprite ~= nil then
					local strMap = "map/"..nMapId.."_2.png";
					local texture = CCTextureCache:sharedTextureCache():addImage(strMap);
					pSprite:setTexture(texture);
				end
				local pSprite = tolua.cast(p.Layer:getChildByTag(10003), "CCSprite");
				if pSprite ~= nil then
					local strMap = "map/"..nMapId.."_2.png";
					local texture = CCTextureCache:sharedTextureCache():addImage(strMap);
					pSprite:setTexture(texture);
				end
				
				local pSprite = tolua.cast(p.Layer:getChildByTag(10004), "CCSprite");
				if pSprite ~= nil then
					local strMap = "map/"..nMapId.."_3.png";
					local texture = CCTextureCache:sharedTextureCache():addImage(strMap);
					pSprite:setTexture(texture);
				end
				local pSprite = tolua.cast(p.Layer:getChildByTag(10005), "CCSprite");
				if pSprite ~= nil then
					local strMap = "map/"..nMapId.."_3.png";
					local texture = CCTextureCache:sharedTextureCache():addImage(strMap);
					pSprite:setTexture(texture);
				end
				
				local pSprite = tolua.cast(p.Layer:getChildByTag(10009), "CCSprite");
				if pSprite ~= nil then
					local strMap = "map/"..nMapId.."_4.png";
					local texture = CCTextureCache:sharedTextureCache():addImage(strMap);
					pSprite:setTexture(texture);
				end
				local pSprite = tolua.cast(p.Layer:getChildByTag(10010), "CCSprite");
				if pSprite ~= nil then
					local strMap = "map/"..nMapId.."_4.png";
					local texture = CCTextureCache:sharedTextureCache():addImage(strMap);
					pSprite:setTexture(texture);
				end
				
				-- 战斗数据解析
				p:ParsingBattle(battleStr, nStageId, fTimeValue);
				
				m_NowStageId = nMapId;
								
			end
			if m_NowStageId ~= -1 or isBoss then
				p:ShowBlackLayer(func);
			else
				func();
			end
		else
			p:ParsingBattle(battleStr, nStageId, fTimeValue);
		end
	end
end

--设置地图名字
function p:SetMapName(strName)
	local pLable = tolua.cast(p.ui["Label_top"], "LabelBMFont");
	if pLable ~= nil then
		pLable:setText(tostring(strName));
	end
end

--启动战斗表现
function p:BeginFightTimer()
	--关闭定时器
	if handTime ~= nil then
		Scheduler.unscheduleGlobal(handTime);
		handTime = nil;
	end
	
	m_nRoundTime = 0;
	
	local nIndex = 0;
	local function func()
		nIndex = nIndex + 1;
		if nIndex >= 18 or SkillResourcesLoad:IsSkillArmatureLoadFinish(m_SkillTimeMask) then
			if p.schedulerFight() then
				nIndex = 0;
			else
				nIndex = 18;
			end
		end
	end
	handTime = Scheduler.scheduleGlobal(func, 0.1);
end

-- 战斗数据池
function p:schedulerFight()
	
	
	if #m_RoundDate==0 then
		-- 回合结束后buff计算
		-- SpriteSkillBufferPool:DoNextRound();
		if #m_BattleDate > 0 and m_nRoundTime <29 then
			m_nRoundTime = m_nRoundTime + 1;
			m_RoundDate = m_BattleDate[1];
			table.remove(m_BattleDate,1);
		else
			m_nRoundTime = 0;
			Scheduler.unscheduleGlobal(handTime);
			handTime = nil;
			--执行战斗结束
			SpriteDamagePool:RemoveNumActionList();
			SpriteSkillBufferPool:RemoveAllBuffer();

			-- 清除没用的缓存
			CCPlistCache:sharedPlistCache():removeUnusedPlists();
			CCTextureCache:sharedTextureCache():removeUnusedTextures();
			SkillResourcesLoad:ClearLoadArmature();
			
			--重新请求战斗数据
			-- p:BattleRequest();
			GameFightContract.BattleMainRequest(false);
			-- cclog("----战斗结束----");
		end
	end
	
	if #m_RoundDate > 0 then
		local tMessage 		= m_RoundDate[1];
		local nSkillID		= tMessage[1][1]["nSkillId"];
		local nAttackType	= tMessage[1][1]["nAttackType"];
		if m_SkillTimeMask == nil then
			m_SkillTimeMask = tostring(os.time());
		end
		
		--[[
		elseif tMessage.nAttackType == 1 then
			bSkillType = 1;		--CRITICAL = 1, 暴击
		elseif tMessage.nAttackType == 2 then
			bSkillType = 3;		-- DODGE = 2,   闪避
		elseif tMessage.nAttackType == 3 then	
			bSkillType = 2;		-- PARRY = 3,   格挡
		elseif tMessage.nAttackType == 11 then	
			bSkillType = 1;	-- 眩晕
		--]]
		
		if SkillResourcesLoad:SyncLoadSkillArmature(nSkillID, m_SkillTimeMask) then
			p:assemblyFight(tMessage);
			table.remove(m_RoundDate,1);
			m_SkillTimeMask = nil;
			return true;
		end
	end
	return false;
end

--解析战斗使其表现出来
function p:assemblyFight(tMessage)
	--状态部分
	local stateArray = nil;
	if tMessage[2] ~= nil then
		stateArray = {};
		for i,v in ipairs(tMessage[2]) do
			local tb = SpriteStateCenter:StateAssembly(v);
			table.insert(stateArray, tb);
		end
	end
	--文字战报
	GameFightTextBattle.ParsFightRoundText(tMessage);
	--行动部分
	SkillReleaseCenter:SkillRoundComb(tMessage[1], stateArray);
end

-- 敌人出现
function p:ShowEnemy(winSize, yOffset, callBack)
	
	local xOffset = 300;
	p:InitBattleSpite(m_BattleSprite[2], true, xOffset, yOffset);

	--添加到动作池
	local actionArray = {};
	--表示执行动作的精灵
	for i,v in ipairs(m_BattleSprite[2]) do
		if i==1 then
			table.insert(actionArray, v.nId);
		else
			table.insert(actionArray,{nil, nil, ActionEnum.DELAY_ACTION, 0.1});
		end
		table.insert(actionArray,{v.nId, nil, ActionEnum.JUMP_ACTION, {0.2,ccp(-xOffset, 0), 50, 1}});
	end
	SpriteActionPool:PushInActionFromQueue(actionArray);
	-----------------------------------------------
	Scheduler.performWithDelayGlobal(callBack, 0.4);
end

-- 开始战斗
function p:StartGameFight()
	if m_DataActionTime ~= nil then
		Scheduler.unscheduleGlobal(m_DataActionTime);
		m_DataActionTime = nil;
	end
	m_DataActionTime = Scheduler.scheduleGlobal(p.schedulerFunc, 0.1);
end

-- 队列轮询定时器
function p:schedulerFunc()	
	
	-- 1:动作池
	local tAction = SpriteActionPool:PushOutActionFromQueue();
	if tAction ~= nil then
		SpriteActionPool:RunActionParsing(tAction)
	end
	
	-- 2:场景粒子特效池(技能显示)
	local tEffect = SceneSkillEffectPool:PushOutEffectFromQueue();
	if tEffect ~= nil then
		SceneSkillEffectPool:ShowEffect(tEffect)
	end
	
	-- 3:英雄伤害显示
	local tDamage = SpriteDamagePool:PushOutActionFromQueue()
	if tDamage ~= nil then
		SpriteDamagePool:ShowDamageHurt(tDamage);
	end
	
	-- 4:英雄buff状态显示
	local tBuffer = SpriteSkillBufferPool:PushOutBufferFromQueue();
	if tBuffer ~= nil then
		SpriteSkillBufferPool:BufferParsing(tBuffer);
	end
	
	-- 5:由于英雄的技能产生的位移
	local tPerform = SkillActionPerform:PushOutActionFromQueue()
	if tPerform ~= nil then
		SkillActionPerform:RunPerformAction(tPerform)
	end
	
	-- 6:技能释放前的蓄力表现
	local tStorageEffect = SkillDoReleaseBefore:PushOutStorageFromQueue()
	if tStorageEffect ~= nil then
		SkillDoReleaseBefore:ShowStorageEffect(tStorageEffect);
	end
end

--获取战斗的场景
function p:GetActiveLayer()
	return p.Layer;
end

-- 场景抖动
function p:LayerMoveAction()
	local array = CCArray:create();
	local pMove = CCMoveBy:create(0.02, ccp(0,-20));
	array:addObject(pMove);
	array:addObject(pMove:reverse());
	local pMove = CCMoveBy:create(0.03, ccp(10,10));
	array:addObject(pMove);
	array:addObject(pMove:reverse());
	local pMove = CCMoveBy:create(0.05, ccp(-8, 8));
	array:addObject(pMove);
	array:addObject(pMove:reverse());
	
	local pAction = CCSequence:create(array);	
	p.Layer:runAction(pAction);
end

-- 场景变灰度
function p:ShowGrayLayer()
	if p.GrayLayer == nil then
		p.GrayLayer = CCLayerColor:create(ccc4(0, 0, 0, 125), 640, 960);
		p.Layer:addChild(p.GrayLayer,10);
	end
	--
	for index=10004,10005 do
		local pSprite = tolua.cast(p.Layer:getChildByTag(index), "CCSprite");
		if pSprite ~= nil then
			local array = CCArray:create();
			array:addObject(CCTintTo:create(0.4, 41,36,33));
			array:addObject(CCDelayTime:create(0.6));
			array:addObject(CCTintTo:create(0.4, 255, 255, 255));
			local pAction = CCSequence:create(array);	
			pSprite:runAction(pAction);
		end
	end
	--]]	
	local array = CCArray:create();
	array:addObject(CCShow:create());
	array:addObject(CCFadeTo:create(0.4, 200));
	array:addObject(CCDelayTime:create(0.6));
	array:addObject(CCFadeTo:create(0.4, 0));
	array:addObject(CCHide:create());
	local pAction = CCSequence:create(array);	
	p.GrayLayer:runAction(pAction);	
end

-- 场景变黑
function p:ShowBlackLayer(func)
	local spriteTb = SpriteArmaturePool:GetSpriteArmature();
	for k,v in pairs(spriteTb) do
		if v.IsEnemy then
			v.Sprite:setVisible(false);
		else
			m_bStop = true;
			GameFightMusic.PlayWalkOnMap(false);
			GameFightMusic.PlayRunOnMap(true);
			
			local array = CCArray:create();
			-- array:addObject(CCShow:create());
			-- array:addObject(CCFadeIn:create(0.1));--1.5
			array:addObject(CCMoveBy:create(1.5, ccp(800,0)));
			local pAction = CCSequence:create(array);
			v.Sprite:runAction(pAction);
			v:PlayAnimationByName("run",nil,nil,1);
		end
	end
	
	
	local function showFunc()
		if p.BlackLayer == nil then
			p.BlackLayer = CCLayerColor:create(ccc4(0, 0, 0, 255), 640, 960);
			p.Layer:addChild(p.BlackLayer,1001);
		end
		local array = CCArray:create();
		array:addObject(CCShow:create());
		array:addObject(CCFadeIn:create(0.5));
		array:addObject(CCDelayTime:create(0.6));
		--角色进场
		--角色进场完毕后更换地图
		array:addObject(CCCallFunc:create(func));
		array:addObject(CCFadeOut:create(0.5));
		array:addObject(CCHide:create());
		local pAction = CCSequence:create(array);	
		p.BlackLayer:runAction(pAction);
	end
	Scheduler.performWithDelayGlobal(showFunc, 1.5);
end

--初始化精灵
function p:InitBattleSpite(tSpite, bIsEnemy, xOffset, yOffset)
	local nSprite = #tSpite;
	for nIndex=1,nSprite do
		local pos = nil;
		if not bIsEnemy then
			pos = p:GetAttackPostion(nIndex , nSprite, bIsEnemy, xOffset, yOffset);
		else
			pos = p:GetBeAttackPostion(nIndex , nSprite, bIsEnemy, xOffset, yOffset);
		end
		
		
		local weapIng = nil;
		local bIsBoss = false;
		local spriteName = nil;
		local spriteWearing = nil;
		local nSkillStoneId = tSpite[nIndex].nSkillStoneId;
		local nSkillStoneLv = tSpite[nIndex].nSkillStoneLev;
		
		if tSpite[nIndex].nRace < 35000 then
			--角色
			spriteName = CfgData["cfg_race"][tSpite[nIndex].nRace]["armture"];
			spriteWearing = CfgData["cfg_profession"][tSpite[nIndex].nRole]["wear"];
			weapIng = tSpite[nIndex].nWeap;
		else
			--怪物
			spriteName = CfgData["cgf_monster"][tSpite[nIndex].nRace]["armture"];
			spriteWearing = CfgData["cgf_monster"][tSpite[nIndex].nRace]["wear"];
			weapIng = CfgData["cgf_monster"][tSpite[nIndex].nRace]["weap"];
			if  tSpite[nIndex].nRace > 36000 then
				bIsBoss = true;
			end
		end
		SpriteArmaturePool:CreateArmature(tSpite[nIndex].nId, spriteName, weapIng, spriteWearing, tSpite[nIndex].IsEnemy, "move", pos, tSpite[nIndex].nMaxHp, bIsBoss, nSkillStoneId, nSkillStoneLv);
	end
end

--站位初始化函数
--***********************************************************************
--攻击方
function p:GetAttackPostion(nIndex , nMaxCount, bIsEnemy, xOffset, yOffset)
	local winSize = CCDirector:sharedDirector():getWinSize();
	if nMaxCount == 1 then
		return ccp(winSize.width*4/18+xOffset, winSize.height*2/16+yOffset)
	elseif nMaxCount == 2 then
		if nIndex==1 then
			return ccp(winSize.width*4/18+xOffset, winSize.height*3/16+yOffset)
		elseif nIndex==2 then
			return ccp(winSize.width*3/18+xOffset, winSize.height*1/16+yOffset)
		end
	elseif nMaxCount == 3 then
		if nIndex==1 then
			return ccp(winSize.width*5/36+xOffset, winSize.height*7/32+yOffset)
		elseif nIndex==2 then
			return ccp(winSize.width*10/36+xOffset, winSize.height*4/32+yOffset)
		elseif nIndex==3 then
			return ccp(winSize.width*6/36+xOffset, winSize.height*1/32+yOffset)
		end
	elseif nMaxCount == 4 then
		if nIndex==1 then
			return ccp(winSize.width*6/36+xOffset, winSize.height*8/32+yOffset)
		elseif nIndex==2 then
			return ccp(winSize.width*11/36+xOffset, winSize.height*6/32+yOffset)
		elseif nIndex==3 then
			return ccp(winSize.width*5/36+xOffset, winSize.height*3/32+yOffset)
		elseif nIndex==4 then
			return ccp(winSize.width*9/36+xOffset, winSize.height*1/64+yOffset)
		end
	end
	return ccp(winSize.width*4/18+xOffset, winSize.height*3/16+yOffset)
end

--被击方
function p:GetBeAttackPostion(nIndex , nMaxCount, bIsEnemy, xOffset, yOffset)
	local winSize = CCDirector:sharedDirector():getWinSize();
	if nMaxCount == 1 then
		return ccp(winSize.width*14/18+xOffset, winSize.height*2/16+yOffset)
	elseif nMaxCount == 2 then
		if nIndex==1 then
			return ccp(winSize.width*14/18+xOffset, winSize.height*3/16+yOffset)
		elseif nIndex==2 then
			return ccp(winSize.width*15/18+xOffset, winSize.height*1/16+yOffset)
		end
	elseif nMaxCount == 3 then
		if nIndex==1 then
			return ccp(winSize.width*31/36+xOffset, winSize.height*7/32+yOffset)
		elseif nIndex==2 then
			return ccp(winSize.width*26/36+xOffset, winSize.height*4/32+yOffset)
		elseif nIndex==3 then
			return ccp(winSize.width*30/36+xOffset, winSize.height*1/32+yOffset)
		end
	elseif nMaxCount == 4 then
		if nIndex==1 then
			return ccp(winSize.width*31/36+xOffset, winSize.height*8/32+yOffset)
		elseif nIndex==2 then
			return ccp(winSize.width*25/36+xOffset, winSize.height*6/32+yOffset)
		elseif nIndex==3 then
			return ccp(winSize.width*31/36+xOffset, winSize.height*3/32+yOffset)
		elseif nIndex==4 then
			return ccp(winSize.width*25/36+xOffset, winSize.height*1/32+yOffset)
		end
	end
	return ccp(winSize.width*14/18+xOffset, winSize.height*2/16+yOffset);
end

--竞技场结果显示
function p.ShowAreanResult(bWin,rank)
	local spriteExportJson = nil;
	local armaName = nil;
	
	if bWin == true then
		--spriteExportJson = "armature/txslbx/txslbx.ExportJson"
		spriteExportJson = "armature/Effectvictory/Effectvictory.ExportJson"
		armaName = "Effectvictory"
	elseif bWin == false then
		spriteExportJson = "armature/Effectfailed/Effectfailed.ExportJson"
		armaName = "Effectfailed"
	else
		return;
	end
	
	
	CCArmatureDataManager:sharedArmatureDataManager():addArmatureFileInfo(spriteExportJson);
	-- 创建骨骼动画
	local Sprite = CCArmature:create(armaName);
	Sprite:setAnchorPoint(ccp(0,0))
	Sprite:getAnimation():playWithIndex(0);
	--Sprite:getAnimation():play("close");
	if bWin == true then
		--Sprite:setPosition(ccp(20,600));
		Sprite:setPosition(ccp(0,750));
	elseif bWin == false then
		--Sprite:setPosition(ccp(280,600));
		Sprite:setPosition(ccp(320,750));
	end
	
	--Sprite:setScale(0.5);
	local function pCall(obj)
		obj:getAnimation():pause();
		obj:removeFromParentAndCleanup(true);
		--[[
		local failStr = {"一定是姿势不对！","去洗练词条试试。","去更换技能组再来!"}
		local strText = nil;
		local nPos = nil;
		if bWin == true then
			if rank ~= nil then
				strText = string.format("竞技场排名上升到：%d",rank);
			else
				strText = string.format("恭喜在竞技场中胜利");
			end
			nPos = ccp(320,550)
		elseif bWin == false then
			local n = math.random(1,3)
			strText = failStr[n];
			nPos = ccp(320,580)
		end
		local label = CCLabelTTF:create(strText,"Helvetica",30);
		
		label:setPosition(nPos)
		--label:setContentSize(CCSizeMake(50,50))
		p.Layer:addChild(label,151,112);
		local function listener()
			obj:removeFromParentAndCleanup(true);
			local txtObj = p.Layer:getChildByTag(112)
			if txtObj ~= nil then
				txtObj:removeFromParentAndCleanup(true);
			end
		end
		Scheduler.performWithDelayGlobal(listener, 2)
	--]]
	end
	Sprite:getAnimation():setMovementEventCallFunc(pCall)
	
	p.Layer:addChild(Sprite,350,110);
end

function p.RefushBattleUI()
	local pLable = tolua.cast(p.ui["Label_fightnum"], "Label");
	if pLable ~= nil then
		if UserData.ChallengeTime > 0 then
			pLable:setText(tostring(UserData.ChallengeTime).."次");
		else
			--
			--显示券的数量
			local item = UserData.GetItemInfo(202);
			if CheckT(item) then
				if item.MutilNum > 0 then
					local str = string.format(ZhTextSet_30333,item.MutilNum)
					pLable:setText(str);
				else
					pLable:setText("0");
				end
			else
				pLable:setText("0");
			end
		end
	end
end

return p;