-- **************************************************
-- 根据 App 自动切换输入法
-- **************************************************

local utils = require('./utils')

local Chinese = 'com.apple.inputmethod.SCIM.ITABC'
local English = 'com.apple.keylayout.ABC'

-- 定义你自己想要自动切换输入法的 App
local app2Ime = {
  { '/Applications/Terminal.app', English } ,
  { '/Applications/iTerm.app', English },
  { '/Applications/Visual Studio Code.app', English },
  { '/Applications/WebStorm.app', English },
  { '/Applications/Google Chrome.app', English },
  { '/Applications/QQ.app', Chinese },
  { '/Applications/WeChat.app', Chinese },
}

local function updateFocusedAppInputMethod(appObject)
  local focusedAppPath = appObject:path()

  for _, app in pairs(app2Ime) do
    local appPath = app[1]
    local expectedIme = app[2]

    if focusedAppPath == appPath then
      hs.keycodes.currentSourceID(expectedIme)
      break
    end
  end
end

local debouncedUpdateFn = utils.debounce(updateFocusedAppInputMethod, 0.1)

local function applicationWatcher(appName, eventType, appObject)
  if eventType == hs.application.watcher.activated then
    debouncedUpdateFn(appObject)
  end
end

appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()
