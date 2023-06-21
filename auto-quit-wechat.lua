local utils = require("./utils")

local BOUNDLE_ID = "com.tencent.xinWeChat"
local WAIT_DURATION = 60 * 10 -- 10 分钟后不亮屏则杀掉微信

local clearTimeout = nil

local function quit()
  local app = hs.application.get(BOUNDLE_ID)
  if app and app:isRunning() then
    app:kill()
  end
end

local function caffeinateCallback(eventType)
  if (eventType == hs.caffeinate.watcher.screensDidSleep) then
    print("screensDidSleep")
  elseif (eventType == hs.caffeinate.watcher.screensDidWake) then
    print("screensDidWake")
  elseif (eventType == hs.caffeinate.watcher.screensDidLock) then
    print("screensDidLock")
    clearTimeout = utils.setTimeout(quit, WAIT_DURATION)
  elseif (eventType == hs.caffeinate.watcher.screensDidUnlock) then
    print("screensDidUnlock")
    clearTimeout()
    -- hs.application.open(BOUNDLE_ID)
  end
end

caffeinateWatcher = hs.caffeinate.watcher.new(caffeinateCallback)
caffeinateWatcher:start()