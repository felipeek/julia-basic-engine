const Shader = GLuint

const PHONG_VERTEX_SHADER_PATH = "./shaders/phong_shader.vs"
const PHONG_FRAGMENT_SHADER_PATH = "./shaders/phong_shader.fs"
const BASIC_VERTEX_SHADER_PATH = "./shaders/basic_shader.vs"
const BASIC_FRAGMENT_SHADER_PATH = "./shaders/basic_shader.fs"

struct Vertex
	position::Vec3f
	normal::Vec3f
	textureCoordinates::Vec2f
end

struct Mesh
	VAO::UInt32
	VBO::UInt32
	EBO::UInt32
	points::Vector{Vec3}
	triangles::Vector{DVec3}
end

mutable struct Entity
	mesh::Mesh
	worldPosition::Vec3
	worldRotation::Quaternion
	worldScale::Vec3
	modelMatrix::Matrix
	diffuseColor::Vec4
end

mutable struct Light
	position::Vec3
	ambientColor::Vec4
	diffuseColor::Vec4
	specularColor::Vec4
end

mutable struct GraphicsCtx
	phongShader::Shader
	basicShader::Shader
end

function GraphicsInit()::GraphicsCtx
	phongShader = GraphicsShaderCreate(PHONG_VERTEX_SHADER_PATH, PHONG_FRAGMENT_SHADER_PATH)
	basicShader = GraphicsShaderCreate(BASIC_VERTEX_SHADER_PATH, BASIC_FRAGMENT_SHADER_PATH)

	return GraphicsCtx(phongShader, basicShader)
end

function GraphicsShaderCreate(vertexShaderPath::String, fragmentShaderPath::String)::Shader
	vertexShaderCode = [ read(vertexShaderPath, String) ]
	fragmentShaderCode = [ read(fragmentShaderPath, String) ]

	vertexShader = glCreateShader(GL_VERTEX_SHADER)
	fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)

	glShaderSource(vertexShader, 1, vertexShaderCode, C_NULL)
	glShaderSource(fragmentShader, 1, fragmentShaderCode, C_NULL)

	statusRef = Ref{GLint}(-1)
	statusBufferSize = 1024
	statusBuffer = fill(0x0, statusBufferSize)
	glCompileShader(vertexShader)

	glGetShaderiv(vertexShader, GL_COMPILE_STATUS, statusRef)
	if statusRef[] == GL_FALSE
		glGetShaderInfoLog(vertexShader, statusBufferSize, C_NULL, statusBuffer)
		println("Error compiling vertex shader: ", String(statusBuffer))
	end

	glCompileShader(fragmentShader)
	glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, statusRef)
	if statusRef[] == GL_FALSE
		glGetShaderInfoLog(fragmentShader, statusBufferSize, C_NULL, statusBuffer)
		println("Error compiling fragment shader: ", String(statusBuffer))
	end

	shaderProgram = glCreateProgram()

	glAttachShader(shaderProgram, vertexShader)
	glAttachShader(shaderProgram, fragmentShader)
	glLinkProgram(shaderProgram)

	glGetProgramiv(shaderProgram, GL_LINK_STATUS, statusRef)
	if statusRef[] == GL_FALSE
		glGetShaderInfoLog(shaderProgram, statusBufferSize, C_NULL, statusBuffer)
		println("Error linking program: ", String(statusBuffer))
	end

	return shaderProgram
end

function GraphicsMeshRender(shader::Shader, mesh::Mesh)
	glBindVertexArray(mesh.VAO)
	glUseProgram(shader)
	#normals_update_uniforms(&mesh.normal_info, shader)
	glDrawElements(GL_TRIANGLES, length(mesh.triangles) * 3, GL_UNSIGNED_INT, C_NULL)
	glUseProgram(0)
	glBindVertexArray(0)
end

function GraphicsEntityCreate(mesh::Mesh, worldPosition::Vec3, worldRotation::Quaternion, worldScale::Vec3, color::Vec4)::Entity
	entity = Entity(mesh, worldPosition, worldRotation, worldScale, zeros(4, 4), color)
	EntityRecalculateModelMatrix(entity)

	return entity
end

function GraphicsEntitySetPosition(entity::Entity, worldPosition::Vec3)
	entity.worldPosition = worldPosition
	EntityRecalculateModelMatrix(entity)
end

function GraphicsEntitySetRotation(entity::Entity, worldRotation::Quaternion)
	entity.worldRotation = worldRotation
	EntityRecalculateModelMatrix(entity)
end

function GraphicsEntitySetScale(entity::Entity, worldScale::Vec3)
	entity.worldScale = worldScale
	EntityRecalculateModelMatrix(entity)
end

