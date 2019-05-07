require "util"
require "UI"

-- Def
RET_OK = 0
RET_ERR = -1
RET_VALID = 1
RET_RECONN = 2

-- Global cfg
HUD = nil
hud_info = nil
hud_button = nil
settlement_en = 0
offer_arr = {0, 0, 0, 0, 0, 0}
reconn = 0
turbo_settle = 0
turbo_settle_en = 0
buff_start = 0
buff_start_en = 0
buff_sel = {0, 0, 0, 0}
buff_stop_idle = 0
buff_stop_idle_time = 0
buff_stop_useup = 0

-- Global vars
win_cnt = {global = 0, yuhun = 0, tansuo = 0, jjtp = 0, juexing = 0, yyh = 0, yuling = 0, yqfy = 0, battle = 0, hundgho = 0}
fail_cnt = {global = 0, yuhun = 0, tansuo = 0, jjtp = 0, juexing = 0, yyh = 0, yuling = 0, yqfy = 0, battle = 0, hundgho = 0}

-- Init
system_date = os.date()
start_time = mTime()
ver = getOSType()
width, height = getScreenSize()
dpi = getScreenDPI()
screen_direct_init()
appid = frontAppName()
wid_div_dpi = width/dpi
width_dev = 640
height_dev = 1136
ratio = height_dev/height
s = (height*0.050)*(ratio)
setScreenScale(width_dev, height_dev) -- iPhone 5s
linkage, linkage_err = getCloudContent("WALL_BREAKER_LINKAGE", "BDAB2A1E8229572B", "0")
math.randomseed(os.time())
math.random(1,10000)
setTimer(5*60*1000, garbage_collect)
print(system_date)
print(string.format("OS = %s, AppID = %s, width = %d, height = %d, dpi = %d",ver, appid, width, height, dpi))

-- Portal
portal_UI()