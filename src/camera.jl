abstract type Camera end

mutable struct PerspectiveCamera <: Camera
	position::Vec3
	nearPlane::Real
	farPlane::Real
	fov::Real
	viewMatrix::Matrix
	projectionMatrix::Matrix
	rotation::Quaternion
	yRotation::Quaternion
end

mutable struct LookAtCamera <: Camera
	position::Vec3
	nearPlane::Real
	farPlane::Real
	fov::Real
	viewMatrix::Matrix
	projectionMatrix::Matrix
	rotation::Quaternion
	yRotation::Quaternion

	lookAtPosition::Vec3
	lookAtDistance::Real
end

function PerspectiveCamera(position::Vec3, nearPlane::Real, farPlane::Real, fov::Real, windowWidth::Integer, windowHeight::Integer)::PerspectiveCamera
	rotation = Quaternion(0, 0, 0, 1)
	yRotation = Quaternion(0, 0, 0, 1)
	camera = PerspectiveCamera(position, nearPlane, farPlane, fov, zeros(4, 4), zeros(4, 4), rotation, yRotation)
	RecalculateViewMatrix(camera)
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
	return camera
end

function CameraGetPosition(camera::Camera)::Vec3
	return camera.position
end

function CameraSetPosition(camera::Camera, position::Vec3)
	camera.position = position
	RecalculateViewMatrix(camera)
end

function CameraSetNearPlane(camera::Camera, nearPlane::Real, windowWidth::Integer, windowHeight::Integer)
	camera.nearPlane = nearPlane
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
end

function CameraSetFarPlane(camera::Camera, farPlane::Real, windowWidth::Integer, windowHeight::Integer)
	camera.farPlane = farPlane
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
end

function CameraRotateX(camera::Camera, xDifference::Real)
	yAxis = QuaternionNew(Vec3(0.0, 1.0, 0.0), xDifference)
	camera.yRotation = yAxis * camera.yRotation
	QuaternionNormalize(camera.yRotation)
	RecalculateViewMatrix(camera)
end

function CameraRotateY(camera::Camera, yDifference::Real)
	right = QuaternionGetRightInverted(camera.rotation)
	right = normalize(right)
	xAxis = QuaternionNew(right, yDifference)
	camera.rotation = camera.rotation * xAxis
	QuaternionNormalize(camera.rotation)
	RecalculateViewMatrix(camera)
end

function CameraMoveForward(camera::Camera, amount::Real)
	f = camera.rotation * camera.yRotation

	forward = QuaternionGetForwardInverted(f)
	forward = amount * normalize(forward)
	camera.position = Vec3(-forward.x, -forward.y, -forward.z) + camera.position

	RecalculateViewMatrix(camera)
end

function CameraMoveRight(camera::Camera, amount::Real)
	f = camera.rotation * camera.yRotation

	right = QuaternionGetRightInverted(f)
	right = amount * normalize(right)
	camera.position = Vec3(right.x, right.y, right.z) + camera.position

	RecalculateViewMatrix(camera)
end

function CameraGetXAxis(camera::Camera)::Vec3
	q = camera.rotation * camera.yRotation
	right = QuaternionGetRightInverted(q)
	right = normalize(right)
	return Vec3(right.x, right.y, right.z)
end

function CameraGetYAxis(camera::Camera)::Vec3
	q = camera.rotation * camera.yRotation
	up = QuaternionGetUpInverted(q)
	up = normalize(up)
	return Vec3(up.x, up.y, up.z)
end

function CameraGetZAxis(camera::Camera)::Vec3
	q = camera.rotation * camera.yRotation
	forward = QuaternionGetForwardInverted(q)
	forward = normalize(forward)
	return Vec3(forward.x, forward.y, forward.z)
end

function CameraSetFov(camera::Camera, fov::Real, windowWidth::Integer, windowHeight::Integer)
	camera.fov = fov
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
end

function CameraGetViewMatrix(camera::Camera)::Matrix
	return camera.viewMatrix
end

function CameraGetProjectionMatrix(camera::Camera)::Matrix
	return camera.projectionMatrix
end

function CameraGetView(camera::Camera)::Vec3
	cameraViewMatrix = camera.viewMatrix
	cameraView = Vec3(-cameraViewMatrix[3, 1], -cameraViewMatrix[3, 2], -cameraViewMatrix[3, 3])
	return normalize(cameraView);
end

function CameraForceMatrixRecalculation(camera::Camera, windowWidth::Integer, windowHeight::Integer)
	RecalculateViewMatrix(camera)
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
end

function RecalculateViewMatrix(camera::Camera)
	trans = [
		1 0 0 -camera.position[1]
		0 1 0 -camera.position[2]
		0 0 1 -camera.position[3]
		0 0 0 1
	]

	f = camera.rotation * camera.yRotation

	rotation = QuaternionGetMatrix(f)
	camera.viewMatrix = rotation * trans
end

function RecalculateProjectionMatrix(camera::Camera, windowWidth::Integer, windowHeight::Integer)
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

# Look At Camera

function LookAtCamera(lookAtPosition::Vec3, lookAtDistance::Real, nearPlane::Real, farPlane::Real, fov::Real,
		windowWidth::Integer, windowHeight::Integer)::LookAtCamera
	cameraView = Vec3(0, 0, -1)
	position = lookAtPosition - lookAtDistance * normalize(cameraView)
	rotation = Quaternion(0, 0, 0, 1)
	yRotation = Quaternion(0, 0, 0, 1)
	camera = LookAtCamera(position, nearPlane, farPlane, fov, zeros(4, 4), zeros(4, 4), rotation, yRotation, lookAtPosition, lookAtDistance)
	RecalculateViewMatrix(camera)
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
	return camera
end

function LookAtCameraRotate(camera::LookAtCamera, xDifference::Real, yDifference::Real)
	CameraRotateX(camera, xDifference)
	CameraRotateY(camera, yDifference)
	cameraView = CameraGetView(camera)
	camera.position = camera.lookAtPosition - camera.lookAtDistance * cameraView
	RecalculateViewMatrix(camera)
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

function LookAtCameraGetLookAtDistance(camera::LookAtCamera)
	return camera.lookAtDistance
end

function LookAtCameraGetLookAtPosition(camera::LookAtCamera)
	return camera.lookAtPosition
end