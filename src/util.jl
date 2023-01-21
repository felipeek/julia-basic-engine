# Convert window coords to NDC (from [0, WinWidth],[0, WinHeight] to [-1, 1])
function WindowNormalizeCoordsToNdc(x::Real, y::Real, windowWidth::Integer, windowHeight::Integer)::Tuple{Real, Real}
	y = windowHeight - y
	x = (2 * x) / windowWidth - 1
	y = (2 * y) / windowHeight - 1

	return x, y
end

# Get mouse's click position and direction vector in World Coordinates
# Inputs:
# camera - camera to consider
# mouseX, mouseY - mouse coordinates in range [0, WindowWidth] and [0, WindowHeight]
# Outputs:
# Position: Click position in world coords
# Direction: Direction vector in world coords
function MouseGetRayWorldCoords(camera::Camera, mouseX::Real, mouseY::Real, windowWidth::Integer, windowHeight::Integer)::Tuple{Vec3, Vec3}
	x, y = WindowNormalizeCoordsToNdc(mouseX, mouseY, windowWidth, windowHeight)

	projMatrix = CameraGetProjectionMatrix(camera)
	viewMatrix = CameraGetViewMatrix(camera)
	invProjMatrix = inv(projMatrix)
	invViewMatrix = inv(viewMatrix)

	# Get the exact point that the user clicked on. This point is in NDC coordinates (i.e. "projection coordinates").
	# We are picking the point that is in the closest plane to the screen (i.e., the plane z = -1.0)
	# Note that this is a point, not a vector.
	rayClipNdcCoords = Vec4(x, y, -1, 1)

	# Transform the point back to view coordinates.
	rayClipViewCoords = invProjMatrix * rayClipNdcCoords
	rayClipViewCoords = (1 / rayClipViewCoords[4]) * rayClipViewCoords

	# Get vector from camera origin to point, in view coordinates.
	# Note that we are in view coordinates, so the origin is always <0,0,0,1>.
	# Therefore, performing the subtraction "ray - origin" is the same as making the w coord 0.
	rayEyeViewCoords = Vec4(rayClipViewCoords[1], rayClipViewCoords[2], rayClipViewCoords[3], 0.0)

	# Transform ray vector from view coords to world coords.
	rayEyeWorldCoords = normalize(invViewMatrix * rayEyeViewCoords)

	return CameraGetPosition(camera), Vec3(rayEyeWorldCoords[1], rayEyeWorldCoords[2], rayEyeWorldCoords[3])
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