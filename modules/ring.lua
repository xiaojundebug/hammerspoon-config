-- **************************************************
-- 环形 App 启动器
-- **************************************************
-- ## 使用方式
-- 1. 按下 alt + tab 呼出环形菜单，这时候可以松开 tab 键
-- 2. 滑动鼠标选中目标 app 后松开 alt 键跳到目标 app
-- **************************************************

local utils = require('./utils')
local tween = require('./tween')

-- --------------------------------------------------
-- 自定义配置
-- --------------------------------------------------

-- 菜单项配置
local APPLICATIONS = {
  { name = 'QQ', icon = '/Applications/QQ.app/Contents/Resources/icon.icns' },
  { name = 'WeChat', icon = '/Applications/WeChat.app/Contents/Resources/AppIcon.icns' },
  { name = '企业微信', icon = '/Applications/企业微信.app/Contents/Resources/AppIcon.icns' },
  { name = 'Google Chrome', icon = '/Applications/Google Chrome.app/Contents/Resources/app.icns' },
  { name = 'Visual Studio Code', icon = '/Applications/Visual Studio Code.app/Contents/Resources/Code.icns' },
  { name = 'Spotify', icon = '/Applications/Spotify.app/Contents/Resources/Icon.icns' },
  -- { name = 'WebStorm', icon = '/Applications/WebStorm.app/Contents/Resources/webstorm.icns' }
}
-- 菜单圆环大小
local RING_SIZE = 280
-- 菜单圆环粗细
local RING_THICKNESS = RING_SIZE / 4
-- 图标大小
local ICON_SIZE = RING_THICKNESS / 2
-- 是否菜单在鼠标指针处弹出，而不是居中
local FOLLOW_POINTER = true
-- 颜色配置
local COLOR_PATTERN = {
  inactive = { hex = '#000000' },
  active = { hex = '#393e46' }
}
-- 透明度
local ALPHA = 1
-- 是否展示动画
local ANIMATED = true
-- 动画时长
local ANIMATION_DURATION = 0.3
-- 是否允许按 tab 键进行选择
local TAB_TO_PICK = false

-- --------------------------------------------------
-- 菜单封装
-- --------------------------------------------------

local Ring = {}

-- 创建菜单
function Ring:new(config)
  local obj = {}
  setmetatable(obj, self)
  self.__index = self

  self._items = config.items
  self._ringSize = config.ringSize or 280
  self._ringThickness = config.ringThickness or self._ringSize / 4
  self._iconSize = config.iconSize or self._ringThickness / 2
  self._inactiveColor = config.inactiveColor or { hex = "#000000" }
  self._activeColor = config.activeColor or { hex = "#40534c" }
  self._alpha = config.alpha or 1
  self._animated = config.animated
  self._animationDuration = config.animationDuration or 0.3
  self._canvas = nil
  self._active = nil

  self._cancelAnimation = nil

  local halfRingSize = self._ringSize / 2
  local halfRingThickness = self._ringThickness / 2
  local pieceDeg = 360 / #self._items
  local halfPieceDeg = pieceDeg / 2
  local halfIconSize = self._iconSize / 2

  self._canvas = hs.canvas.new({
    x = 0,
    y = 0,
    w = self._ringSize,
    h = self._ringSize
  })
  self._canvas:level(hs.canvas.windowLevels.overlay)
  self._canvas:alpha(self._alpha)

  -- 渲染圆环
  self._canvas[1] = {
    type = 'arc',
    action = 'stroke',
    center = { x = '50%', y = '50%' },
    radius = halfRingSize - halfRingThickness,
    startAngle = 0,
    endAngle = 360,
    strokeWidth = self._ringThickness,
    strokeColor = self._inactiveColor,
    arcRadii = false
  }

  -- 渲染激活项高亮背景
  self._canvas[2] = {
    type = 'arc',
    action = 'stroke',
    center = { x = '50%', y = '50%' },
    radius = halfRingSize - halfRingThickness,
    startAngle = -halfPieceDeg,
    endAngle = halfPieceDeg,
    strokeWidth = self._ringThickness * 0.9,
    strokeColor = { alpha = 0 },
    arcRadii = false
  }

  -- 渲染 icon
  for key, app in ipairs(self._items) do
    local image = hs.image.imageFromPath(app.icon)
    local rad = math.rad(pieceDeg * (key - 1) - 90)

    local length = halfRingSize - halfRingThickness
    local x = length * math.cos(rad) + halfRingSize - halfIconSize
    local y = length * math.sin(rad) + halfRingSize - halfIconSize

    self._canvas[key + 2] = {
      type = "image",
      image = image,
      frame = { x = x , y = y, h = self._iconSize, w = self._iconSize }
    }
  end

  return obj
end

-- 显示菜单
function Ring:show()
  self._canvas:show()

  -- 根据配置决定是否开启动画
  if self._animated then
    local halfRingSize = self._ringSize / 2
    local matrix = hs.canvas.matrix.identity()

    self._cancelAnimation = utils.animate({
      duration = self._animationDuration,
      easing = tween.easeOutExpo,
      onProgress = function(progress)
        self._canvas:transformation(
          matrix
            :translate(halfRingSize, halfRingSize)
            :scale((0.1 * progress) + 0.9)
            :translate(-halfRingSize, -halfRingSize)
        )
        self._canvas:alpha(self._alpha * progress)
      end
    })
  end
