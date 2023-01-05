# Map one range into another, i.e., map [a1, a2] into [b1, b2].
# Receives a value 's' in [a1, a2] and returns the same value in [b1, b2], considering a linear mapping
function MapRange(a1::Real, a2::Real, b1::Real, b2::Real, s::Real)::Real
	return b1 + ((s - a1) * (b2 - b1))/(a2 - a1)
end

function MapRange(a1::Real, a2::Real, b1::Real, b2::Real, s::Vec2)::Vec2
	x = b1 + ((s.x - a1) * (b2 - b1))/(a2 - a1)
	y = b1 + ((s.y - a1) * (b2 - b1))/(a2 - a1)
	return Vec2(x, y)
end