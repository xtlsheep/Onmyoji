require "util"
require "func"

-- Config
mark_delay_juexing = 500

-- Util func
function lct_juexingtower()
	local x, y = findColor({109, 139, 1098, 141},
		"0|0|0xe8d4cf,-776|159|0xfb6c4f,-551|167|0x4ccd89,-334|156|0x5aa9f0,-88|166|0x8356c6",
		90, 0, 0, 0)
	if x > -1 then
		HUD_show_or_hide(HUD,hud_info,"探索 - 觉醒之塔",20,"0xff000000","0xffffffff",0,100,0,300,32)
	end
	return x, y
end

function lct_juexingelement()
	local x, y = findColor({929, 108, 931, 110},
		"0|0|0xe8d4cf,-210|320|0xe97c2c,-84|332|0xf3b25e,-380|-7|0xf8f3e0",
		90, 0, 0, 0)
	if x > -1 then
		HUD_show_or_hide(HUD,hud_info,"探索 - 觉醒材料",20,"0xff000000","0xffffffff",0,100,0,300,32)
	end
	return x, y
end

function juexing_mark(mark)
	mSleep(700)
	mSleep(mark_delay_juexing)
	random_sleep(50)
	
	local cnt = math.random(2, 3)
	local pos_x = {488, 560, 653, 823, 1016}
	local pos_y = {140, 170, 210, 230, 240}
	local pos
	if (mark == "小怪") then
		pos = math.random(1, 5)
	end
	
	for i = 1, cnt do
		random_sleep(150)
		if (mark == "大怪") then
			random_touch(0, 722, 148, 10, 30)
		elseif (mark == "小怪") then
			random_touch(0, pos_x[pos], pos_y[pos], 10, 10)
		end
	end
	mSleep(1000)
end

function juexing_element(element)
	if (element == "火") then
		random_touch(0, 225, 300, 20, 20)
	elseif (element == "风") then
		random_touch(0, 465, 300, 20, 20)
	elseif (element == "水") then
		random_touch(0, 700, 300, 20, 20)
	elseif (element == "雷") then
		random_touch(0, 950, 300, 20, 20)
	end
	random_sleep(1000)
end

-- Main func
function juexing(mode, role, group, element, mark, level, round, lock, member_auto_group, fail_and_group, member_to_captain, captain_auto_group, captain_auto_invite, auto_invite_zone, fail_and_recreate)
	print(string.format("觉醒材料 - 模式：%s，角色：%s，组队：%s，标记延迟 %d，类型：%s，标记：%s ，层数：%d，战斗次数：%d, 锁定出战：%d",
			mode, role, group, mark_delay_juexing, element, mark, level, round, lock))
	print(string.format("队员自动组队：%d，失败重新组队：%d，队员接手队长：%d，队长自动组队：%d，队长自动邀请：%d, 自动邀请区域 %s, 失败重新建队：%d",
			member_auto_group, fail_and_group, member_to_captain, captain_auto_group, captain_auto_invite, auto_invite_zone, fail_and_recreate))
	print_global_config()
	
	local ret = 0
	
	if sg_en == 1 then
		member_auto_group = 0
		captain_auto_group = 0
	end
	
	if buff_start == 1 then
		buff_start_en = 1
		buff_sel = {1, 0, 0, 0}
	end
	
	turbo_settle = 0
	
	while (1) do
		if (mode == "单人") then
			ret = juexing_solo(element, mark, level, round, lock)
		elseif (mode == "组队" and role == "队员" and group == "野队") then
			ret = juexing_group_wild_member(element, mark, level, round, lock, member_auto_group, fail_and_group, member_to_captain)
		elseif (mode == "组队" and role == "队长" and (group == "野队2人" or group == "野队3人")) then
			ret = juexing_group_wild_captain(element, mark, level, round, lock, captain_auto_group, fail_and_recreate, group)
		elseif (mode == "组队" and role == "队员" and group == "固定队") then
			ret = juexing_group_fix_member(element, mark, level, round, member_auto_group, member_to_captain)
		elseif (mode == "组队" and role == "队长" and (group == "固定队2人" or group == "固定队3人")) then
			ret = juexing_group_fix_captain(element, mark, level, round, lock, captain_auto_group, captain_auto_invite, auto_invite_zone, group)
		end
		
		if ret ~= RET_RECONN then
			return ret
		end
	end
	return RET_ERR
