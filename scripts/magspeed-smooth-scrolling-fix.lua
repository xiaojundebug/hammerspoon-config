
-- **************************************************
-- 罗技 MX Anywhere 3s 鼠标回滚问题尝试性优化
-- 可能对其他类似鼠标也有效果，如：罗技 MX Master 系列
-- ⚠️ 该脚本可能对性能有一定影响
-- **************************************************

-- 回滚场景：
-- 1. Logi Options+ 中开启了平滑滚动
-- 2. 即使使用棘轮模式（刻度模式），当手指放到滚轮上，也有概率会触发回滚

-- 原因分析：
-- 由于开启了平滑滚动，滚轮任何细粒度的滚动都会触发事件，
-- 这种情况下棘轮单纯是为了手感，棘轮刻度的粒度并不严格对应事件粒度，
-- 很可能棘轮刻度感还没触发，事件已经发射了好几次

-- 处理方案：
-- 简单来说，当鼠标滚轮事件触发时，判断一下滚动方向是不是发生了变化，
-- 只有在同一个方向上滚动到一定次数后，才认为是真的发生了预期滚动

-- 忽略在同一方向上的前几次事件
-- 这个次数不宜过高，否则会影响跟手性，一般来说设置 1～3 就可以规避掉大部分的误触
local REVERSE_THRESHOLD = 2

local prevEvtTime = 0
local prevDeltaY = 0
local scrollCount = 0

local function handleScrollWheel(event)
  local sourceGroupID = event:getProperty(hs.eventtap.event.properties.eventSourceGroupID)
  -- 不对内置触摸板进行处理，测试发现触摸板该值为 0，可以作为判定依据
  if sourceGroupID == 0 then
    return false
  end

  local deltaY = event:getProperty(hs.eventtap.event.properties.scrollWheelEventPointDeltaAxis1)
  local now = hs.timer.absoluteTime() / 1000000
  local isDirChanged = deltaY ~= 0 and deltaY * prevDeltaY <= 0
  local diffMs = now - prevEvtTime

  if isDirChanged or diffMs >= 100 then
    scrollCount = 0
    prevReverseTime = now
  else
    scrollCount = scrollCount + 1
  end

  prevEvtTime = now
  prevDeltaY = deltaY

  if scrollCount < REVERSE_THRESHOLD then
    return true
  end

  return false
end

mssf_wheelEvtTap = hs.eventtap.new({hs.eventtap.event.types.scrollWheel}, handleScrollWheel)
mssf_wheelEvtTap:start()
