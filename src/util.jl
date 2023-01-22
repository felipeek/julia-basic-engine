# Convert window coords to NDC (from [0, WinWidth],[0, WinHeight] to [-1, 1])
function WindowNormalizeCoordsToNdc(x::Real, y::Real, windowWidth::Integer, windowHeight::Integer)::Tuple{Real, Real}
	y = windowHeight - y
	x = (2 * x) / windowWidth - 1
	y = (2 * y) / windowHeight - 1

	return x, y
end

function ViewportBasedOnWindowSize(x::Integer, y::Integer, width::Integer, height::Integer)
	if Sys.isapple()
		# When apple retina displays are used, the window size reported by GLFW is half the size of the framebuffer
		glViewport(x, y, 2 * width, 2 * height)
	else
		glViewport(x, y, width, height)
	end
end

function ViewportBasedOnFramebufferSize(x::Integer, y::Integer, width::Integer, height::Integer)
	glViewport(x, y, width, height)
end