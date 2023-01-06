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