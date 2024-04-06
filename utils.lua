local module = {}

function module.setTimeout(callback, delay)
  local timer = hs.timer.doAfter(delay, function()
    callback()
  end)

  timer:start()

  return function()
    timer:stop()
  end
end

function module.debounce(func, delay)
  local clearTimeout = nil

  return function(...)
    local args = { ... }

    if clearTimeout ~= nil then
      clearTimeout()
    end

    clearTimeout = module.setTimeout(function()
      func(table.unpack(args))
    end, delay)
  end
end

function module.clamp(value, min, max)
  return math.max(math.min(value, max), min)
end

return module
