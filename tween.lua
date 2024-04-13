local module = {}

function module.easeOutQuint(t)
  return 1 - math.pow(1 - t, 5);
end

return module
