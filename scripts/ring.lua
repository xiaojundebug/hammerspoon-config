-- **************************************************
-- 环形 app 启动器
-- **************************************************

local utils = require('./utils')

-- ---------- 自定义配置 ----------

-- 菜单项配置
local APPLICATIONS = {
  { name = 'QQ', icon = '/Applications/QQ.app/Contents/Resources/icon.icns' },
  { name = 'WeChat', icon = '/Applications/WeChat.app/Contents/Resources/AppIcon.icns' },
  { name = '企业微信', icon = '/Applications/企业微信.app/Contents/Resources/AppIcon.icns' },
  { name = 'Google Chrome', icon = '/Applications/Google Chrome.app/Contents/Resources/app.icns' },
  { name = 'Visual Studio Code', icon = '/Applications/Visual Studio Code.app/Contents/Resources/Code.icns' },
  { name = 'WebStorm', icon = '/Applications/WebStorm.app/Contents/Resources/webstorm.icns' },
}
-- 菜单圆环大小
local RING_SIZE = 280
-- 菜单圆环粗细
local RING_THICKNESS = RING_SIZE / 3.75
-- 图标大小
local ICON_SIZE = RING_THICKNESS / 2
-- 是否菜单在鼠标指针处弹出，而不是居中
local FOLLOW_MOUSE = true
-- 颜色配置
local COLOR_PATTERN = {
  inactive = { red = 0.1, green = 0.1, blue = 0.15, alpha = 0.95 },
  active = { hex = '#565584' }
}

-- ---------- 菜单封装 ----------

local Menu = {}

