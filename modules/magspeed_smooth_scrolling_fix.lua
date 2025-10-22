-- **************************************************
-- 罗技 MX Anywhere 3S 滚轮回滚问题优化
-- **************************************************
-- 适用于 MX Master 等具备无极滚动的鼠标
-- 该脚本对性能有一丢丢影响

-- ## 问题背景
-- 在 Logi Options+ 开启平滑滚动后，即便处于棘轮模式，
-- 轻触或离开滚轮时也可能会误触发滚动事件

-- ## 原因分析
-- 平滑滚动使得微小的滚动动作也会产生多个事件，
-- 棘轮反馈的刻度感与事件粒度不再对应，
-- 很可能棘轮刻度感还没触发，事件已经发射了好几次

-- ## 处理思路
-- 只有在同方向上连续滚动达到一定次数后，
-- 才认为是用户有意的滚动行为
-- **************************************************

-- --------------------------------------------------
-- 防抖阈值，意味着在同方向上滚动超过设定次数后才会生效，
-- 这个值不宜过高，否则会影响跟手性，一般来说设置 1 ～ 3 就可以规避掉大部分的误触
local SCROLL_STABLE_COUNT_THRESHOLD = 2
-- 两次滚动事件的间隔时间在多少毫秒之内认为是连续滚动，超过后需重新防抖（即使滚动方向没变），
-- 不要设置太短，否则影响滚动连续性，保持默认值最好
local SCROLL_CONTINUOUS_TIMEOUT = 300
-- --------------------------------------------------

local lastDeltaY = 0
local lastDeltaX = 0
local lastEvtTime = 0
local stableCount = 0

local function handleScrollWheel(event)
  local sourceGroupID = event:getProperty(hs.eventtap.event.properties.eventSourceGroupID)
  local deltaY = event:getProperty(hs.eventtap.event.properties.scrollWheelEventPointDeltaAxis1)
  local deltaX = event:getProperty(hs.eventtap.event.properties.scrollWheelEventPointDeltaAxis2)

  -- 不对内置触摸板进行处理，经测试发现触摸板 sourceGroupID 为 0，可以作为判定依据
  if sourceGroupID == 0 or (deltaY == 0 and deltaX == 0) then
    return false
  end

  local isDirChangedY = deltaY ~= 0 and deltaY * lastDeltaY <= 0
  local isDirChangedX = deltaX ~= 0 and deltaX * lastDeltaX <= 0
  local evtTime = event:timestamp() / 1000000
  local diffMs = evtTime - lastEvtTime

  -- 滚动方向发生变化或两次滚动的间隔时间过长，重新开始防抖
  if isDirChangedY or isDirChangedX or diffMs > SCROLL_CONTINUOUS_TIMEOUT then
    stableCount = 0
  else
    stableCount = stableCount + 1
  end

  lastDeltaY = deltaY
  lastDeltaX = deltaX
  lastEvtTime = evtTime

  -- 未达到防抖阈值，阻止本次事件
  if stableCount < SCROLL_STABLE_COUNT_THRESHOLD then
    return true
  end

  return false
end

mssf_wheelEvtTap = hs.eventtap.new({ hs.eventtap.event.types.scrollWheel }, handleScrollWheel)
mssf_wheelEvtTap:start()
