-- **************************************************
-- 输入法指示器
-- **************************************************

-- 指示器高度
local HEIHGT = 5
-- 指示器透明度
local ALPHA = 1
-- 指示器颜色
local IME_TO_COLORS = {
  -- 系统自带简中输入法
  ['com.apple.inputmethod.SCIM.ITABC'] = {
    { hex = '#dc2626' },
    -- 你可以使用多个颜色，它们之间会进行渐变
    -- { hex = '#0ea5e9' },
  }
}

local canvases = {}
local lastSourceID = nil

-- 绘制指示器
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
local function updateCanvas(sourceID)
  clearCanvas()

  local colors = IME_TO_COLORS[sourceID or hs.keycodes.currentSourceID()]

  if colors then
    drawIndicator(colors)
  end
end

local function handleInputSourceChanged()
  local currentSourceID = hs.keycodes.currentSourceID()

  if lastSourceID ~= currentSourceID then
    updateCanvas(currentSourceID)
    lastSourceID = currentSourceID
  end
end

-- 输入法变化事件监听
-- 通过 hs.keycodes.inputSourceChanged 方式监听有时候不触发，直接监听系统事件可以解决，
-- 参考 https://github.com/Hammerspoon/hammerspoon/issues/1499）
imi_dn = hs.distributednotifications.new(
  handleInputSourceChanged,
  -- or 'AppleSelectedInputSourcesChangedNotification'
  'com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged'
)
-- 每秒同步一次，避免由于错过事件监听导致状态不同步
imi_indicatorSyncTimer = hs.timer.new(1, handleInputSourceChanged)
-- 屏幕变化时候重新渲染
imi_screenWatcher = hs.screen.watcher.new(function() updateCanvas() end)

imi_dn:start()
imi_indicatorSyncTimer:start()
imi_screenWatcher:start()

-- 初始执行一次
updateCanvas()
