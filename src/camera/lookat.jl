mutable struct LookAtCamera <: Camera
	position::Vec3
	nearPlane::Real
	farPlane::Real
	fov::Real
	viewMatrix::Matrix
	projectionMatrix::Matrix
	rotation::Quaternion

	lookAtPosition::Vec3
	lookAtDistance::Real
	rotateRoll::Bool

	zoomSpeed::Real
	rotationSpeed::Real
	panningSpeed::Real
end

function LookAtCamera(lookAtPosition::Vec3, lookAtDistance::Real, nearPlane::Real, farPlane::Real, fov::Real, windowWidth::Integer,
		windowHeight::Integer, rotateRoll::Bool, zoomSpeed::Real, rotationSpeed::Real, panningSpeed::Real)::LookAtCamera
	cameraView = Vec3(0, 0, -1)
	position = lookAtPosition - lookAtDistance * normalize(cameraView)
	rotation = Quaternion(0, 0, 0, 1)
	camera = LookAtCamera(position, nearPlane, farPlane, fov, zeros(4, 4), zeros(4, 4), rotation, lookAtPosition, lookAtDistance, rotateRoll,
		zoomSpeed, rotationSpeed, panningSpeed)
	RecalculateViewMatrix(camera)
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
	return camera
end

function CameraGetPosition(camera::LookAtCamera)::Vec3
	return camera.position
end

function CameraGetViewMatrix(camera::LookAtCamera)::Matrix
	return camera.viewMatrix
end

function CameraGetProjectionMatrix(camera::LookAtCamera)::Matrix
	return camera.projectionMatrix
end

function CameraGetView(camera::LookAtCamera)::Vec3
	cameraViewMatrix = camera.viewMatrix
	cameraView = Vec3(-cameraViewMatrix[3, 1], -cameraViewMatrix[3, 2], -cameraViewMatrix[3, 3])
	return normalize(cameraView);
end

function CameraGetXAxis(camera::LookAtCamera)::Vec3
	q = camera.rotation
	right = QuaternionGetRightInverted(q)
	right = normalize(right)
	return Vec3(right.x, right.y, right.z)
end

function CameraGetYAxis(camera::LookAtCamera)::Vec3
	q = camera.rotation
	up = QuaternionGetUpInverted(q)
	up = normalize(up)
	return Vec3(up.x, up.y, up.z)
end

function CameraGetZAxis(camera::LookAtCamera)::Vec3
	q = camera.rotation
	forward = QuaternionGetForwardInverted(q)
	forward = normalize(forward)
	return Vec3(forward.x, forward.y, forward.z)
end

function CameraSetPosition(camera::LookAtCamera, position::Vec3)
	camera.position = position
	RecalculateViewMatrix(camera)
end

function CameraSetNearPlane(camera::LookAtCamera, nearPlane::Real, windowWidth::Integer, windowHeight::Integer)
	camera.nearPlane = nearPlane
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
end

function CameraSetFarPlane(camera::LookAtCamera, farPlane::Real, windowWidth::Integer, windowHeight::Integer)
	camera.farPlane = farPlane
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
end

function CameraRotateXConsideringClickCoords(camera::LookAtCamera, xDifference::Real, mouseY::Real)
	# If the user clicked on the top (or bottom) of the screen, we also consider the Z axis.
	axis = mouseY * Vec3(0.0, 0.0, 1.0) + (1 - abs(mouseY)) * Vec3(0.0, 1.0, 0.0)
	CameraRotateAxis(camera, xDifference, axis)
end

function CameraRotateYConsideringClickCoords(camera::LookAtCamera, yDifference::Real, mouseX::Real)
	# If the user clicked on the right (or left) of the screen, we also consider the Z axis.
	axis = mouseX * Vec3(0.0, 0.0, 1.0) + (1 - abs(mouseX)) * Vec3(1.0, 0.0, 0.0)
	CameraRotateAxis(camera, yDifference, axis)
end

function CameraRotateX(camera::LookAtCamera, xDifference::Real)
	CameraRotateAxis(camera, xDifference, Vec3(0.0, 1.0, 0.0))
end

function CameraRotateY(camera::LookAtCamera, yDifference::Real)
	CameraRotateAxis(camera, yDifference, Vec3(1.0, 0.0, 0.0))
end

function CameraRotateAxis(camera::LookAtCamera, angle::Real, axis::Vec3)
	axis = QuaternionNew(axis, angle * camera.rotationSpeed)
	camera.rotation = QuaternionNormalize(axis * camera.rotation)
	RecalculateViewMatrix(camera)
