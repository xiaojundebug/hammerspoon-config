-- **************************************************
-- 输入法指示器
-- **************************************************

local height = 5
local alpha = 0.9
-- 配置指示器颜色
-- 你可以通过 `defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | grep "Input Mode"` 命令获取当前输入法
local colorsConfig = {
  {
    ime = 'com.apple.inputmethod.SCIM.ITABC',
    colors = {
      { hex = '#84cc16' },
      -- 你可以使用多个颜色
      -- { hex = '#ffffff' },
      -- { hex = '#3b82f6' },
    }
  },
}

local myCanvas = {}
local lastSourceID = ''

-- 绘制角标矩形
function drawIndicator(config)
  local colors = config.colors
  local screens = hs.screen.allScreens()
  
  for _, s in ipairs(screens) do
    local frame = s:fullFrame()
    local cellW = frame.w / #colors
    
    for i, color in ipairs(config.colors) do
      local startX = (i - 1) * cellW
      local startY = 0
      local rect = {
        type = 'rectangle',
        fillColor = color,
        action = 'fill',
        frame = { x = startX, y = startY, h = height, w = cellW }
      }

      if not myCanvas[s] then
        myCanvas[s] = hs.canvas.new({ x = frame.x, y = frame.y, w = frame.w, h = height })
        myCanvas[s]:level(hs.canvas.windowLevels.overlay)
        myCanvas[s]:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
        myCanvas[s]:alpha(alpha)
      end

      myCanvas[s][i] = rect
    end

    myCanvas[s]:show()
  end
end

-- 清除 Canvas 上的内容
function clearCanvas()
  for _, canvas in pairs(myCanvas) do
    canvas:delete()
  end
  myCanvas = {}
end

-- 更新 Canvas 显示
local function updateCanvas()
  clearCanvas()

  for index, config in pairs(colorsConfig) do
    local ime = config.ime
    local colors = config.config

    if hs.keycodes.currentSourceID() == ime then
      drawIndicator(config)
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
dn = hs.distributednotifications.new(
  handleInputSourceChanged,
  -- or 'AppleSelectedInputSourcesChangedNotification'
  'com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged'
)
-- 每秒同步一次，避免由于错过事件监听导致状态不同步
indicatorSyncTimer = hs.timer.new(1, handleInputSourceChanged)
screenWatcher = hs.screen.watcher.new(updateCanvas)

dn:start()
indicatorSyncTimer:start()
screenWatcher:start()

-- 初始执行一次
updateCanvas()
