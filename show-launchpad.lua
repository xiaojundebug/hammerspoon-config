-- **************************************************
-- 系统设置快捷键打开启动台经常不工作，用脚本实现它！
-- **************************************************

local function toggleLaunchpad()
  hs.application.launchOrFocus('Launchpad')
end

hs.hotkey.bind({ 'cmd' }, 'space', toggleLaunchpad)