function EntityRecalculateModelMatrix(entity::Entity)
	scaleMatrix = [
		entity.worldScale.x 0 0 0
		0 entity.worldScale.y 0 0
		0 0 entity.worldScale.z 0
		0 0 0 1
	]

	rotationMatrix = QuaternionGetMatrix(entity.worldRotation)

	translationMatrix = [
		1 0 0 entity.worldPosition.x
		0 1 0 entity.worldPosition.y
		0 0 1 entity.worldPosition.z
		0 0 0 1
	]

	entity.modelMatrix = rotationMatrix * scaleMatrix
	entity.modelMatrix = translationMatrix * entity.modelMatrix
end

function GraphicsEntityRenderBasicShader(ctx::GraphicsCtx, camera::Camera, entity::Entity)
	shader = ctx.basicShader
	glUseProgram(shader)
	modelMatrixLocation = glGetUniformLocation(shader, "model_matrix")
	viewMatrixLocation = glGetUniformLocation(shader, "view_matrix")
	projectionMatrixLocation = glGetUniformLocation(shader, "projection_matrix")
	modelMatrixArr = MatrixToArray(entity.modelMatrix, Float32)
	viewMatrixArr = MatrixToArray(CameraGetViewMatrix(camera), Float32)
	projectionMatrixArr = MatrixToArray(CameraGetProjectionMatrix(camera), Float32)
	glUniformMatrix4fv(modelMatrixLocation, 1, GL_TRUE, modelMatrixArr)
	glUniformMatrix4fv(viewMatrixLocation, 1, GL_TRUE, viewMatrixArr)
	glUniformMatrix4fv(projectionMatrixLocation, 1, GL_TRUE, projectionMatrixArr)
	GraphicsMeshRender(shader, entity.mesh)
	glUseProgram(0)
end

function GraphicsEntityRenderPhongShader(ctx::GraphicsCtx, camera::Camera, entity::Entity, lights::Vector{Light})
	shader = ctx.phongShader
	glUseProgram(shader)
	LightUpdateUniforms(lights, shader)
	cameraPositionLocation = glGetUniformLocation(shader, "camera_position")
	shininessLocation = glGetUniformLocation(shader, "object_shineness")
	modelMatrixLocation = glGetUniformLocation(shader, "model_matrix")
	viewMatrixLocation = glGetUniformLocation(shader, "view_matrix")
	projectionMatrixLocation = glGetUniformLocation(shader, "projection_matrix")
	diffuseColorLocation = glGetUniformLocation(shader, "diffuse_color")

	cameraPosition = CameraGetPosition(camera)
	modelMatrixArr = MatrixToArray(entity.modelMatrix, Float32)
	viewMatrixArr = MatrixToArray(CameraGetViewMatrix(camera), Float32)
	projectionMatrixArr = MatrixToArray(CameraGetProjectionMatrix(camera), Float32)

	glUniform3f(cameraPositionLocation, cameraPosition.x, cameraPosition.y, cameraPosition.z)
	glUniform1f(shininessLocation, 128.0)
	glUniformMatrix4fv(modelMatrixLocation, 1, GL_TRUE, modelMatrixArr)
	glUniformMatrix4fv(viewMatrixLocation, 1, GL_TRUE, viewMatrixArr)
	glUniformMatrix4fv(projectionMatrixLocation, 1, GL_TRUE, projectionMatrixArr)
	glUniform4f(diffuseColorLocation, entity.diffuseColor[1], entity.diffuseColor[2], entity.diffuseColor[3], entity.diffuseColor[4])
	GraphicsMeshRender(shader, entity.mesh)
	glUseProgram(0)
end

function LightUpdateUniforms(lights::Vector{Light}, shader::Shader)
	glUseProgram(shader)

	for i in eachindex(lights)
		light = lights[i]
		uniformPrefix = "lights[" * string(i - 1) * "]."
		lightPositionLocation = glGetUniformLocation(shader, uniformPrefix * "position")
		ambientColorLocation = glGetUniformLocation(shader, uniformPrefix * "ambient_color")
		diffuseColorLocation = glGetUniformLocation(shader, uniformPrefix * "diffuse_color")
		specularColorLocation = glGetUniformLocation(shader, uniformPrefix * "specular_color")
		glUniform3f(lightPositionLocation, light.position.x, light.position.y, light.position.z)
		glUniform4f(ambientColorLocation, light.ambientColor[1], light.ambientColor[2], light.ambientColor[3], light.ambientColor[4])
		glUniform4f(diffuseColorLocation, light.diffuseColor[1], light.diffuseColor[2], light.diffuseColor[3], light.diffuseColor[4])
		glUniform4f(specularColorLocation, light.specularColor[1], light.specularColor[2], light.specularColor[3], light.specularColor[4])
	end

	lightQuantityLocation = glGetUniformLocation(shader, "light_quantity")
	glUniform1i(lightQuantityLocation, length(lights))
