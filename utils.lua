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
  local cancelTimeout = nil

  return function(...)
    local args = {...}

    if cancelTimeout ~= nil then
      cancelTimeout()
    end

    cancelTimeout = module.setTimeout(function()
      func(table.unpack(args))
    end, delay)
  end
end

return module
