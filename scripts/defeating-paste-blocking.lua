-- **************************************************
-- 有些网站禁止粘贴，该脚本可以模拟系统输入事件绕过限制
-- **************************************************

hs.hotkey.bind({ 'cmd', 'shift' }, 'v', function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)
