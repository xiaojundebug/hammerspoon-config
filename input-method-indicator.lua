-- **************************************************
-- 输入法指示器
-- **************************************************

local width = 90
local height = 5
local alpha = 1
local colorsConfig = {
  {
    ime = 'com.apple.inputmethod.SCIM.ITABC',
    colors = {
      { hex = '#ef4444' },
      { hex = '#ffffff' },
      { hex = '#3b82f6' },
    }
  },
}

local myCanvas = {}
local lastSourceID = ''

-- 绘制角标矩形
function drawIcon(config)
  local colors = config.colors
  local screens = hs.screen.allScreens()
  local cellW = width / #colors

  for _, s in ipairs(screens) do
    local frame = s:fullFrame()

    for i, color in ipairs(config.colors) do
      local startX = frame.w - width + (i - 1) * cellW
      local startY = 0
      local rect = {
        type = 'rectangle',
        fillColor = color,
        action = 'fill',
        frame = { x = startX, y = startY, h = height, w = cellW }
      }

      if not myCanvas[s] then
        myCanvas[s] = hs.canvas.new({ x = frame.x, y = frame.y, w = frame.w, h = frame.h })
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
  local currentSourceID = hs.keycodes.currentSourceID()

  if lastSourceID == currentSourceID then
    return
  end

  lastSourceID = currentSourceID

  clearCanvas()

  for index, config in pairs(colorsConfig) do
    local ime = config.ime
    local colors = config.config

    if currentSourceID == ime then
      drawIcon(config)
      break
    end
  end
end

local function handleInputSourceChanged()
  updateCanvas()
end

-- 注册输入法变化事件监听（该方式有时候不触发，参考 https://github.com/Hammerspoon/hammerspoon/issues/1499）
-- hs.keycodes.inputSourceChanged(handleInputSourceChanged)

dn = hs.distributednotifications.new(
  function(name, object, userInfo)
    handleInputSourceChanged()
  end,
  -- or 'AppleSelectedInputSourcesChangedNotification'
  'com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged'
)
dn:start()

updateCanvas()
