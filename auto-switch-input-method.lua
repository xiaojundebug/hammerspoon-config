-- **************************************************
-- 根据 App 自动切换输入法
-- **************************************************

local utils = require('./utils')

local function toChinese()
  hs.keycodes.currentSourceID('com.apple.inputmethod.SCIM.ITABC')
end

local function toEnglish()
  hs.keycodes.currentSourceID('com.apple.keylayout.ABC')
end

-- 定义你自己想要自动切换输入法的 App
local app2Ime = {
  {'/Applications/Terminal.app', 'English'},
  {'/Applications/iTerm.app', 'English'},
  {'/Applications/Visual Studio Code.app', 'English'},
  {'/Applications/WebStorm.app', 'English'},
  {'/Applications/Google Chrome.app', 'English'},
  {'/Applications/QQ.app', 'Chinese'},
  {'/Applications/WeChat.app', 'Chinese'},
}

local function updateFocusedAppInputMethod(appObject)
  local ime
  local focusAppPath = appObject:path()

  for index, app in pairs(app2Ime) do
    local appPath = app[1]
    local expectedIme = app[2]

    if focusAppPath == appPath then
      ime = expectedIme
      break
    end
  end

  if ime == 'English' then
    toEnglish()
  elseif ime == 'Chinese' then
    toChinese()
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
