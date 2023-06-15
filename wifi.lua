-- **************************************************
-- 连接到公司 Wi-Fi 时自动静音扬声器
-- **************************************************

-- 定义公司的 Wi-Fi 名称
local companyWifi = "MUDU"

-- 检测当前 Wi-Fi 的名称
local function getCurrentWifiName()
  local wifiInfo = hs.wifi.currentNetwork()
  return wifiInfo or ""
end

-- 静音函数
local function muteVolume()
  hs.audiodevice.defaultOutputDevice():setOutputMuted(true)
end

-- 取消静音函数
local function unmuteVolume()
  hs.audiodevice.defaultOutputDevice():setOutputMuted(false)
end

-- 监听 Wi-Fi 变化
wifiWatcher = hs.wifi.watcher.new(function ()
  local currentWifi = getCurrentWifiName()
  if currentWifi == companyWifi then
    muteVolume()  -- 如果是公司 Wi-Fi，则静音
  else
    unmuteVolume()  -- 否则取消静音
  end
end)

-- 启动 Wi-Fi 监听
wifiWatcher:start()
