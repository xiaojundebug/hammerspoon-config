-- **************************************************
-- 环形 App 启动器
-- **************************************************
-- ## 使用方式
-- 1. 按下 alt + tab 呼出环形菜单，这时候可以松开 tab 键
-- 2. 滑动鼠标选中目标 app 后松开 alt 键跳到目标 app
-- **************************************************
-- ## 架构
-- Geometry   —— 纯几何计算，无副作用（图标坐标、扇区角度、命中检测）
-- View       —— 只负责 canvas 渲染，不感知 app / 鼠标
-- Controller —— 状态机 + 事件监听，串起 Geometry 与 View
-- **************************************************

local utils = require('./utils')
local tween = require('./tween')

-- --------------------------------------------------
-- 配置（唯一来源）
-- --------------------------------------------------

local CONFIG = {
  -- 菜单项
  applications = {
    { name = 'QQ', icon = '/Applications/QQ.app/Contents/Resources/icon.icns' },
    { name = 'WeChat', icon = '/Applications/WeChat.app/Contents/Resources/AppIcon.icns' },
    { name = '企业微信', icon = '/Applications/企业微信.app/Contents/Resources/AppIcon.icns' },
    { name = 'Google Chrome', icon = '/Applications/Google Chrome.app/Contents/Resources/app.icns' },
    { name = 'Visual Studio Code', icon = '/Applications/Visual Studio Code.app/Contents/Resources/Code.icns' },
    { name = 'SnippetsLab', icon = '/Applications/SnippetsLab.app/Contents/Resources/AppIcon.icns' },
  },

  -- 尺寸
  ringSize = 280,         -- 圆环外径
  ringThickness = nil,    -- 圆环粗细，留空默认 ringSize / 4
  iconSize = nil,         -- 图标大小，留空默认 ringThickness / 2

  -- 行为
  followPointer = true,   -- 在鼠标指针处弹出（false 则屏幕居中）
  tabToPick = false,      -- 是否允许按 tab 键循环选择

  -- 颜色（实色）
  ringColor = { hex = '#1C1C1E' },   -- 圆环
  centerColor = { hex = '#0E0E10' }, -- 中心
  activeColor = { hex = '#FF7A45' }, -- 选中扇区

  -- 选中图标放大倍数（设为 1 可关闭）
  iconActiveScale = 1.15,

  -- 中心标签
  showLabel = true,
  labelColor = { hex = '#FAFAF7' },
  labelSize = 14,
  labelFont = '.AppleSystemUIFontRounded', -- SF Rounded

  -- 弹出动画
  animated = true,
  animationDuration = 0.3,
}

-- --------------------------------------------------
-- Geometry —— 纯几何计算
-- --------------------------------------------------

local Geometry = {}
Geometry.__index = Geometry

function Geometry.new(opts)
  local self = setmetatable({}, Geometry)

  self.ringSize = opts.ringSize
  self.thickness = opts.thickness or self.ringSize / 4
  self.iconSize = opts.iconSize or self.thickness / 2
  self.count = opts.count

  self.center = self.ringSize / 2
  self.ringRadius = self.ringSize / 2
  -- 圆环描边的中心线半径（图标与指示弧都落在这条线上）
  self.centerRadius = self.ringRadius - self.thickness / 2
  -- 中心空洞半径（命中检测阈值 + 中心盘半径）
  self.innerRadius = self.ringRadius - self.thickness
  self.sliceDeg = 360 / self.count
  self.halfSliceDeg = self.sliceDeg / 2

  return self
end

-- 第 index 个图标在 canvas 内的 frame，scale 用于选中放大
-- 减 90° 是为了让第一项从十二点钟方向开始（标准弧度 0 在三点钟方向）
function Geometry:iconFrame(index, scale)
  local size = self.iconSize * (scale or 1)
  local rad = math.rad(self.sliceDeg * (index - 1) - 90)
  local cx = self.centerRadius * math.cos(rad) + self.center
  local cy = self.centerRadius * math.sin(rad) + self.center
  local half = size / 2
  return { x = cx - half, y = cy - half, w = size, h = size }
end

-- 第 index 个扇区指示弧的起止角度（canvas 弧度系：0 在十二点，顺时针）
function Geometry:sliceAngles(index)
  return self.sliceDeg * (index - 1) - self.halfSliceDeg,
         self.sliceDeg * index - self.halfSliceDeg
end

-- 命中检测：传入相对圆心的偏移，返回扇区序号，落在中心空洞返回 nil
function Geometry:hitTest(dx, dy)
  if dx * dx + dy * dy <= self.innerRadius * self.innerRadius then
    return nil
  end
  -- 弧度 -> 角度（-180~180），再补偿到「十二点起、0~360」
  local deg = (math.deg(math.atan(dy, dx)) + 90 + self.halfSliceDeg) % 360
  return math.floor(deg / self.sliceDeg) + 1
end

-- --------------------------------------------------
-- View —— canvas 渲染
-- --------------------------------------------------

