# Convert window coords to NDC (from [0, WinWidth],[0, WinHeight] to [-1, 1])
function WindowNormalizeCoordsToNdc(x::Real, y::Real, windowWidth::Integer, windowHeight::Integer)::Tuple{Real, Real}
	y = windowHeight - y
	x = (2 * x) / windowWidth - 1
	y = (2 * y) / windowHeight - 1

	return x, y
end