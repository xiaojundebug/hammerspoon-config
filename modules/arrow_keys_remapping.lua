-- **************************************************
-- 方向键映射
-- **************************************************

-- --------------------------------------------------
-- 修饰键
local MODS = { 'rShift' }
-- 映射
local MAPPING = {
  up    = 'w',
  down  = 's',
  left  = 'a',
  right = 'd',
}
-- --------------------------------------------------

hs.loadSpoon('LeftRightHotkey')

local function postKeyEvent(keyCode)
  hs.eventtap.event.newKeyEvent(keyCode, true):post()
  hs.eventtap.event.newKeyEvent(keyCode, false):post()
end

local function up()
  postKeyEvent(hs.keycodes.map['up'])
end

local function down()
  postKeyEvent(hs.keycodes.map['down'])
end

local function left()
  postKeyEvent(hs.keycodes.map['left'])
end

local function right()
  postKeyEvent(hs.keycodes.map['right'])
end

local function bind(key, func)
  spoon.LeftRightHotkey:bind(MODS, key, func, nil, func)
end

bind(MAPPING.up, up)
bind(MAPPING.down, down)
bind(MAPPING.left, left)
bind(MAPPING.right, right)

spoon.LeftRightHotkey:start()