end

function juexing_solo(element, mark, level, round, lock)
	local tingyuan_time_cnt = 0
	local quit_end = 0
	local quit_con = 0
	local init = 1
	local ret = 0
	local x, y
	
	while (1) do
		while (1) do
			-- 战
			x, y = round_fight() if (x > -1) then print("!!!")juexing_mark(mark) break end
			mSleep(500)
			-- 循环通用
			ret = loop_generic() if ret == RET_RECONN then return RET_RECONN end
			-- 拒绝组队
			x, y = member_team_refuse_invite() if (x > -1) then break end
			-- 战斗准备
			x, y = fight_ready() if (x > -1) then break end
			-- 战斗进行
			x, y = fight_ongoing() if x > -1 then break end
			-- 战斗胜利
			x, y, ret = fight_settle("觉醒")
			if (x > -1) then
				tingyuan_time_cnt = 0
				if ret == "Success" then
					win_cnt.global = win_cnt.global + 1
					show_win_fail(win_cnt.global, fail_cnt.global)
					win_cnt.juexing = win_cnt.juexing + 1
					if win_cnt.juexing >= round then
						quit_end = 1
					end
				elseif ret == "Failed" then
					x, y = fight_failed()
					fail_cnt.global = fail_cnt.global + 1
					show_win_fail(win_cnt.global, fail_cnt.global)
					fail_cnt.juexing = fail_cnt.juexing + 1
				end
				break
			end
			-- 超鬼王
			SuperGhost()
			-- 觉醒材料
			x, y = lct_juexingelement()
			if (x > -1) then
				-- 智能突破Check
				quit_con = auto_jjtp_time_check()
				if quit_end == 1 then
					random_touch(0, 930, 110, 5, 5)
					break
				end
				-- 退出后继续
				if quit_con == 1 then
					random_touch(0, 930, 110, 5, 5)
					break
				end
				level_select(level, init, lock, "觉醒")
				init = 0
				solo_start()
				break
			end
			-- 庭院
			x, y = lct_tingyuan() if (x > -1) then tingyuan_enter_tansuo() tingyuan_time_cnt = idle_at_tingyuan(tingyuan_time_cnt) break end
			-- 探索
			x, y = lct_tansuo()
			if (x > -1) then
				if quit_end == 1 then
					stop_buff()
					lua_exit()
				end
				if quit_con == 1 then
					stop_buff()
					return RET_VALID
				end
				if buff_start_en == 1 then
					start_buff()
					buff_start_en = 0
				end
				random_touch(0, 90, 590, 20, 20)
				mSleep(1000)
				break
			end
			-- 觉醒之塔
			x, y = lct_juexingtower() if (x > -1) then juexing_element(element) break end
			-- 真八岐大蛇
			x, y = real_baqidashe() if x > -1 then break end
			-- 神秘商人
			x, y = mysterious_vender() if x > -1 then break end
			-- 喂食纸人
			x, y = feed_paperman() if x > -1 then break end
			-- 体力不足
			x, y = out_of_sushi() if x > -1 then break end
			break
		end
	end
	return RET_ERR
end