end

function GraphicsMeshCreateFromObj(objPath::String)::Mesh
	# Load a model mesh
	rawMesh = FileIO.load(objPath)

	# Transform the mesh data into a mesh container object
	# This is a brute force approach because the triangles do not point to the point positions in the array...
	# instead, they redefine every point...
	positionToIdx = Dict()
	for (i, position) in enumerate(rawMesh.position)
		if haskey(positionToIdx, position)
			@printf "Warning: found a duplicated vertex in the mesh. Attributes like normals and UVs may not be correct (MeshIO.jl limitation)\n"
		end

		positionToIdx[position] = i
	end
	
	triangles = Vector{DVec3}()

	for triangle in rawMesh
		i1 = positionToIdx[triangle[1]]
		i2 = positionToIdx[triangle[2]]
		i3 = positionToIdx[triangle[3]]
		push!(triangles, DVec3(i1, i2, i3))
	end

	uvCoords = hasproperty(rawMesh, :uv) ? [Vec2(rawMesh.uv[i]) for i in eachindex(rawMesh.uv)] :
		[Vec2(0.0, 0.0) for _ in eachindex(rawMesh.position)]

	return GraphicsMeshCreate([Vec3(p) for p in rawMesh.position], triangles, uvCoords)
end

function GraphicsMeshCreate(points::Vector{Vec3}, triangles::Vector{DVec3}, uvCoords::Vector{Vec2})::Mesh
	# Generate normals
	generatedNormals = fill(Vec3(0, 0, 0), length(points)) # Vec3 is immutable, so we can fill everything with the same reference

	for t in triangles
		i1 = t[1]
		i2 = t[2]
		i3 = t[3]

		p1 = points[i1]
		p2 = points[i2]
		p3 = points[i3]

		e1 = p2 - p1
		e2 = p3 - p1

		normal = cross(e1, e2)

		generatedNormals[i1] += normal
		generatedNormals[i2] += normal
		generatedNormals[i3] += normal
	end

	return GraphicsMeshCreate(points, triangles, generatedNormals, uvCoords)
end

function GraphicsMeshCreate(points::Vector{Vec3}, triangles::Vector{DVec3}, normals::Vector{Vec3}, uvCoords::Vector{Vec2})::Mesh
	vertices = [Vertex(points[i], normals[i], uvCoords[i]) for i in eachindex(points)]

	indexes = Vector{UInt32}()
	for t in triangles
		push!(indexes, t[1] - 1)
		push!(indexes, t[2] - 1)
		push!(indexes, t[3] - 1)
	end

	VAORef = Ref{GLuint}(0)
	VBORef = Ref{GLuint}(0)
	EBORef = Ref{GLuint}(0)
	glGenVertexArrays(1, VAORef)
	glGenBuffers(1, VBORef)
	glGenBuffers(1, EBORef)

	VAO = VAORef[]
	VBO = VBORef[]
	EBO = EBORef[]

	glBindVertexArray(VAO)

	glBindBuffer(GL_ARRAY_BUFFER, VBO)
	glBufferData(GL_ARRAY_BUFFER, length(vertices) * sizeof(Vertex), C_NULL, GL_STATIC_DRAW)
	glBufferSubData(GL_ARRAY_BUFFER, 0, length(vertices) * sizeof(Vertex), vertices)

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), Ptr{Cvoid}(0 * sizeof(GLfloat)))
	glEnableVertexAttribArray(0)

	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), Ptr{Cvoid}(3 * sizeof(GLfloat)))
	glEnableVertexAttribArray(1)

	glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), Ptr{Cvoid}(6 * sizeof(GLfloat)))
	glEnableVertexAttribArray(2)

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO)
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, length(indexes) * sizeof(UInt32), C_NULL, GL_STATIC_DRAW)
	glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, length(indexes) * sizeof(UInt32), indexes)

	glBindVertexArray(0)

	glBindBuffer(GL_ARRAY_BUFFER, 0)
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

	return Mesh(VAO, VBO, EBO, points, triangles)
end

# Note: Julia matrices are column-major
# OpenGL textures expect row-major data
# GLSL uniforms expect column-major data
# This function returns row-major data, and we use transpose=GL_TRUE when updating the uniforms
function MatrixToArray(m::Matrix, ::Type{T})::Vector{T} where {T}
	v = Vector{T}()

	height, width = size(m)

	for i = 1:height
		for j = 1:width
			push!(v, m[i, j])
		end
	end

	return v
end