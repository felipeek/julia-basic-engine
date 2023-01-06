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

function GetTrianglesAdjacency(triangles::Vector{DVec3})::AbstractDict{<:Integer, <:Set{<:Integer}}
	vertexToTriangles = DefaultDict{Int64, Set{Int64}}(() -> Set{Int64}())

	for i = 1:length(triangles)
		triangle = triangles[i]

		push!(vertexToTriangles[triangle[1]], i)
		push!(vertexToTriangles[triangle[2]], i)
		push!(vertexToTriangles[triangle[3]], i)
	end

	trianglesAdjacency = DefaultDict{Int64, Set{Int64}}(() -> Set{Int64}())

	for i = 1:length(triangles)
		triangle = triangles[i]
		v1Idx = triangle[1]
		v2Idx = triangle[2]
		v3Idx = triangle[3]

		v1Triangles = vertexToTriangles[v1Idx]
		v2Triangles = vertexToTriangles[v2Idx]
		v3Triangles = vertexToTriangles[v3Idx]

		@assert i in v1Triangles
		@assert i in v2Triangles
		@assert i in v3Triangles

		for neighbor in v1Triangles
			if neighbor != i
				push!(trianglesAdjacency[i], neighbor)
			end
		end

		for neighbor in v2Triangles
			if neighbor != i
				push!(trianglesAdjacency[i], neighbor)
			end
		end

		for neighbor in v3Triangles
			if neighbor != i
				push!(trianglesAdjacency[i], neighbor)
			end
		end
	end

	return trianglesAdjacency
end