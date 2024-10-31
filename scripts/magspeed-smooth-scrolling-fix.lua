-- **************************************************
-- 罗技 MX Anywhere 3S 鼠标回滚问题优化
-- **************************************************
-- 该脚本可能对罗技 MX Master 系列这种同样带无极滚动功能的鼠标也有效
-- 该脚本对性能有一丢丢影响

-- ## 触发场景
-- 在 Logi Options+ 中开启了平滑滚动的情况下，即便使用棘轮模式（刻度模式），
-- 每当手指放到滚轮上，或者手指从滚轮上拿开时也有概率会触发回滚

-- ## 原因分析
-- 由于开启了平滑滚动，滚轮任何细粒度的滚动都会触发事件，
-- 这种情况下棘轮单纯是为了手感，棘轮刻度的粒度并不严格对应事件粒度，
-- 很可能棘轮刻度感还没触发，事件已经发射了好几次

-- ## 处理方案
-- 简单来说，当鼠标滚轮事件触发时，判断一下滚动方向是不是发生了变化，
-- 只有在同一个方向上滚动到一定次数后，才认为是真的发生了预期滚动
-- **************************************************

-- --------------------------------------------------
-- 防抖阈值，意味着在同方向上滚动超过设定次数后才会生效，
-- 这个值不宜过高，否则会影响跟手性，一般来说设置 1～3 就可以规避掉大部分的误触
local REVERSE_THRESHOLD = 2
-- 两次滚动事件的间隔时间在多少毫秒之内认为是连续滚动，超过后需重新防抖（即使滚动方向没变），
-- 不要设置太短，否则影响滚动连续性，保持默认值最好
local TIMEOUT_THRESHOLD = 300
-- --------------------------------------------------

local lastDeltaY = 0
local lastDeltaX = 0
local lastEvtTime = 0
local stableCount = 0

local function handleScrollWheel(event)
  local sourceGroupID = event:getProperty(hs.eventtap.event.properties.eventSourceGroupID)
  local deltaY = event:getProperty(hs.eventtap.event.properties.scrollWheelEventPointDeltaAxis1)
  local deltaX = event:getProperty(hs.eventtap.event.properties.scrollWheelEventPointDeltaAxis2)

  -- 不对内置触摸板进行处理，测试发现触摸板该值为 0，可以作为判定依据
  if sourceGroupID == 0 or (deltaY == 0 and deltaX == 0) then
    return false
  end

  local isDirChangedY = deltaY ~= 0 and deltaY * lastDeltaY <= 0
  local isDirChangedX = deltaX ~= 0 and deltaX * lastDeltaX <= 0
  local evtTime = event:timestamp() / 1000000
  local diffMs = evtTime - lastEvtTime

  -- 滚动方向发生变化或两次滚动的间隔时间过长，重新开始防抖
  if isDirChangedY or isDirChangedX or diffMs > TIMEOUT_THRESHOLD then
    stableCount = 0
  else
    stableCount = stableCount + 1
  end

  lastDeltaY = deltaY
  lastDeltaX = deltaX
  lastEvtTime = evtTime

  -- 未达到防抖阈值，阻止本次事件
  if stableCount < REVERSE_THRESHOLD then
    return true
  end

  return false
end

mssf_wheelEvtTap = hs.eventtap.new({ hs.eventtap.event.types.scrollWheel }, handleScrollWheel)
mssf_wheelEvtTap:start()