function juexing_group_wild_member(element, mark, level, round, lock, member_auto_group, fail_and_group, member_to_captain)
	local time_cnt = 0
	local wait_invite = 0
	local auto_grouped = 0
	local tingyuan_time_cnt = 0
	local tansuo_time_cnt = 0
	local quit_end = 0
	local quit_con = 0
	local quit_grp = 0
	local ret = 0
	local ret_ = 0
	local init = 1
	local x, y, x_, y_
	
	while (1) do
		while (1) do
			-- 战
			x, y = round_fight() if (x > -1) then juexing_mark(mark) break end
			mSleep(500)
			-- 循环通用
			ret = loop_generic() if ret == RET_RECONN then return RET_RECONN end
			-- 拒绝邀请
			if (wait_invite == 0) then x, y = member_team_refuse_invite() if (x > -1) then mSleep(1000) break end end
			-- 超鬼王
			ret = SuperGhost() if ret == RET_OK then wait_invite = 0 end
			-- 探索
			x, y = lct_tansuo()
			if (x > -1) then
				if quit_end == 1 then
					stop_buff()
					lua_exit()
				end
				if quit_con == 1 then
					stop_buff()
					return RET_VALID
				end
				if buff_start_en == 1 then
					start_buff()
					buff_start_en = 0
				end
				if wait_invite == 0 then
					random_touch(0, 90, 590, 20, 20) -- 觉醒
					mSleep(1000)
				else
					HUD_show_or_hide(HUD,hud_info,"探索 - 等待组队邀请",20,"0xff000000","0xffffffff",0,100,0,300,32)
					x, y, auto_grouped = member_team_accept_invite(member_auto_group)
					if x > -1 then
						wait_invite = 0
						time_cnt = 0
					else
						time_cnt = time_cnt + 1
						if time_cnt > math.random(18, 22) then
							wait_invite = 0
							time_cnt = 0
						end
					end
				end
				tansuo_time_cnt = idle_at_tansuo(tansuo_time_cnt)
				break
			end
			-- 战斗准备
			x, y = fight_ready() if (x > -1) then break end
			-- 战斗进行
			x, y = fight_ongoing()
			if x > -1 then
				if quit_grp == 1 then
					x_, y_ = fight_stop_auto_group()
					if x_ > -1 then
						quit_grp = 0
					end
				end
				break
			end
			-- 战斗胜利
			x, y, ret_ = fight_settle("觉醒")
			if (x > -1) then
				tansuo_time_cnt = 0
				tingyuan_time_cnt = 0
				if ret_ == "Success" then
					wait_invite = 1
					win_cnt.global = win_cnt.global + 1
					show_win_fail(win_cnt.global, fail_cnt.global)
					win_cnt.juexing = win_cnt.juexing + 1
					if win_cnt.juexing == round then
						quit_grp = 1
						wait_invite = 0
					end
					if win_cnt.juexing > round then
						quit_end = 1
					end
					-- 智能突破Check
					ret = auto_jjtp_time_check()
					if ret == RET_VALID then
						quit_grp = 1
						quit_con = 1
						wait_invite = 0
					end
				elseif ret_ == "Failed" then
					fail_cnt.global = fail_cnt.global + 1
					show_win_fail(win_cnt.global, fail_cnt.global)
					fail_cnt.juexing = fail_cnt.juexing + 1
					if (fail_and_group == 1) then
						wait_invite = 0
					else
						wait_invite = 1
					end
				end
				break
			end
			-- 组队寻找
			x, y = member_room_init() if (x > -1) then member_room_find() break end
			-- 队员接手队长
			if (member_to_captain == 1) then
				x, y = member_room_find_start() if (x > -1) then random_touch(0, 925, 535, 20, 10) break end -- 开始战斗
			else
				x, y = member_room_find_start() if (x > -1) then random_touch(0, 205, 535, 20, 10) break end -- 离开队伍
			end
			-- 离开确认
			x, y = member_room_quit() if (x > -1) then wait_invite = 0 break end
			-- 觉醒材料
			x, y = lct_juexingelement() if (x > -1) then level_select(level, init, lock, "觉醒") init = 0 group_start() break end -- 组队开始
			-- 庭院
			x, y = lct_tingyuan() if (x > -1) then tingyuan_enter_tansuo() tingyuan_time_cnt = idle_at_tingyuan(tingyuan_time_cnt) break end
			-- 觉醒之塔
			x, y = lct_juexingtower() if (x > -1) then juexing_element(element) break end
			-- 停止邀请
			x, y = captain_team_win_invite() if (x > -1) then random_touch(0, 460, 385, 20, 10) break end
			x, y = captain_team_lost_invite() if (x > -1) then random_touch(0, 462, 383, 20, 10) break end
			-- 退出个人资料
			x, y = member_user_profile() if x > -1 then break end
			-- 真八岐大蛇
			x, y = real_baqidashe() if x > -1 then break end
			-- 神秘商人
			x, y = mysterious_vender() if x > -1 then break end
			-- 喂食纸人
			x, y = feed_paperman() if x > -1 then break end
			-- 体力不足
			x, y = out_of_sushi() if x > -1 then break end
			break
		end
	end
	return RET_ERR
