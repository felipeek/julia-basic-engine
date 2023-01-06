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

# Get mouse's click position and direction vector in World Coordinates
# Inputs:
# camera - camera to consider
# mouseX, mouseY - mouse coordinates
# convertMouseCoords - if false, received mouse coordinates will be considered to be
# in range [-1, 1]. If true, the function will do the conversion from [0, WIDTH],[0, HEIGHT] to [-1, 1]
# Outputs:
# Position: Click position in world coords
# Direction: Direction vector in world coords
function MouseGetRayWorldCoords(camera::Camera, mouseX::Real, mouseY::Real, convertMouseCoords::Bool,
		windowWidth::Integer, windowHeight::Integer)::Tuple{Vec3, Vec3}

	x = mouseX
	y = mouseY

	if convertMouseCoords
		mouseY = windowHeight - mouseY
		x = (2 * mouseX) / windowWidth - 1
		y = (2 * mouseY) / windowHeight - 1
	end

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

struct NonOrientedEdge
	i1::Int64
	i2::Int64
end

function isNonOrientedEdgeEqual(e1::NonOrientedEdge, e2::NonOrientedEdge)::Bool
	return (e1.i1 == e2.i1 && e1.i2 == e2.i2) ||
		(e1.i1 == e2.i2 && e1.i2 == e2.i1)
end

Base.isequal(e1::NonOrientedEdge, e2::NonOrientedEdge) = isNonOrientedEdgeEqual(e1, e2)
Base.:(==)(e1::NonOrientedEdge, e2::NonOrientedEdge) = isNonOrientedEdgeEqual(e1, e2)
Base.hash(e::NonOrientedEdge, h::UInt) = xor(((e.i1 + e.i2) * 184721), h)

function GetTrianglesAdjacency(triangles::Vector{DVec3})::AbstractDict{<:Integer, <:Set{<:Integer}}
	edgeToTriangles = DefaultDict{NonOrientedEdge, Set{Int64}}(() -> Set{Int64}())

	for i = 1:length(triangles)
		triangle = triangles[i]

		v1 = triangle[1]
		v2 = triangle[2]
		v3 = triangle[3]

		edge1 = NonOrientedEdge(v1, v2)
		edge2 = NonOrientedEdge(v2, v3)
		edge3 = NonOrientedEdge(v3, v1)

		push!(edgeToTriangles[edge1], i)
		push!(edgeToTriangles[edge2], i)
		push!(edgeToTriangles[edge3], i)
	end

	trianglesAdjacency = DefaultDict{Int64, Set{Int64}}(() -> Set{Int64}())

	for i = 1:length(triangles)
		triangle = triangles[i]

		v1 = triangle[1]
		v2 = triangle[2]
		v3 = triangle[3]

		edge1 = NonOrientedEdge(v1, v2)
		edge2 = NonOrientedEdge(v2, v3)
		edge3 = NonOrientedEdge(v3, v1)

		e1Triangles = edgeToTriangles[edge1]
		e2Triangles = edgeToTriangles[edge2]
		e3Triangles = edgeToTriangles[edge3]

		@assert i in e1Triangles
		@assert i in e2Triangles
		@assert i in e3Triangles

		for neighbor in e1Triangles
			if neighbor != i
				push!(trianglesAdjacency[i], neighbor)
			end
		end

		for neighbor in e2Triangles
			if neighbor != i
				push!(trianglesAdjacency[i], neighbor)
			end
		end

		for neighbor in e3Triangles
			if neighbor != i
				push!(trianglesAdjacency[i], neighbor)
			end
		end
	end

	return trianglesAdjacency
end