-- 固定图层序号
local LAYER_RING = 1    -- 圆环底盘
local LAYER_CENTER = 2  -- 中心盘
local LAYER_ACTIVE = 3  -- 选中扇区
local LAYER_ICON = 3    -- 图标从 LAYER_ICON + index 开始

local View = {}
View.__index = View

function View.new(geo, opts)
  local self = setmetatable({}, View)

  self.geo = geo
  self.animated = opts.animated
  self.animationDuration = opts.animationDuration or 0.3

  self.activeColor = opts.activeColor or { hex = '#FF7A45' }
  self.iconActiveScale = opts.iconActiveScale or 1.15

  self.showLabel = opts.showLabel ~= false
  self.labelColor = opts.labelColor or { hex = '#FAFAF7' }
  self.labelFont = opts.labelFont or '.AppleSystemUIFontRounded'
  self.labelSize = opts.labelSize or 14
  -- 标签宽度控制在中心盘内，避免压到圆环上
  self.labelWidth = geo.innerRadius * 1.9

  self.active = nil
  self.cancelAnimation = nil
  self.count = 0
  self.labels = {}
  self.labelIndex = nil

  local size = geo.ringSize
  local canvas = hs.canvas.new({ x = 0, y = 0, w = size, h = size })
  canvas:level(hs.canvas.windowLevels.overlay)

  -- 圆环底盘
  canvas[LAYER_RING] = {
    type = 'circle',
    center = { x = '50%', y = '50%' },
    radius = geo.ringRadius,
    action = 'fill',
    fillColor = opts.ringColor or { hex = '#1C1C1E' },
  }

  -- 中心盘（盖住圆环中部，形成「环」+ 承托文字）
  canvas[LAYER_CENTER] = {
    type = 'circle',
    center = { x = '50%', y = '50%' },
    radius = geo.innerRadius,
    action = 'fill',
    fillColor = opts.centerColor or { hex = '#0E0E10' },
  }

  -- 选中扇区
  canvas[LAYER_ACTIVE] = {
    type = 'arc',
    center = { x = '50%', y = '50%' },
    radius = geo.centerRadius,
    action = 'stroke',
    startAngle = -geo.halfSliceDeg,
    endAngle = geo.halfSliceDeg,
    strokeWidth = geo.thickness * 0.9,
    strokeColor = self.activeColor,
    arcRadii = false,
  }

  self.canvas = canvas
  return self
end

-- 渲染图标（image 已由 Controller 预加载）与中心标签
function View:renderIcons(items)
  self.count = #items
  self.labels = {}

  for i, item in ipairs(items) do
    self.labels[i] = item.name
    self.canvas[LAYER_ICON + i] = {
      type = 'image',
      image = item.image,
      frame = self.geo:iconFrame(i),
    }
  end

  -- 中心标签居于最上层
  if self.showLabel then
    self.labelIndex = LAYER_ICON + self.count + 1
    self.canvas[self.labelIndex] = {
      type = 'text',
      text = '',
      textFont = self.labelFont,
      textSize = self.labelSize,
      textColor = self.labelColor,
      textAlignment = 'center',
      textLineBreak = 'truncateTail',
      frame = { x = 0, y = 0, w = self.labelWidth, h = self.labelSize },
    }
  end

  self:reset()
end

-- 设置中心标签文字并垂直居中
-- text 元素在 frame 内是顶部对齐的，所以按文本真实高度定 frame 高度再居中
function View:setLabel(text)
  if not self.labelIndex then
    return
  end

  self.canvas[self.labelIndex].text = text or ''

  if text and text ~= '' then
    local g = self.geo
    local measured = self.canvas:minimumTextSize(self.labelIndex, text)
    local h = measured and measured.h or self.labelSize
    self.canvas[self.labelIndex].frame = {
      x = g.center - self.labelWidth / 2,
      y = g.center - h / 2,
      w = self.labelWidth,
      h = h,
    }
  end
end

-- 回到无选中的初始状态
function View:reset()
  self.active = nil
  self.canvas[LAYER_ACTIVE].strokeColor = { alpha = 0 }

  for i = 1, self.count do
    self.canvas[LAYER_ICON + i].frame = self.geo:iconFrame(i)
  end

  self:setLabel('')
end

-- 高亮指定扇区，nil 表示取消高亮
function View:highlight(index)
  if self.active == index then
    return
  end
  self.active = index

  -- 选中扇区
  if index then
    local startAngle, endAngle = self.geo:sliceAngles(index)
    self.canvas[LAYER_ACTIVE].startAngle = startAngle
    self.canvas[LAYER_ACTIVE].endAngle = endAngle
    self.canvas[LAYER_ACTIVE].strokeColor = self.activeColor
  else
    self.canvas[LAYER_ACTIVE].strokeColor = { alpha = 0 }
  end

  -- 选中图标放大，其余复原
  for i = 1, self.count do
    local scale = (i == index) and self.iconActiveScale or 1
    self.canvas[LAYER_ICON + i].frame = self.geo:iconFrame(i, scale)
  end

  -- 中心标签
  self:setLabel(index and self.labels[index] or '')