end

-- 隐藏菜单
function Ring:hide()
  self._canvas:hide()

  if self._animated then
    self._cancelAnimation()
  end
end

-- 返回菜单是否显示
function Ring:isShowing()
  return self._canvas:isShowing()
end

-- 设置菜单激活项
function Ring:setActive(index)
  if self._active ~= index then
    self._active = index

    local pieceDeg = 360 / #self._items
    local halfPieceDeg = pieceDeg / 2
    local indicator = self._canvas[2]

    if (index) then
      indicator.startAngle = pieceDeg * (index - 1) - halfPieceDeg
      indicator.endAngle = pieceDeg * index - halfPieceDeg
      indicator.strokeColor = self._activeColor
    else
      indicator.strokeColor = { alpha = 0 }
    end
  end
end

-- 获取菜单激活项
function Ring:getActive()
  return self._active
end

-- 设置菜单坐标（指的是圆心坐标）
function Ring:setPosition(topLeft)
  self._canvas:topLeft({ x = topLeft.x - self._ringSize / 2, y = topLeft.y - self._ringSize / 2 })
end

-- --------------------------------------------------
-- 菜单调用以及事件监听处理
-- --------------------------------------------------

local ringPos = nil

local ring = Ring:new({
  items = APPLICATIONS,
  ringSize = RING_SIZE,
  ringThickness = RING_THICKNESS,
  iconSize = ICON_SIZE,
  inactiveColor = COLOR_PATTERN.inactive,
  activeColor = COLOR_PATTERN.active,
  alpha = ALPHA,
  animated = ANIMATED,
  animationDuration = ANIMATION_DURATION,
})

-- 处理鼠标移动事件
local function handleMouseMoved()
  local mousePos = hs.mouse.absolutePosition()

  -- 鼠标指针与中心点的距离
  local distance = math.sqrt(math.abs(mousePos.x - ringPos.x)^2 + math.abs(mousePos.y - ringPos.y)^2)
  local rad = math.atan2(mousePos.y - ringPos.y, mousePos.x - ringPos.x)
  local deg = math.deg(rad)
  -- 转为 0 - 360
  deg = (deg + 90 + 360 / #APPLICATIONS / 2) % 360

  local active = math.ceil(deg / (360 / #APPLICATIONS))
  -- 在中心空洞中不激活菜单
  if distance <= RING_SIZE / 2 - RING_THICKNESS then
    active = nil
  end

  ring:setActive(active)
end
-- 貌似也并没节省到性能，throttle 一下图心理安慰
local throttledHandleMouseMoved = utils.throttle(handleMouseMoved, 1 / 60)

-- 显示逻辑处理
local function handleShowRing()
  if ring:isShowing() then
    if (TAB_TO_PICK) then
      local active = ring:getActive()
      ring:setActive(active == nil and 1 or (active % #APPLICATIONS) + 1)
    end
    return
  end

  local frame = hs.mouse.getCurrentScreen():fullFrame()

  if FOLLOW_POINTER then
    local mousePos = hs.mouse.absolutePosition()
    ringPos = {
      x = utils.clamp(mousePos.x, frame.x + RING_SIZE / 2, frame.x + frame.w - RING_SIZE / 2),
      y = utils.clamp(mousePos.y, frame.y + RING_SIZE / 2, frame.y + frame.h - RING_SIZE / 2)
    }
  else
    ringPos = {
      x = (frame.x + frame.w) / 2,
      y = (frame.y + frame.h) / 2
    }
  end

  ring:setPosition(ringPos)
  ring:show()

  -- 菜单显示后开始监听鼠标移动事件
  ring_mouseEvtTap = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, throttledHandleMouseMoved)
  ring_mouseEvtTap:start()

  -- 初始化触发计算一次
  handleMouseMoved()
end

-- 隐藏逻辑处理
local function handleHideRing()
  if not ring:isShowing() then
    return
  end

  ring:hide()
  -- 菜单隐藏后移除监听鼠标移动事件
  ring_mouseEvtTap:stop()

  local active = ring:getActive()

  if active then
    local onActive = APPLICATIONS[active].onActive
    -- 如果菜单项中配置了 onActive，则执行自定义行为，否则作为程序打开
    if onActive then
      onActive()
    else
      hs.application.launchOrFocus(APPLICATIONS[ring:getActive()].name)
    end
  end
end

-- 处理按键事件
local function handleKeyEvent(event)
  local keyCode = event:getKeyCode()
  local type = event:getType()
  local isAltDown = event:getFlags().alt

  -- 按下了 alt + tab 后显示菜单
  if
    type == hs.eventtap.event.types.keyDown and
    keyCode == hs.keycodes.map.tab and
    isAltDown
  then
    handleShowRing()
    -- 阻止事件传递
    return true
  end

  -- 松开了 alt 后隐藏菜单
  if
    type == hs.eventtap.event.types.flagsChanged and
    keyCode == hs.keycodes.map.alt and
    not isAltDown
  then
    handleHideRing()
  end

  return false
end

-- 监听快捷键
ring_keyEvtTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged }, handleKeyEvent)
ring_keyEvtTap:start()
