local module = {}

function module.debounce(func, delay)
  local timer = nil

  return function(...)
    local args = { ... }

    if timer ~= nil then
      timer:stop()
      timer = nil
    end

    timer = hs.timer.doAfter(delay, function()
      func(table.unpack(args))
    end)
  end
end

function module.throttle(func, delay)
  local wait = false
  local storedArgs = nil

  function checkStoredArgs()
    if storedArgs == nil then
      wait = false
    else
      func(table.unpack(storedArgs))
      storedArgs = nil
      hs.timer.doAfter(delay, checkStoredArgs)
    end
  end

  return function(...)
    local args = { ... }

    if wait then
      storedArgs = args
      return
    end

    func(table.unpack(args))
    wait = true
    hs.timer.doAfter(delay, checkStoredArgs)
  end
end

function module.clamp(value, min, max)
  return math.max(math.min(value, max), min)
end

return module