-- 创建菜单
function Menu:new(config)
  o = {}
  setmetatable(o, self)
  self.__index = self

  self._menus = config.menus
  self._ringSize = config.ringSize or 360
  self._ringThickness = config.ringThickness or self._ringSize / 3.75
  self._iconSize = config.iconSize or self._ringThickness / 2
  self._canvas = nil
  self._active = nil
  self._inactiveColor = config.inactiveColor or { hex = '#333333' }
  self._activeColor = config.activeColor or { hex = '#3b82f6' }

  local halfRingSize = self._ringSize / 2
  local halfRingThickness = self._ringThickness / 2
  local pieceDeg = 360 / #self._menus
  local halfPieceDeg = pieceDeg / 2
  local halfIconSize = self._iconSize / 2

  self._canvas = hs.canvas.new({
    x = config.left or 0,
    y = config.top or 0,
    w = self._ringSize,
    h = self._ringSize
  })
  self._canvas:level(hs.canvas.windowLevels.overlay)

  -- 渲染圆环
  local ring = {
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
  
  self._canvas[1] = ring

  -- 渲染激活项高亮背景
  local indicator = {
    type = 'arc',
    action = 'stroke',
    center = { x = '50%', y = '50%' },
    radius = halfRingSize - halfRingThickness,
    startAngle = -halfPieceDeg,
    endAngle = halfPieceDeg,
    strokeWidth = self._ringThickness - 6,
    strokeColor = self._activeColor,
    arcRadii = false
  }
  indicator.strokeColor.alpha = 0

  self._canvas[2] = indicator

  -- 渲染 icon
  for key, app in pairs(self._menus) do
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

  return o
end

-- 显示菜单
function Menu:show()
  self._canvas:show()
end

-- 隐藏菜单
function Menu:hide()
  self._canvas:hide()
end

-- 返回菜单是否显示
function Menu:isShowing()
  return self._canvas:isShowing()
end

-- 设置菜单激活项
function Menu:setActive(index)
  if self._active ~= index then
    self._active = index

    local pieceDeg = 360 / #self._menus
    local halfPieceDeg = pieceDeg / 2

    if (index) then
      self._canvas[2].startAngle = pieceDeg * (index - 1) - halfPieceDeg
      self._canvas[2].endAngle = pieceDeg * index - halfPieceDeg
      self._canvas[2].strokeColor.alpha = 1
    else
      self._canvas[2].strokeColor.alpha = 0
    end
  end
end

-- 获取菜单激活项
function Menu:getActive()
  return self._active
end

-- 设置菜单位置（这里指圆点 x、y 坐标）
function Menu:setPosition(topLeft)
  self._canvas:topLeft({ x = topLeft.x - self._ringSize / 2, y = topLeft.y - self._ringSize / 2 })
end

-- 获取菜单位置
function Menu:getPosition()
  return self._canvas:topLeft()
end

-- ---------- 逻辑处理 ----------

-- 保存菜单弹出时鼠标的位置
local menuPos = nil

local menu = Menu:new({
  menus = APPLICATIONS,
  ringSize = RING_SIZE,
  ringThickness = RING_THICKNESS,
  iconSize = ICON_SIZE,
  inactiveColor = COLOR_PATTERN.inactive,
  activeColor = COLOR_PATTERN.active,
})

-- 处理鼠标移动事件
local function handleMouseMoved()
  local mousePos = hs.mouse.absolutePosition()
  -- 鼠标指针与中心点的距离
  local distance = math.sqrt(math.abs(mousePos.x - menuPos.x)^2 + math.abs(mousePos.y - menuPos.y)^2)
  local rad = math.atan2(mousePos.y - menuPos.y, mousePos.x - menuPos.x)
  local deg = math.deg(rad)
  -- 转为 0 - 360
  deg = (deg + 90 + 360 / #APPLICATIONS / 2) % 360

  local active = math.ceil(deg / (360 / #APPLICATIONS))
  -- 在中心空洞中不激活菜单
  if distance <= RING_SIZE / 2 - RING_THICKNESS then
    active = nil
  end

  menu:setActive(active)
end

-- 处理显示菜单
local function handleShowMenu()
  if menu:isShowing() then
    return
  end

  local frame = hs.screen.primaryScreen():fullFrame()

  if FOLLOW_MOUSE then
    local mousePos = hs.mouse.absolutePosition()
    menuPos = {
      x = utils.clamp(mousePos.x, frame.x + RING_SIZE / 2, frame.x + frame.w - RING_SIZE / 2),
      y = utils.clamp(mousePos.y, frame.y + RING_SIZE / 2, frame.y + frame.h - RING_SIZE / 2)
    }
  else
    menuPos = {
      x = (frame.x + frame.w) / 2,
      y = (frame.y + frame.h) / 2
    }
  end
  menu:setPosition(menuPos)
  menu:show()
  -- 菜单显示后开始监听鼠标移动事件
  r_mouseEvtTap = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, handleMouseMoved)
  r_mouseEvtTap:start()
  -- 初始化触发计算一次
  handleMouseMoved()
end

-- 处理隐藏菜单
local function handleHideMenu()
  if not menu:isShowing() then
    return
  end
  
  -- 菜单隐藏后移除监听鼠标移动事件
  menu:hide()
  r_mouseEvtTap:stop()

  local active = menu:getActive()

  if active then
    local onActive = APPLICATIONS[active].onActive
    -- 如果菜单项中配置了 onActive，则执行自定义行为，否则作为程序打开
    if onActive then
      onActive()
    else
      hs.application.launchOrFocus(APPLICATIONS[menu:getActive()].name)
    end
  end
end

-- 处理按键事件
local function handleKeyEvent(event)
  -- 按下了 alt + tab 后显示菜单
  if event:getKeyCode() == 48 and event:getFlags().alt then
    if event:getType() == hs.eventtap.event.types.keyDown then
      handleShowMenu()
      return true
    end
    return false
  end

  -- 松开了 alt 后隐藏菜单
  if event:getKeyCode() == 58 then
    if event:getType() == hs.eventtap.event.types.flagsChanged then
      handleHideMenu()
    end
    return true
  end

  return false
end

-- 监听快捷键
r_keyEvtTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged }, handleKeyEvent)
r_keyEvtTap:start()
