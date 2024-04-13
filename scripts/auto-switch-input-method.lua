-- **************************************************
-- 根据 App 自动切换输入法
-- **************************************************

local utils = require('./utils')

local CHINESE = 'com.apple.inputmethod.SCIM.ITABC'
local ENGLISH = 'com.apple.keylayout.ABC'

-- 定义你自己想要自动切换输入法的 App
local APP_TO_IME = {
  ['/Applications/Terminal.app'] = ENGLISH ,
  ['/Applications/iTerm.app'] = ENGLISH,
  ['/Applications/Visual Studio Code.app'] = ENGLISH,
  ['/Applications/WebStorm.app'] = ENGLISH,
  ['/Applications/Google Chrome.app'] = ENGLISH,
  ['/Applications/QQ.app'] = CHINESE,
  ['/Applications/WeChat.app'] = CHINESE,
  ['/Applications/企业微信.app'] = CHINESE,
  ['/Applications/DingTalk.app'] = CHINESE,
}

local function updateFocusedAppInputMethod(appObject)
  local focusedAppPath = appObject:path()
  local expectedIme = APP_TO_IME[focusedAppPath]

  if expectedIme then
    hs.keycodes.currentSourceID(expectedIme)
  end
end

local debouncedUpdateFn = utils.debounce(updateFocusedAppInputMethod, 0.1)

local function applicationWatcher(appName, eventType, appObject)
  if eventType == hs.application.watcher.activated then
    debouncedUpdateFn(appObject)
  end
end

asim_appWatcher = hs.application.watcher.new(applicationWatcher)
asim_appWatcher:start()
