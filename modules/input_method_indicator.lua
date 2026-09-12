-- **************************************************
-- 输入法指示器
-- **************************************************
-- 在每块屏幕顶部画一条彩色细条，指示当前输入法。
-- 仅在切到指定输入法时创建画布，切走即销毁，空闲零占用。
-- **************************************************

-- --------------------------------------------------
-- 配置
-- --------------------------------------------------

local CONFIG = {
  height = 5,
  width = 128,
  align = 'right',  -- 水平对齐：'left' | 'center' | 'right'
  alpha = 1,
  gradient = false, -- 多色时线性渐变（否则等分分格）

  -- 输入法 -> 颜色
  colors = {
    -- 微信输入法 com.tencent.inputmethod.wetype.pinyin
    -- 豆包输入法 com.bytedance.inputmethod.doubaoime.pinyin
    ['com.bytedance.inputmethod.doubaoime.pinyin'] = {
      { hex = '#de2910' },
      -- { hex = '#ffffff' },
      -- { hex = '#0ea5e9' },
    },
  },
}

-- --------------------------------------------------
-- 渲染
-- --------------------------------------------------

local canvases = {}

local function destroy()
  for _, canvas in ipairs(canvases) do
    canvas:delete()
  end
  canvases = {}
end

local function originX(frame)
  if CONFIG.align == 'left' then
    return frame.x
  elseif CONFIG.align == 'center' then
    return frame.x + (frame.w - CONFIG.width) / 2
  end
  return frame.x + frame.w - CONFIG.width
end

-- 颜色列表 -> canvas 元素
local function buildElements(colors)
  if CONFIG.gradient and #colors > 1 then
    return { {
      type = 'rectangle',
      action = 'fill',
      fillGradient = 'linear',
      fillGradientColors = colors,
      frame = { x = 0, y = 0, w = CONFIG.width, h = CONFIG.height },
    } }
  end

  local els = {}
  local cellW = CONFIG.width / #colors

  for i, color in ipairs(colors) do
    els[i] = {
      type = 'rectangle',
      action = 'fill',
      fillColor = color,
      frame = { x = (i - 1) * cellW, y = 0, w = cellW, h = CONFIG.height },
    }
  end

  return els
end

-- 按颜色在每块屏幕重画；colors 为 nil 则全部销毁
local function render(colors)
  destroy()

  if not colors then
    return
  end

  local els = buildElements(colors)

  for _, screen in ipairs(hs.screen.allScreens()) do
    local frame = screen:fullFrame()
    local canvas = hs.canvas.new({
      x = originX(frame),
      y = frame.y,
      w = CONFIG.width,
      h = CONFIG.height,
    })
    canvas:level(hs.canvas.windowLevels.overlay)
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    canvas:alpha(CONFIG.alpha)

    for i, el in ipairs(els) do
      canvas[i] = el
    end

    canvas:show()
    table.insert(canvases, canvas)
  end
end

-- --------------------------------------------------
-- 监听
-- --------------------------------------------------

local lastSourceID = nil

-- force 跳过「未变化」守卫，供屏幕变化 / 初始化使用
local function update(force)
  local sourceID = hs.keycodes.currentSourceID()
  if not force and sourceID == lastSourceID then
    return
  end
  lastSourceID = sourceID
  render(CONFIG.colors[sourceID])
end

-- 以下监听器用全局变量持有，避免被 GC

-- 输入法变化。hs.keycodes.inputSourceChanged 有时不触发，直接监听系统事件，
-- 参考 https://github.com/Hammerspoon/hammerspoon/issues/1499
imi_dn = hs.distributednotifications.new(
  function() update() end,
  'com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged'
)
-- 每秒兜底同步，避免漏事件导致状态不同步
imi_syncTimer = hs.timer.new(1, function() update() end)
-- 屏幕变化时按新几何重画
imi_screenWatcher = hs.screen.watcher.new(function() update(true) end)

imi_dn:start()
imi_syncTimer:start()
imi_screenWatcher:start()

-- 初始渲染
update(true)