end

function juexing_group_wild_captain(element, mark, level, round, lock, captain_auto_group, fail_and_recreate, group)
	local tingyuan_time_cnt = 0
	local tansuo_time_cnt = 0
	local quit_end = 0
	local quit_con = 0
	local quit_grp = 0
	local ret = 0
	local ret_ = 0
	local init = 1
	local x, y
	
	while (1) do
		while (1) do
			-- 战
			x, y = round_fight() if (x > -1) then juexing_mark(mark) break end
			-- 开始战斗
			if group == "野队2人" then
				x, y = captain_room_start_with_1_members() if (x > -1) then break end
			end
			if group == "野队3人" then
				x, y = captain_room_start_with_2_members() if (x > -1) then break end
			end
			mSleep(500)
			-- 循环通用
			ret = loop_generic() if ret == RET_RECONN then return RET_RECONN end
			-- 拒绝邀请
			x, y = member_team_refuse_invite() if (x > -1) then break end
			-- 战斗进行
			x, y = fight_ongoing()
			if x > -1 then
				if quit_grp == 1 then
					x_, y_ = fight_stop_auto_group()
					if x_ > -1 then
						quit_grp = 0
					end
				end
				break
			end
			-- 战斗准备
			x, y = fight_ready() if (x > -1) then break end
			-- 战斗胜利
			x, y, ret_ = fight_settle("觉醒")
			if (x > -1) then
				tansuo_time_cnt = 0
				tingyuan_time_cnt = 0
				if ret_ == "Success" then
					win_cnt.global = win_cnt.global + 1
					show_win_fail(win_cnt.global, fail_cnt.global)
					win_cnt.juexing = win_cnt.juexing + 1
					if win_cnt.juexing == round then
						quit_grp = 1
					end
					if win_cnt.juexing > round then
						quit_end = 1
					end
					-- 智能突破Check
					ret = auto_jjtp_time_check()
					if ret == RET_VALID then
						quit_grp = 1
						quit_con = 1
					end
				elseif ret_ == "Failed" then
					fail_cnt.global = fail_cnt.global + 1
					show_win_fail(win_cnt.global, fail_cnt.global)
					fail_cnt.juexing = fail_cnt.juexing + 1
					break
				end
			end
			-- 失败邀请
			x, y = captain_team_lost_invite()
			if (x > -1) then
				if (fail_and_recreate == 1) then
					random_touch(0, 462, 383, 20, 10) -- 取消
				else
					random_touch(0, 673, 384, 20, 10) -- 确定
				end
				break
			end
			-- 自动邀请
			if (captain_auto_group == 1 and quit_end == 0 and quit_con == 0) then
				x, y = captain_team_set_auto_invite() if (x > -1) then break
				end
			end
			-- 胜利邀请
			x, y = captain_team_win_invite()
			if (x > -1) then
				if quit_end == 1 or quit_con == 1 then
					random_touch(0, 460, 385, 20, 10)
				else
					random_touch(0, 674, 385, 20, 10)
				end
				break
			end
			-- 创建初始化
			x, y = captain_room_create_init() if (x > -1) then break end -- 创建队伍
			-- 创建公共队伍
			x, y = captain_room_create_public() if (x > -1) then break end
			-- 庭院
			x, y = lct_tingyuan() if (x > -1) then tingyuan_enter_tansuo() tingyuan_time_cnt = idle_at_tingyuan(tingyuan_time_cnt) break end
			-- 超鬼王
			SuperGhost()
			-- 探索
			x, y = lct_tansuo()
			if (x > -1) then
				if quit_end == 1 then
					stop_buff()
					lua_exit()
				end
				if quit_con == 1 then
					stop_buff()
					return RET_VALID
				end
				if buff_start_en == 1 then
					start_buff()
					buff_start_en = 0
				end
				random_touch(0, 90, 590, 20, 20)
				mSleep(1000)
				tansuo_time_cnt = idle_at_tansuo(tansuo_time_cnt)
				break
			end
			-- 觉醒之塔
			x, y = lct_juexingtower() if (x > -1) then juexing_element(element) break end
			-- 觉醒材料
			x, y = lct_juexingelement() if (x > -1) then level_select(level, init, lock, "觉醒") init = 0 group_start() break end -- 组队开始
			-- 退出个人资料
			x, y = member_user_profile() if x > -1 then break end
			-- 真八岐大蛇
			x, y = real_baqidashe() if x > -1 then break end
			-- 神秘商人
			x, y = mysterious_vender() if x > -1 then break end
			-- 喂食纸人
			x, y = feed_paperman() if x > -1 then break end
			-- 体力不足
			x, y = out_of_sushi() if x > -1 then break end
			break
		end
	end
	return RET_ERR
