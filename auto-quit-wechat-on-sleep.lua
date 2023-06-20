local boundleID = "com.tencent.xinWeChat"

local function caffeinateCallback(eventType)
  if (eventType == hs.caffeinate.watcher.screensDidSleep) then
    print("screensDidSleep")
    
    local app = hs.application.get(boundleID)
    if app and app:isRunning() then
      app:kill()
    end
  elseif (eventType == hs.caffeinate.watcher.screensDidWake) then
    print("screensDidWake")

    hs.application.open(boundleID)
  elseif (eventType == hs.caffeinate.watcher.screensDidLock) then
    print("screensDidLock")
  elseif (eventType == hs.caffeinate.watcher.screensDidUnlock) then
    print("screensDidUnlock")
  end
end

caffeinateWatcher = hs.caffeinate.watcher.new(caffeinateCallback)
caffeinateWatcher:start()