end

function View:getActive()
  return self.active
end

-- center 为圆心屏幕坐标
function View:moveTo(center)
  local half = self.geo.center
  self.canvas:topLeft({ x = center.x - half, y = center.y - half })
end

function View:isShowing()
  return self.canvas:isShowing()
end

function View:show()
  self.canvas:show()

  if not self.animated then
    return
  end

  local matrix = hs.canvas.matrix.identity()
  local c = self.geo.center

  self.cancelAnimation = utils.animate({
    duration = self.animationDuration,
    easing = tween.easeOutExpo,
    onProgress = function(progress)
      self.canvas:transformation(
        matrix
          :translate(c, c)
          :scale((0.1 * progress) + 0.9)
          :translate(-c, -c)
      )
      self.canvas:alpha(progress)
    end,
  })
end

function View:hide()
  self.canvas:hide()

  if self.cancelAnimation then
    self.cancelAnimation()
    self.cancelAnimation = nil
  end

  -- 复位，保证下次 show 从干净状态开始
  self.canvas:transformation(hs.canvas.matrix.identity())
  self.canvas:alpha(1)
  self:reset()
end

-- --------------------------------------------------
-- Controller —— 状态机 + 事件监听
-- --------------------------------------------------

local Controller = {}
Controller.__index = Controller

function Controller.new(config)
  local self = setmetatable({}, Controller)

  self.items = config.applications
  self.followPointer = config.followPointer
  self.tabToPick = config.tabToPick
  self.center = nil

  -- 预加载图标
  for _, item in ipairs(self.items) do
    item.image = hs.image.imageFromPath(item.icon)
  end

  self.geo = Geometry.new({
    ringSize = config.ringSize,
    thickness = config.ringThickness,
    iconSize = config.iconSize,
    count = #self.items,
  })
  self.view = View.new(self.geo, config)
  self.view:renderIcons(self.items)

  return self
end

-- 鼠标移动 -> 命中检测 -> 高亮
function Controller:onMouseMoved()
  local mouse = hs.mouse.absolutePosition()
  local index = self.geo:hitTest(mouse.x - self.center.x, mouse.y - self.center.y)
  self.view:highlight(index)
end

-- tab 循环选择下一项
function Controller:cycleNext()
  local active = self.view:getActive()
  local nextIndex = (active == nil) and 1 or (active % #self.items) + 1
  self.view:highlight(nextIndex)
end

function Controller:showRing()
  if self.view:isShowing() then
    if self.tabToPick then
      self:cycleNext()
    end
    return
  end

  local frame = hs.mouse.getCurrentScreen():fullFrame()
  local half = self.geo.center

  if self.followPointer then
    local mouse = hs.mouse.absolutePosition()
    self.center = {
      x = utils.clamp(mouse.x, frame.x + half, frame.x + frame.w - half),
      y = utils.clamp(mouse.y, frame.y + half, frame.y + frame.h - half),
    }
  else
    self.center = {
      x = (frame.x + frame.w) / 2,
      y = (frame.y + frame.h) / 2,
    }
  end

  self.view:moveTo(self.center)
  self.view:show()

  ring_mouseEvtTap:start()
  -- 初始触发一次
  self:onMouseMoved()
end

function Controller:hideRing()
  if not self.view:isShowing() then
    return
  end

  -- 必须在 hide 复位前取出当前选项
  local index = self.view:getActive()
  self.view:hide()

  if ring_mouseEvtTap then
    ring_mouseEvtTap:stop()
  end

  if index then
    local app = self.items[index].name
    local ok = pcall(hs.application.launchOrFocus, app)
    if not ok then
      hs.notify.new({ title = 'Ring', informativeText = '启动失败：' .. app }):send()
    end
  end
end

function Controller:onKey(event)
  local types = hs.eventtap.event.types
  local keyCode = event:getKeyCode()
  local eventType = event:getType()
  local isAltDown = event:getFlags().alt

  -- alt + tab 显示菜单
  if eventType == types.keyDown and keyCode == hs.keycodes.map.tab and isAltDown then
    self:showRing()
    return true -- 阻止事件传递
  end

  -- 松开 alt 隐藏菜单
  if eventType == types.flagsChanged and keyCode == hs.keycodes.map.alt and not isAltDown then
    self:hideRing()
  end

  return false
end

function Controller:enable()
  -- 监听器用全局变量持有，避免被 GC

  -- 鼠标移动：仅在菜单显示时 start/stop，这里只创建一次
  ring_mouseEvtTap = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
    self:onMouseMoved()
    return false
  end)

  -- 快捷键：常驻监听
  ring_keyEvtTap = hs.eventtap.new(
    { hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged },
    function(event)
      return self:onKey(event)
    end
  )
  ring_keyEvtTap:start()
end

-- --------------------------------------------------
-- 启动
-- --------------------------------------------------

local controller = Controller.new(CONFIG)
controller:enable()
