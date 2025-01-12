-- **************************************************
-- 系统内置启动台快捷键经常失效，用脚本替代它
-- **************************************************

local function toggleLaunchpad()
  hs.application.launchOrFocus('Launchpad')
end

hs.hotkey.bind({ 'cmd' }, 'space', toggleLaunchpad)