end

function CameraRotate(camera::LookAtCamera, xDiff::Real, yDiff::Real, mouseX::Real, mouseY::Real)
	if camera.rotateRoll
		CameraRotateXConsideringClickCoords(camera, xDiff, -mouseY)
		CameraRotateYConsideringClickCoords(camera, yDiff, -mouseX)
	else
		CameraRotateX(camera, xDiff)
		CameraRotateY(camera, yDiff)
	end

	cameraView = CameraGetView(camera)
	camera.position = camera.lookAtPosition - camera.lookAtDistance * cameraView
	RecalculateViewMatrix(camera)
end

function CameraMoveForward(camera::LookAtCamera, amount::Real)
	q = camera.rotation

	forward = QuaternionGetForwardInverted(q)
	forward = amount * normalize(forward)
	camera.position = Vec3(-forward.x, -forward.y, -forward.z) + camera.position

	RecalculateViewMatrix(camera)
end

function CameraMoveRight(camera::LookAtCamera, amount::Real)
	q = camera.rotation

	right = QuaternionGetRightInverted(q)
	right = amount * normalize(right)
	camera.position = Vec3(right.x, right.y, right.z) + camera.position

	RecalculateViewMatrix(camera)
end

function CameraSetFov(camera::LookAtCamera, fov::Real, windowWidth::Integer, windowHeight::Integer)
	camera.fov = fov
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
end

function CameraForceMatrixRecalculation(camera::LookAtCamera, windowWidth::Integer, windowHeight::Integer)
	RecalculateViewMatrix(camera)
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
end

function RecalculateViewMatrix(camera::LookAtCamera)
	trans = [
		1 0 0 -camera.position.x
		0 1 0 -camera.position.y
		0 0 1 -camera.position.z
		0 0 0 1
	]

	f = camera.rotation

	rotation = QuaternionGetMatrix(f)
	camera.viewMatrix = rotation * trans
end

function RecalculateProjectionMatrix(camera::LookAtCamera, windowWidth::Integer, windowHeight::Integer)
	near = camera.nearPlane
	far = camera.farPlane
	top = abs(near) * atan(deg2rad(camera.fov) / 2.0)
	bottom = -top
	right = top * (windowWidth / windowHeight)
	left = -right

	p = [
		near 0 0 0
		0 near 0 0
		0 0 (near + far) (-near * far)
		0 0 1 0
	]

	m = [
		(2.0 / (right - left)) 0 0 (-(right + left) / (right - left))
		0 (2.0 / (top - bottom)) 0 (-(top + bottom) / (top - bottom))
		0 0 (2.0 / (far - near)) (-(far + near) / (far - near))
		0 0 0 1
	]

	mp = m * p
	camera.projectionMatrix = -mp
end

# Look At Camera specific functions

function LookAtCameraGetLookAtDistance(camera::LookAtCamera)
	return camera.lookAtDistance
end

function LookAtCameraGetLookAtPosition(camera::LookAtCamera)
	return camera.lookAtPosition
end

function LookAtCameraSetLookAtPosition(camera::LookAtCamera, lookAtPosition::Vec3)
	camera.lookAtPosition = lookAtPosition
	cameraView = CameraGetView(camera)
	camera.position = camera.lookAtPosition - camera.lookAtDistance * cameraView
	RecalculateViewMatrix(camera)
end

function LookAtCameraSetLookAtDistance(camera::LookAtCamera, lookAtDistance::Real)
	camera.lookAtDistance = lookAtDistance;

	cameraView = CameraGetView(camera)
	camera.position = camera.lookAtPosition - camera.lookAtDistance * cameraView
	RecalculateViewMatrix(camera)
end

function LookAtCameraPan(camera::LookAtCamera, xDiff::Real, yDiff::Real)
	yAxis = CameraGetYAxis(camera)
	inc = camera.panningSpeed * camera.lookAtDistance * yDiff * yAxis
	LookAtCameraSetLookAtPosition(camera, camera.lookAtPosition + inc)

	xAxis = CameraGetXAxis(camera)
	inc = -camera.panningSpeed * camera.lookAtDistance * xDiff * xAxis
	LookAtCameraSetLookAtPosition(camera, camera.lookAtPosition + inc)
end

function LookAtCameraApproximate(camera::LookAtCamera, yOffset::Real)
	LookAtCameraSetLookAtDistance(camera, camera.lookAtDistance - yOffset * camera.zoomSpeed)
end