local Tween = {}

function Tween.easeOutExpo(t)
  return t == 1 and 1 or 1 - math.pow(2, -10 * t)
end

return Tween
