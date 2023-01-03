struct Quaternion
	x::Real
	y::Real
	z::Real
	w::Real
end

function QuaternionNewRadians(axis::Vec3, angle::Real)::Quaternion
	@assert norm(axis) != 0.0
	axis = normalize(axis)
	sang = sin(angle / 2.0)

	w = cos(angle / 2.0)
	x = axis.x * sang
	y = axis.y * sang
	z = axis.z * sang

	return Quaternion(x, y, z, w)
end

function QuaternionNew(axis::Vec3, angle::Real)::Quaternion
	@assert norm(axis) != 0.0
	axis = normalize(axis)
	sang = sin(deg2rad(angle) / 2.0)

	w = cos(deg2rad(angle) / 2.0)
	x = axis.x * sang
	y = axis.y * sang
	z = axis.z * sang

	return Quaternion(x, y, z, w)
end

function QuaternionGetRightInverted(quat::Quaternion)::Vec3
	return Vec3(
		1.0 - (2.0 * quat.y * quat.y) - (2.0 * quat.z * quat.z),
		2.0 * quat.x * quat.y - 2.0 * quat.w * quat.z,
		2.0 * quat.x * quat.z + 2.0 * quat.w * quat.y
	)
end

function QuaternionGetUpInverted(quat::Quaternion)::Vec3
	return Vec3(
		2.0 * quat.x * quat.y + 2.0 * quat.w * quat.z, 
		1.0 - (2.0 * quat.x * quat.x) - (2.0 * quat.z * quat.z),
		2.0 * quat.y * quat.z - 2.0 * quat.w * quat.x
	)
end

function QuaternionGetForwardInverted(quat::Quaternion)::Vec3
	return Vec3(
		2.0 * quat.x * quat.z - 2.0 * quat.w * quat.y, 
		2.0 * quat.y * quat.z + 2.0 * quat.w * quat.x, 
		1.0 - (2.0 * quat.x * quat.x) - (2.0 * quat.y * quat.y)
	)
end

function QuaternionGetRight(quat::Quaternion)::Vec3
	return Vec3(
		1.0 - (2.0 * quat.y * quat.y) - (2.0 * quat.z * quat.z),
		2.0 * quat.x * quat.y - 2.0 * -quat.w * quat.z, 
		2.0 * quat.x * quat.z + 2.0 * -quat.w * quat.y
	)
end

function QuaternionGetUp(quat::Quaternion)::Vec3
	return Vec3(
		2.0 * quat.x * quat.y + 2.0 * -quat.w * quat.z, 
		1.0 - (2.0 * quat.x * quat.x) - (2.0 * quat.z * quat.z),
		2.0 * quat.y * quat.z - 2.0 * -quat.w * quat.x
	)
end

function QuaternionGetForward(quat::Quaternion)::Vec3
	return Vec3(
		2.0 * quat.x * quat.z - 2.0 * -quat.w * quat.y, 
		2.0 * quat.y * quat.z + 2.0 * -quat.w * quat.x, 
		1.0 - (2.0 * quat.x * quat.x) - (2.0 * quat.y * quat.y)
	)
end

function QuaternionInverse(quat::Quaternion)::Quaternion
	x = -quat.x
	y = -quat.y
	z = -quat.z
	w = quat.w
	return Quaternion(x, y, z, w)
end

function QuaternionGetMatrix(quat::Quaternion)::Matrix
	result = zeros(4, 4)

	result[1, 1] = 1.0 - 2.0 * quat.y * quat.y - 2.0 * quat.z * quat.z
	result[2, 1] = 2.0 * quat.x * quat.y + 2.0 * quat.w * quat.z
	result[3, 1] = 2.0 * quat.x * quat.z - 2.0 * quat.w * quat.y
	result[4, 1] = 0.0

	result[1, 2] = 2.0 * quat.x * quat.y - 2.0 * quat.w * quat.z
	result[2, 2] = 1.0 - (2.0 * quat.x * quat.x) - (2.0 * quat.z * quat.z)
	result[3, 2] = 2.0 * quat.y * quat.z + 2.0 * quat.w * quat.x
	result[4, 2] = 0.0

	result[1, 3] = 2.0 * quat.x * quat.z + 2.0 * quat.w * quat.y
	result[2, 3] = 2.0 * quat.y * quat.z - 2.0 * quat.w * quat.x
	result[3, 3] = 1.0 - (2.0 * quat.x * quat.x) - (2.0 * quat.y * quat.y)
	result[4, 3] = 0.0

	result[1, 4] = 0.0
	result[2, 4] = 0.0
	result[3, 4] = 0.0
	result[4, 4] = 1.0

	return result
end

function QuaternionProduct(q1::Quaternion, q2::Quaternion)::Quaternion
	w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
	x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y
	y = q1.w * q2.y + q1.y * q2.w + q1.z * q2.x - q1.x * q2.z
	z = q1.w * q2.z + q1.z * q2.w + q1.x * q2.y - q1.y * q2.x

	return Quaternion(x, y, z, w)
end

function Base.:*(q1::Quaternion, q2::Quaternion)::Quaternion
	return QuaternionProduct(q1, q2)
end

function QuaternionNormalize(q::Quaternion)::Quaternion
	len = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w)
	return Quaternion(q.x / len, q.y / len, q.z / len, q.w / len)
end

function QuaternionSlerp(q1::Quaternion, q2::Quaternion, t::Real)::Quaternion
	# Calculate angle between them.
	cosHalfTheta = q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z
	if cosHalfTheta < 0
		q2.w = -q2.w
		q2.x = -q2.x
		q2.y = -q2.y
		q2.z = q2.z
		cosHalfTheta = -cosHalfTheta
	end

	if abs(cosHalfTheta) >= 1.0
		return q1
	end

	halfTheta = acos(cosHalfTheta)
	sinHalfTheta = sqrt(1.0 - cosHalfTheta * cosHalfTheta)

	if fabsf(sinHalfTheta) < 0.001
		w = q1.w * 0.5 + q2.w * 0.5
		x = q1.x * 0.5 + q2.x * 0.5
		y = q1.y * 0.5 + q2.y * 0.5
		z = q1.z * 0.5 + q2.z * 0.5
		return Quaternion(x, y, z, w)
	end

	ratioA = sin((1 - t) * halfTheta) / sinHalfTheta
	ratioB = sin(t * halfTheta) / sinHalfTheta

	# Calculate Quaternion
	w = q1.w * ratioA + q2.w * ratioB
	x = q1.x * ratioA + q2.x * ratioB
	y = q1.y * ratioA + q2.y * ratioB
	z = q1.z * ratioA + q2.z * ratioB
	return Quaternion(x, y, z, w)
end

function QuaternionNlerp(q1::Quaternion, q2::Quaternion, t::Real)::Quaternion
	dot = q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z
	blendI = 1.0 - t

	local result
	if dot < 0
		w = blendI * q1.w + t * -q2.w
		x = blendI * q1.x + t * -q2.x
		y = blendI * q1.y + t * -q2.y
		z = blendI * q1.z + t * -q2.z
		result = Quaternion(x, y, z, w)
	else
		w = blendI * q1.w + t * q2.w
		x = blendI * q1.x + t * q2.x
		y = blendI * q1.y + t * q2.y
		z = blendI * q1.z + t * q2.z
		result = Quaternion(x, y, z, w)
	end

	return QuaternionNormalize(result)
end