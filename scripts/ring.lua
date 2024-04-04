-- **************************************************
-- 环形 app 启动器
-- **************************************************

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
local RING_SIZE = 300
-- 菜单圆环粗细
local RING_THICKNESS = RING_SIZE / 3.75
-- 颜色配置
local COLOR_PATTERN = {
  inactive = { red = 0.1, green = 0.1, blue = 0.15, alpha = 0.95 },
  active = { hex = '#565584' }
}
-- 图标大小
local ICON_SIZE = RING_THICKNESS / 2
-- 是否菜单在鼠标指针处弹出，而不是居中
local FOLLOW_MOUSE = true

-- ---------- 菜单封装 ----------

local Menu = {}

-- 创建菜单
function Menu:new(config)
  o = {}
  setmetatable(o, self)
  self.__index = self

  self.menus = config.menus
  self.ringSize = config.ringSize or 360
  self.ringThickness = config.ringThickness or 96
  self.iconSize = config.iconSize or self.ringThickness / 2
  self.canvas = nil
  self.active = nil
  self.inactiveColor = config.inactiveColor or { hex = '#333333' }
  self.activeColor = config.activeColor or { hex = '#3b82f6' }

  local screenFrame = hs.screen.primaryScreen():fullFrame()
  local halfScreenW = screenFrame.w / 2
  local halfScreenH = screenFrame.h / 2
  local halfRingSize = self.ringSize / 2
  local halfRingThickness = self.ringThickness / 2
  local pieceDeg = 360 / #self.menus
  local halfPieceDeg = pieceDeg / 2
  local halfIconSize = self.iconSize / 2

  self.canvas = hs.canvas.new({
    x = screenFrame.x + halfScreenW - halfRingSize,
    y = screenFrame.y + halfScreenH - halfRingSize,
    w = self.ringSize,
    h = self.ringSize
  })

  -- 渲染圆环
  local ring = {
    type = 'arc',
    action = 'stroke',
    center = { x = '50%', y = '50%' },
    radius = halfRingSize - halfRingThickness,
    startAngle = 0,
    endAngle = 360,
    strokeWidth = self.ringThickness,
    strokeColor = self.inactiveColor,
    arcRadii = false,
  }
  
  self.canvas[1] = ring

  -- 渲染激活项高亮背景
  local indicator = {
    type = 'arc',
    action = 'stroke',
    center = { x = '50%', y = '50%' },
    radius = halfRingSize - halfRingThickness,
    startAngle = -halfPieceDeg,
    endAngle = halfPieceDeg,
    strokeWidth = self.ringThickness - 6,
    strokeColor = self.activeColor,
    arcRadii = false,
    -- strokeCapStyle = 'round',
  }
  indicator.strokeColor.alpha = 0

  self.canvas[2] = indicator

  -- 渲染 icon
  for key, app in pairs(self.menus) do
    local image = hs.image.imageFromPath(app.icon)
    local rad = math.rad(pieceDeg * (key - 1) - 90)

    local length = halfRingSize - halfRingThickness
    local x = length * math.cos(rad) + halfRingSize - halfIconSize
    local y = length * math.sin(rad) + halfRingSize - halfIconSize

    self.canvas[key + 2] = {
      type = "image",
      image = image,
      frame = { x = x , y = y, h = self.iconSize, w = self.iconSize }
    }
  end

  self.canvas:level(hs.canvas.windowLevels.overlay)

  return o
end

-- 显示菜单
function Menu:show()
  self.canvas:show(0.1)
end

-- 隐藏菜单
function Menu:hide()
  self.canvas:hide(0.1)
end

-- 返回菜单是否显示
function Menu:isShowing()
  return self.canvas:isShowing()
end

-- 设置菜单激活项
function Menu:setActive(index)
  if self.active ~= index then
    self.active = index

    local pieceDeg = 360 / #self.menus
    local halfPieceDeg = pieceDeg / 2

    if (index) then
      self.canvas[2].startAngle = pieceDeg * (index - 1) - halfPieceDeg
      self.canvas[2].endAngle = pieceDeg * index - halfPieceDeg
      self.canvas[2].strokeColor.alpha = 1
    else
      self.canvas[2].strokeColor.alpha = 0
    end
  end
end

-- 获取菜单激活项
function Menu:getActive()
  return self.active
end

-- 设置菜单位置
function Menu:setPosition(topLeft)
  self.canvas:topLeft({ x = topLeft.x - self.ringSize / 2, y = topLeft.y - self.ringSize / 2 })
end

-- 获取菜单位置
function Menu:getPosition()
  return self.canvas:topLeft()
end

-- ---------- 逻辑处理 ----------

local menu = Menu:new({
  menus = APPLICATIONS,
  ringSize = RING_SIZE,
  ringThickness = RING_THICKNESS,
  iconSize = ICON_SIZE,
  inactiveColor = COLOR_PATTERN.inactive,
  activeColor = COLOR_PATTERN.active
})

-- 保存菜单弹出时鼠标的位置
local menuPos = nil

-- 处理鼠标移动事件
local function handleMouseMoved()
  local mousePos = hs.mouse.absolutePosition()
  local centerX = nil
  local centerY = nil

  if FOLLOW_MOUSE then
    centerX = menuPos.x
    centerY = menuPos.y
  else
    local screenFrame = hs.screen.primaryScreen():fullFrame()
    centerX = screenFrame.w / 2
    centerY = screenFrame.h / 2
  end

  -- 鼠标指针与中心点的距离
  local distance = math.sqrt(math.abs(mousePos.x - centerX)^2 + math.abs(mousePos.y - centerY)^2)
  local rad = math.atan2(mousePos.y - centerY, mousePos.x - centerX)
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

  if FOLLOW_MOUSE then
    menuPos = hs.mouse.absolutePosition()
    menu:setPosition(menuPos)
  end
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