end

function juexing_group_fix_member(element, mark, level, round, member_auto_group, member_to_captain)
	local auto_grouped = 0
	local quit_end = 0
	local quit_con = 0
	local quit_grp = 0
	local tingyuan_time_cnt = 0
	local tansuo_time_cnt = 0
	local wait_invite = 1
	local ret = 0
	local ret_ = 0
	local x, y
	
	while (1) do
		while (1) do
			-- 战
			x, y = round_fight() if (x > -1) then juexing_mark(mark) break end
			mSleep(500)
			-- 循环通用
			ret = loop_generic() if ret == RET_RECONN then return RET_RECONN end
			-- 邀请
			if wait_invite == 1 then
				-- 接收
				x, y, auto_grouped = member_team_accept_invite(member_auto_group) if (x > -1) then break end
			else
				-- 拒绝
				x, y = member_team_refuse_invite() if (x > -1) then mSleep(1000) break end
			end
			-- 战斗准备
			x, y = fight_ready() if (x > -1) then break end
			-- 战斗进行
			x, y = fight_ongoing()
			if x > -1 then
				if quit_grp == 1 then
					x_, y_ = fight_stop_auto_group()
					if x_ > -1 then
						quit_grp = 0
					end
				end
				break
			end
			-- 战斗胜利
			x, y, ret_ = fight_settle("觉醒")
			if (x > -1) then
				tansuo_time_cnt = 0
				tingyuan_time_cnt = 0
				if ret_ == "Success" then
					win_cnt.global = win_cnt.global + 1
					show_win_fail(win_cnt.global, fail_cnt.global)
					win_cnt.juexing = win_cnt.juexing + 1
					if win_cnt.juexing == round then
						quit_grp = 1
						wait_invite = 0
					end
					if win_cnt.juexing > round then
						quit_end = 1
					end
					-- 智能突破Check
					ret = auto_jjtp_time_check()
					if ret == RET_VALID then
						quit_grp = 1
						quit_con = 1
						wait_invite = 0
					end
				elseif ret_ == "Failed" then
					fail_cnt.global = fail_cnt.global + 1
					show_win_fail(win_cnt.global, fail_cnt.global)
					fail_cnt.juexing = fail_cnt.juexing + 1
				end
				break
			end
			-- 队员接手队长
			if (member_to_captain == 1) then
				x, y = member_room_find_start() if (x > -1) then random_touch(0, 925, 535, 20, 10) break end -- 开始战斗
			else
				x, y = member_room_find_start() if (x > -1) then random_touch(0, 205, 535, 20, 10) break end -- 离开队伍
			end
			-- 离开队伍
			x, y = member_room_find_start() if (x > -1) then random_touch(0, 205, 535, 20, 10) break end -- 离开队伍
			-- 离开确认
			x, y = member_room_quit() if (x > -1) then break end
			-- 超鬼王
			SuperGhost()
			-- 庭院
			x, y = lct_tingyuan()
			if x > -1 then
				if quit_end == 1 then
					stop_buff()
					lua_exit()
				end
				if quit_con == 1 then
					stop_buff()
					return RET_VALID
				end
				if buff_start_en == 1 then
					start_buff()
					buff_start_en = 0
				end
				tingyuan_time_cnt = idle_at_tingyuan(tingyuan_time_cnt)
				break
			end
			-- 探索
			x, y = lct_tansuo()
			if x > -1 then
				if quit_end == 1 then
					stop_buff()
					lua_exit()
				end
				if quit_con == 1 then
					stop_buff()
					return RET_VALID
				end
				if buff_start_en == 1 then
					start_buff()
					buff_start_en = 0
				end
				tansuo_time_cnt = idle_at_tansuo(tansuo_time_cnt)
				break
			end
			x, y = lct_tansuo() if x > -1 then tansuo_time_cnt = idle_at_tansuo(tansuo_time_cnt) break end
			-- 退出个人资料
			x, y = member_user_profile() if x > -1 then break end
			-- 真八岐大蛇
			x, y = real_baqidashe() if x > -1 then break end
			-- 神秘商人
			x, y = mysterious_vender() if x > -1 then break end
			-- 喂食纸人
			x, y = feed_paperman() if x > -1 then break end
			-- 体力不足
			x, y = out_of_sushi() if x > -1 then break end
			break
		end
	end
	return RET_ERR
