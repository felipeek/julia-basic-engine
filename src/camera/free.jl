mutable struct FreeCamera <: Camera
	position::Vec3
	nearPlane::Real
	farPlane::Real
	fov::Real
	viewMatrix::Matrix
	projectionMatrix::Matrix
	rotation::Quaternion
	yRotation::Quaternion
	lockRotation::Bool
end

function FreeCamera(position::Vec3, nearPlane::Real, farPlane::Real, fov::Real, windowWidth::Integer, windowHeight::Integer,
		lockRotation::Bool = true)
	rotation = Quaternion(0, 0, 0, 1)
	yRotation = Quaternion(0, 0, 0, 1)
	camera = FreeCamera(position, nearPlane, farPlane, fov, zeros(4, 4), zeros(4, 4), rotation, yRotation, lockRotation)
	RecalculateViewMatrix(camera)
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
	return camera
end

function CameraGetPosition(camera::FreeCamera)::Vec3
	return camera.position
end

function CameraGetViewMatrix(camera::FreeCamera)::Matrix
	return camera.viewMatrix
end

function CameraGetProjectionMatrix(camera::FreeCamera)::Matrix
	return camera.projectionMatrix
end

function CameraGetXAxis(camera::FreeCamera)::Vec3
	q = camera.lockRotation ? camera.rotation * camera.yRotation : camera.rotation
	right = QuaternionGetRightInverted(q)
	right = normalize(right)
	return Vec3(right.x, right.y, right.z)
end

function CameraGetYAxis(camera::FreeCamera)::Vec3
	q = camera.lockRotation ? camera.rotation * camera.yRotation : camera.rotation
	up = QuaternionGetUpInverted(q)
	up = normalize(up)
	return Vec3(up.x, up.y, up.z)
end

function CameraGetZAxis(camera::FreeCamera)::Vec3
	q = camera.lockRotation ? camera.rotation * camera.yRotation : camera.rotation
	forward = QuaternionGetForwardInverted(q)
	forward = normalize(forward)
	return Vec3(forward.x, forward.y, forward.z)
end

function CameraSetPosition(camera::FreeCamera, position::Vec3)
	camera.position = position
	RecalculateViewMatrix(camera)
end

function CameraSetNearPlane(camera::FreeCamera, nearPlane::Real, windowWidth::Integer, windowHeight::Integer)
	camera.nearPlane = nearPlane
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
end

function CameraSetFarPlane(camera::FreeCamera, farPlane::Real, windowWidth::Integer, windowHeight::Integer)
	camera.farPlane = farPlane
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
end

function CameraRotateX(camera::FreeCamera, xDifference::Real)
	yAxis = QuaternionNew(Vec3(0.0, 1.0, 0.0), xDifference)
	if camera.lockRotation
		camera.yRotation = QuaternionNormalize(yAxis * camera.yRotation)
	else
		camera.rotation = QuaternionNormalize(yAxis * camera.rotation)
	end
	RecalculateViewMatrix(camera)
end

function CameraRotateY(camera::FreeCamera, yDifference::Real)
	local xAxis
	if camera.lockRotation
		right = QuaternionGetRightInverted(camera.rotation)
		right = normalize(right)
		xAxis = QuaternionNew(right, yDifference)
		camera.rotation = QuaternionNormalize(xAxis * camera.rotation)
	else
		xAxis = QuaternionNew(Vec3(1.0, 0.0, 0.0), yDifference)
	end

	camera.rotation = QuaternionNormalize(xAxis * camera.rotation)
	RecalculateViewMatrix(camera)
end

function CameraMoveForward(camera::FreeCamera, amount::Real)
	f = camera.lockRotation ? camera.rotation * camera.yRotation : camera.rotation

	forward = QuaternionGetForwardInverted(f)
	forward = amount * normalize(forward)
	camera.position = Vec3(-forward.x, -forward.y, -forward.z) + camera.position

	RecalculateViewMatrix(camera)
end

function CameraMoveRight(camera::FreeCamera, amount::Real)
	f = camera.lockRotation ? camera.rotation * camera.yRotation : camera.rotation

	right = QuaternionGetRightInverted(f)
	right = amount * normalize(right)
	camera.position = Vec3(right.x, right.y, right.z) + camera.position

	RecalculateViewMatrix(camera)
end

function CameraSetFov(camera::FreeCamera, fov::Real, windowWidth::Integer, windowHeight::Integer)
	camera.fov = fov
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
end

function CameraForceMatrixRecalculation(camera::FreeCamera, windowWidth::Integer, windowHeight::Integer)
	RecalculateViewMatrix(camera)
	RecalculateProjectionMatrix(camera, windowWidth, windowHeight)
end

function RecalculateViewMatrix(camera::FreeCamera)
	trans = [
		1 0 0 -camera.position.x
		0 1 0 -camera.position.y
		0 0 1 -camera.position.z
		0 0 0 1
	]

	f = camera.lockRotation ? camera.rotation * camera.yRotation : camera.rotation

	rotation = QuaternionGetMatrix(f)
	camera.viewMatrix = rotation * trans
end

function RecalculateProjectionMatrix(camera::FreeCamera, windowWidth::Integer, windowHeight::Integer)
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