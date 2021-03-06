--第一次战斗
GameFightInfoBase = {};
local p = GameFightInfoBase;
 
local str1 = "1_"..ZhTextSet_40008.."_80_1206_1111_80074_0_10100_1301_8&"
local str2 = "2_"..ZhTextSet_40009.."_99_1201_1115_80041_0_15000_1306_15&"
local str3 = "3_"..ZhTextSet_40010.."_80_1206_1120_80042_0_10900_1322_19|"
local str4 = "100_"..ZhTextSet_40011.."_80_35901_0_0_0_9000_0_0&"
local str5 = "101_"..ZhTextSet_40012.."_99_36901_1116_80021_0_80000_0_0&"
local str6 = "102_"..ZhTextSet_40021.."_80_35902_0_0_0_9000_0_0"

--第一次战斗战报
local tBattleLogTb = {
	str1,
	str2,
	str3,
	str4,
	str5,
	str6,
"#",
	-- "/101_40000_2_25_0_",
	"/101_30000_2_25_0_",
	"/2_30001_101_25_0_",
	"/3_10910_100_0_2400_&",
	"/100_10880_1_8_0_20126&100_10880_2_8_0_20126&100_10880_3_8_0_20126&|",
	"/1_10360_102_1_2000_&102_20076_1_7_500&1_10360_100_1_1300&1_10360_101_1_1300&|100_20126_1_0_200&",
	"/101_11010_1_0_3000_20141&|",
	"/2_10620_2_8_0_20102,20103&|100_20126_2_0_200&",
	"/102_10155_1_8_0_20147&102_10155_2_8_0_20147&102_10155_3_8_0_20147&|",
"#",
	"/3_10950_102_1_2100_&102_20076_3_7_2000|100_20126_3_0_200&",
	"/100_10860_3_1_3000_&|",
	"/1_10380_102_0_2000_&101_20141_1_12_0_&1_10380_1_8_0_20057&102_20076_1_7_500_&|100_20126_1_0_200&",
	"/101_10710_1_8_0_20146&101_10710_2_8_0_20146&101_10710_3_8_0_20146&|101_10710_101_10_0_5600&|",
	"/2_30003_101_25_0_",
	"/1_30004_101_25_0_",
	"/2_10640_102_1_3200_&102_20076_1_7_500&2_10640_100_1_2400_&2_10640_102_1_2400_&|101_20146_2_0_5600&100_20126_2_0_200&",
"#",
	"/3_10950_100_1_4800_&|100_20126_3_0_200&101_20146_3_0_5600&",
	"/1_10410_101_1_10000_&1_10410_1_8_0_20058&|100_20126_1_0_200&101_20146_1_0_5600&",
	"/101_30005_2_25_0_",
	"/2_30006_101_25_0_",
	"/2_30007_101_25_0_",
	"/2_40001_101_25_0_",	
}

local tShowHeroTb = {
	InAWorld_30000 = ZhTextSet_40013,
	InAWorld_30001 = ZhTextSet_40014,
	InAWorld_30002 = ZhTextSet_40015,
	InAWorld_30003 = ZhTextSet_40016,
	InAWorld_30004 = ZhTextSet_40017,
	InAWorld_30005 = ZhTextSet_40018,
	InAWorld_30006 = ZhTextSet_40019,
	InAWorld_30007 = ZhTextSet_40020,
	InAWorld_31008 = nil, 
}


--获取巅峰战报内容
function p.FirstBattleLog()
	local str = "";
	for i,v in ipairs(tBattleLogTb) do
		str = str..v;
	end
	return str;
end

--40000(打开对话界面)
--40001(关闭对话界面)
--根据战斗对话ID获取说话内容
function p:ShowHeroTalkInfoById(nWorldIndex)
	if nWorldIndex == 30000 then
		--开启战斗对话界面
		OpenLayer(UI_TAG.UI_LOGINFIGHT,0,112);
		local sKey = "InAWorld_"..tostring(nWorldIndex);
		return tShowHeroTb[sKey];
	elseif nWorldIndex == 40001 then
		--关闭战斗对话界面
		CloseLayer(UI_TAG.UI_LOGINFIGHT);
		MainBtn.ShowTabPage(1);
	else
		--返回战斗文字
		local sKey = "InAWorld_"..tostring(nWorldIndex);
		return tShowHeroTb[sKey];
	end
	return nil;
end