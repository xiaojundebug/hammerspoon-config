-- **************************************************
-- 连接到公司 Wi-Fi 后自动静音
-- **************************************************

-- --------------------------------------------------
-- 定义公司的 wifi 名称
local WORK_SSID = 'MUDU'
-- --------------------------------------------------

local function mute()
  hs.audiodevice.defaultOutputDevice():setOutputMuted(true)
end

local function unmute()
  hs.audiodevice.defaultOutputDevice():setOutputMuted(false)
end

local handleWifiChanged = function()
  local currentSSID = hs.wifi.currentNetwork()

  if currentSSID == WORK_SSID then
    mute()
  else
    unmute()
  end
end

wm_wifiWatcher = hs.wifi.watcher.new(handleWifiChanged)
wm_wifiWatcher:start()
