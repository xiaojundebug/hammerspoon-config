-- **************************************************
-- 环形 app 启动器
-- **************************************************

-- 菜单项配置
local APPLICATIONS = {
  { name = 'QQ', icon = '/Applications/QQ.app/Contents/Resources/icon.icns' },
  { name = 'WeChat', icon = '/Applications/WeChat.app/Contents/Resources/AppIcon.icns' },
  { name = 'Google Chrome', icon = '/Applications/Google Chrome.app/Contents/Resources/app.icns' },
  { name = 'Visual Studio Code', icon = '/Applications/Visual Studio Code.app/Contents/Resources/Code.icns' },
  { name = 'WebStorm', icon = '/Applications/WebStorm.app/Contents/Resources/webstorm.icns' },
}
-- 预设主题
local PRESET_COLOR_PATTERN = {
  lime = {
    inactive = { red = 0.1, green = 0.12, blue = 0.1, alpha = 0.95 },
    active = { hex = '#4d7c0f' }
  },
  lavender = {
    inactive = { red = 0.1, green = 0.1, blue = 0.15, alpha = 0.95 },
    active = { hex = '#565584' }
  },
  blue = {
    inactive = { red = 0.1, green = 0.1, blue = 0.15, alpha = 0.95 },
    active = { hex = '#0369a1' }
  },
  white = {
    inactive = { red = 0.8, green = 0.8, blue = 0.8, alpha = 0.95 },
    active = { hex = '#ffffff' }
  },
  black = {
    inactive = { red = 0.1, green = 0.1, blue = 0.1, alpha = 0.95 },
    active = { hex = '#444444' }
  },
  tahiti = {
    inactive = { red = 0.1, green = 0.13, blue = 0.15, alpha = 0.95 },
    active = { hex = '#3ab7bf' }
  },
}
-- 菜单大小
local SIZE = 300
-- 菜单圆环粗细
local THICKNESS = SIZE / 3.75
-- 颜色配置
local COLOR_PATTERN = PRESET_COLOR_PATTERN.lavender
-- 图标大小
local ICON_SIZE = THICKNESS / 2

-- ***** Menu 封装（后续考虑抽离为 Spoon） *****
local Menu = {}

-- 创建菜单
function Menu:new(config)
  o = {}
  setmetatable(o, self)
  self.__index = self

  self.apps = config.apps
  self.size = config.size or 360
  self.thickness = config.thickness or 96
  self.iconSize = config.iconSize or self.thickness / 2
  self.canvas = nil
  self.active = nil
  self.inactiveColor = config.inactiveColor or { hex = '#333333' }
  self.activeColor = config.activeColor or { hex = '#3b82f6' }

  local screenFrame = hs.screen.primaryScreen():fullFrame()
  local halfScreenW = screenFrame.w / 2
  local halfScreenH = screenFrame.h / 2
  local halfSize = self.size / 2
  local halfThickness = self.thickness / 2
  local pieceDeg = 360 / #self.apps
  local halfPieceDeg = pieceDeg / 2
  local halfIconSize = self.iconSize / 2

  self.canvas = hs.canvas.new({
    x = screenFrame.x + halfScreenW - halfSize,
    y = screenFrame.y + halfScreenH - halfSize,
    w = self.size,
    h = self.size
  })

  -- 渲染圆环
  local ring = {
    type = 'arc',
    action = 'stroke',
    center = { x = '50%', y = '50%' },
    radius = halfSize - halfThickness,
    startAngle = 0,
    endAngle = 360,
    strokeWidth = self.thickness,
    strokeColor = self.inactiveColor,
    arcRadii = false,
  }
  
  self.canvas[1] = ring

  -- 渲染激活项高亮背景
  local indicator = {
    type = 'arc',
    action = 'stroke',
    center = { x = '50%', y = '50%' },
    radius = halfSize - halfThickness,
    startAngle = -halfPieceDeg,
    endAngle = halfPieceDeg,
    strokeWidth = self.thickness - 6,
    strokeColor = self.activeColor,
    arcRadii = false,
    -- strokeCapStyle = 'round',
  }
  indicator.strokeColor.alpha = 0

  self.canvas[2] = indicator

  -- 渲染 icon
  for key, app in pairs(self.apps) do
    local image = hs.image.imageFromPath(app.icon)
    local rad = math.rad(pieceDeg * (key - 1) - 90)

    local length = halfSize - halfThickness
    local x = length * math.cos(rad) + halfSize - halfIconSize
    local y = length * math.sin(rad) + halfSize - halfIconSize

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

    local pieceDeg = 360 / #self.apps
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
-- ***** Menu 封装结束 *****

local menu = Menu:new({
  apps = APPLICATIONS,
  size = SIZE,
  thickness = THICKNESS,
  iconSize = ICON_SIZE,
  inactiveColor = COLOR_PATTERN.inactive,
  activeColor = COLOR_PATTERN.active
})

-- 处理鼠标移动事件
local function handleMouseMoved()
  local mousePos = hs.mouse.absolutePosition()
  local screenFrame = hs.screen.primaryScreen():fullFrame()
  local centerX = screenFrame.w / 2
  local centerY = screenFrame.h / 2
  -- 鼠标指针与中心点的距离
  local distance = math.sqrt(math.abs(mousePos.x - centerX)^2 + math.abs(mousePos.y - centerY)^2)
  local rad = math.atan2(mousePos.y - centerY, mousePos.x - centerX)
  local deg = math.deg(rad)
  -- 转为 0 - 360
  deg = (deg + 90 + 360 / #APPLICATIONS / 2) % 360

  local active = math.ceil(deg / (360 / #APPLICATIONS))
  -- 在中心空洞中不激活菜单
  if distance <= SIZE / 2 - THICKNESS then
    active = nil
  end

  menu:setActive(active)
end

-- 处理按键事件
local function handleKeyEvent(event)
  local isShowing = menu:isShowing()

  -- 按下了 alt + tab 后显示菜单
  if event:getKeyCode() == 48 and event:getFlags().alt then
    if event:getType() == hs.eventtap.event.types.keyDown then
      if not isShowing then
        -- 初始化触发计算一次
        handleMouseMoved()
        menu:show()
        -- 菜单显示后开始监听鼠标移动事件
        r_mouseEvtTap = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, handleMouseMoved)
        r_mouseEvtTap:start()
      end
      return true
    end
  end

  -- 松开了 alt 后隐藏菜单
  if event:getKeyCode() == 58 then
    if event:getType() == hs.eventtap.event.types.flagsChanged then
      if isShowing then
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
    end
  end

  return false
end

-- 监听快捷键
r_keyEvtTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged }, handleKeyEvent)
r_keyEvtTap:start()

