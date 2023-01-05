const Vec4 = SVector{4, Float64}
const Vec3 = SVector{3, Float64}
const Vec2 = SVector{2, Float64}
const DVec3 = SVector{3, Int64}
const DVec2 = SVector{2, Int64}

#SVector{3, Float64}(p::GeometryBasics.Point3{<:Real}) = Vec3(p[1], p[2], p[3])
#convert(::Type{SVector{3, Float64}}, p::GeometryBasics.Point3{<:Real}) = Vec3(p)

#GeometryBasics.Point3{T}(p::Vec3) where {T<:Real} = GeometryBasics.Point3{T}(p[1], p[2], p[3])
#convert(::Type{GeometryBasics.Point3{T} where {T<:Real}}, p::Vec3) = GeometryBasics.Point3{T}(p[1], p[2], p[3])

const Vec4f = SVector{4, Float32}
const Vec3f = SVector{3, Float32}
const Vec2f = SVector{2, Float32}
const DVec3f = SVector{3, Int32}
const DVec2f = SVector{2, Int32}

Vec3f(v::Vec3) = Vec3f(Float32(v[1]), Float32(v[2]), Float32(v[3]))