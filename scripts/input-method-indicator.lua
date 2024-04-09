-- **************************************************
-- 输入法指示器
-- **************************************************

-- 指示器高度
local HEIHGT = 5
-- 指示器透明度
local ALPHA = 0.9
-- 指示器颜色
local IME_TO_COLORS = {
  -- 系统自带简中输入法
  ['com.apple.inputmethod.SCIM.ITABC'] = {
    { hex = '#8b5cf6' },
    -- 你可以使用多个颜色，它们之间会进行渐变
    { hex = '#0ea5e9' },
  }
}

local canvases = {}
local lastSourceID = ''

-- 绘制角标矩形
local function drawIndicator(colors)
  local screens = hs.screen.allScreens()

  for i, screen in ipairs(screens) do
    local frame = screen:fullFrame()

    local canvas = hs.canvas.new({ x = frame.x, y = frame.y, w = frame.w, h = HEIHGT })
    canvas:level(hs.canvas.windowLevels.overlay)
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    canvas:alpha(ALPHA)

    local rect = {
      type = 'rectangle',
      action = 'fill',
      frame = { x = 0, y = 0, w = frame.w, h = HEIHGT }
    }
    if #colors > 1 then
      rect.fillGradient = 'linear'
      rect.fillGradientColors = colors
    else
      rect.fillColor = colors[1]
    end

    canvas[1] = rect
    canvas:show()
    canvases[i] = canvas
  end
end

-- 清除 Canvas 上的内容
local function clearCanvas()
  for _, canvas in ipairs(canvases) do
    canvas:delete()
  end
  canvases = {}
end

-- 更新 Canvas 显示
local function updateCanvas()
  clearCanvas()

  for ime, colors in pairs(IME_TO_COLORS) do
    if hs.keycodes.currentSourceID() == ime then
      drawIndicator(colors)
      break
    end
  end
end

local function handleInputSourceChanged()
  local currentSourceID = hs.keycodes.currentSourceID()

  if lastSourceID ~= currentSourceID then
    updateCanvas()
  end

  lastSourceID = currentSourceID
end

-- 注册输入法变化事件监听（该方式有时候不触发，参考 https://github.com/Hammerspoon/hammerspoon/issues/1499）
-- hs.keycodes.inputSourceChanged(handleInputSourceChanged)
imi_dn = hs.distributednotifications.new(
  handleInputSourceChanged,
  -- or 'AppleSelectedInputSourcesChangedNotification'
  'com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged'
)
-- 每秒同步一次，避免由于错过事件监听导致状态不同步
imi_indicatorSyncTimer = hs.timer.new(1, handleInputSourceChanged)
imi_screenWatcher = hs.screen.watcher.new(updateCanvas)

imi_dn:start()
imi_indicatorSyncTimer:start()
imi_screenWatcher:start()

-- 初始执行一次
updateCanvas()
