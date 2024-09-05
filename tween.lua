local module = {}

function module.easeOutExpo(t)
  return t == 1 and 1 or 1 - math.pow(2, -10 * t)
end

return module