end

function juexing_group_fix_captain(element, mark, level, round, lock, captain_auto_group, captain_auto_invite, auto_invite_zone, group)
	local time_cnt = 0
	local invite = 1
	local tingyuan_time_cnt = 0
	local tansuo_time_cnt = 0
	local quit_end = 0
	local quit_con = 0
	local quit_grp = 0
	local invite_zone = 0
	local ret = 0
	local ret_ = 0
	local init = 1
	local x, y
	
	if auto_invite_zone == "好友" then
		invite_zone = 1
	elseif auto_invite_zone == "最近" then
		invite_zone = 2
	elseif auto_invite_zone == "跨区" then
		invite_zone = 3
	end
	
	while (1) do
		while (1) do
			-- 战
			x, y = round_fight() if (x > -1) then juexing_mark(mark) break end
			-- 开始战斗
			if group == "固定队2人" then
				x, y = captain_room_start_with_1_members() if (x > -1) then invite = 0 time_cnt = 0 break end
			end
			if group == "固定队3人" then
				x, y = captain_room_start_with_2_members() if (x > -1) then invite = 0 time_cnt = 0 break end
			end
			mSleep(500)
			-- 循环通用
			ret = loop_generic() if ret == RET_RECONN then return RET_RECONN end
			-- 超鬼王
			SuperGhost()
			-- 拒绝邀请
			x, y = member_team_refuse_invite() if (x > -1) then break end
			-- 战斗准备
			x, y = fight_ready() if (x > -1) then break end
			-- 战斗进行
			x, y = fight_ongoing()
			if x > -1 then
				if quit_grp == 1 then
					x_, y_ = fight_stop_auto_group()
					if x_ > -1 then
						quit_grp = 0
					end
				end
				break
			end
			-- 战斗胜利
			x, y, ret_ = fight_settle("觉醒")
			if (x > -1) then
				tingyuan_time_cnt = 0
				if ret_ == "Success" then
				win_cnt.global = win_cnt.global + 1
				show_win_fail(win_cnt.global, fail_cnt.global)
				win_cnt.juexing = win_cnt.juexing + 1
				if win_cnt.juexing == round then
					quit_grp = 1
				end
				if win_cnt.juexing > round then
					quit_end = 1
				end
				-- 智能突破Check
				ret = auto_jjtp_time_check()
				if ret == RET_VALID then
					quit_grp = 1
					quit_con = 1
				end
				elseif ret_ == "Failed" then
				fail_cnt.global = fail_cnt.global + 1
				show_win_fail(win_cnt.global, fail_cnt.global)
				fail_cnt.juexing = fail_cnt.juexing + 1
				end
				break
			end
			-- 失败邀请
			x, y = captain_team_lost_invite() if (x > -1) then random_touch(0, 673, 384, 20, 10) invite = 0 time_cnt = 0 break end -- 确定
			-- 自动邀请
			if (captain_auto_group == 1 and quit_end == 0 and quit_con == 0) then
				x, y = captain_team_set_auto_invite() if (x > -1) then break
				end
			end
			-- 胜利邀请
			x, y = captain_team_win_invite()
			if (x > -1) then
				if quit_end == 1 then
					random_touch(0, 460, 385, 20, 10)
				else
					random_touch(0, 674, 385, 20, 10)
					invite = 0
					time_cnt = 0
				end
				break
			end
			-- 创建初始化
			x, y = captain_room_create_init() if x > -1 then break end
			-- 创建私人队伍
			x, y = captain_room_create_private() if x > -1 then invite = 1 break end
			-- 邀请初始化
			x, y = captain_room_invite_init()
			if (x > -1) then
				time_cnt = time_cnt + 1
				mSleep(500)
				if (time_cnt > math.random(8, 12)) then
					invite = 1
				end
				if (captain_auto_invite == 1 and invite == 1) then
					random_touch(0, 565, 320, 50, 50) -- 邀请初始化
					x, y = captain_room_invite_init() if (x > -1) then break end
				end
				break
			end
			-- 邀请第一个好友
			if (captain_auto_invite == 1 and invite == 1) then
				x, y = captain_room_invite_first(invite_zone) if (x > -1) then invite = 0 time_cnt = 0 break end
			end
			-- 庭院
			x, y = lct_tingyuan() if (x > -1) then tingyuan_enter_tansuo() tingyuan_time_cnt = idle_at_tingyuan(tingyuan_time_cnt) break end
			-- 超鬼王
			SuperGhost()
			-- 探索
			x, y = lct_tansuo()
			if (x > -1) then
				if quit_end == 1 then
					stop_buff()
					lua_exit()
				end
				if quit_con == 1 then
					stop_buff()
					return RET_VALID
				end
				if buff_start_en == 1 then
					start_buff()
					buff_start_en = 0
				end
				random_touch(0, 90, 590, 20, 20)
				tansuo_time_cnt = idle_at_tansuo(tansuo_time_cnt)
				mSleep(1000)
				break
			end
			-- 觉醒之塔
			x, y = lct_juexingtower() if (x > -1) then juexing_element(element) break end
			-- 觉醒材料
			x, y = lct_juexingelement() if (x > -1) then level_select(level, init, lock, "觉醒") init = 0 group_start() break end -- 组队开始
			-- 退出个人资料
			x, y = member_user_profile() if x > -1 then break end
			-- 真八岐大蛇
			x, y = real_baqidashe() if x > -1 then break end
			-- 神秘商人
			x, y = mysterious_vender() if x > -1 then break end
			-- 喂食纸人
			x, y = feed_paperman() if x > -1 then break end
			-- 体力不足
			x, y = out_of_sushi() if x > -1 then break end
			break
		end
	end
	return RET_ERR
end