const Shader = GLuint

const PHONG_VERTEX_SHADER_PATH = "./shaders/phong_shader.vs"
const PHONG_FRAGMENT_SHADER_PATH = "./shaders/phong_shader.fs"
const BASIC_VERTEX_SHADER_PATH = "./shaders/basic_shader.vs"
const BASIC_FRAGMENT_SHADER_PATH = "./shaders/basic_shader.fs"
const SELECTION_VERTEX_SHADER_PATH = "./shaders/selection_shader.vs"
const SELECTION_FRAGMENT_SHADER_PATH = "./shaders/selection_shader.fs"
const SELECTION_BOX_VERTEX_SHADER_PATH = "./shaders/selection_box_shader.vs"
const SELECTION_BOX_FRAGMENT_SHADER_PATH = "./shaders/selection_box_shader.fs"

struct RenderingVertex
	position::Vec3f
	normal::Vec3f
	textureCoordinates::Vec2f
	baryCoords::Vec3f
	selectionColor::Vec4f
end

struct Vertex
	position::Vec3f
	normal::Vec3f
	textureCoordinates::Vec2f
end

struct Mesh
	VAO::UInt32
	VBO::UInt32
	EBO::UInt32
	vertices::Vector{Vertex}
	triangles::Vector{DVec3f}
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
	selectionShader::Shader
	selectionBoxShader::Shader

	selectionBoxVAO::UInt32
	selectionBoxVBO::UInt32
	selectionBoxEBO::UInt32
end

function RenderingVertex(vertex::Vertex, baryCoords::Vec3f, selectionColor::Vec4f)::RenderingVertex
	return RenderingVertex(vertex.position, vertex.normal, vertex.textureCoordinates, baryCoords, selectionColor)
end

function GraphicsInit()::GraphicsCtx
	phongShader = GraphicsShaderCreate(PHONG_VERTEX_SHADER_PATH, PHONG_FRAGMENT_SHADER_PATH)
	basicShader = GraphicsShaderCreate(BASIC_VERTEX_SHADER_PATH, BASIC_FRAGMENT_SHADER_PATH)
	selectionShader = GraphicsShaderCreate(SELECTION_VERTEX_SHADER_PATH, SELECTION_FRAGMENT_SHADER_PATH)
	selectionBoxShader = GraphicsShaderCreate(SELECTION_BOX_VERTEX_SHADER_PATH, SELECTION_BOX_FRAGMENT_SHADER_PATH)
	selectionBoxVAO, selectionBoxVBO, selectionBoxEBO = SelectionBoxSetup()

	return GraphicsCtx(phongShader, basicShader, selectionShader, selectionBoxShader, selectionBoxVAO, selectionBoxVBO, selectionBoxEBO)
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

function GraphicsMeshCreate(vertices::Vector{Vertex}, triangles::Vector{DVec3f})::Mesh
	renderingVertices = Vector{RenderingVertex}()

	for i = 1:length(triangles)
		t = triangles[i]

		v1 = vertices[t[1]]
		v2 = vertices[t[2]]
		v3 = vertices[t[3]]

		triangleUniqueColor = TriangleIndexToUniqueColor(i)

		push!(renderingVertices, RenderingVertex(v1, Vec3f(1, 0, 0), triangleUniqueColor))
		push!(renderingVertices, RenderingVertex(v2, Vec3f(0, 1, 0), triangleUniqueColor))
		push!(renderingVertices, RenderingVertex(v3, Vec3f(0, 0, 1), triangleUniqueColor))
	end

	indexes = UInt32[i - 1 for i = 1:length(renderingVertices)]

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
	glBufferData(GL_ARRAY_BUFFER, length(renderingVertices) * sizeof(RenderingVertex), C_NULL, GL_STATIC_DRAW)
	glBufferSubData(GL_ARRAY_BUFFER, 0, length(renderingVertices) * sizeof(RenderingVertex), renderingVertices)

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(RenderingVertex), Ptr{Cvoid}(0 * sizeof(GLfloat)))
	glEnableVertexAttribArray(0)

	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(RenderingVertex), Ptr{Cvoid}(3 * sizeof(GLfloat)))
	glEnableVertexAttribArray(1)

	glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(RenderingVertex), Ptr{Cvoid}(6 * sizeof(GLfloat)))
	glEnableVertexAttribArray(2)

	glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, sizeof(RenderingVertex), Ptr{Cvoid}(8 * sizeof(GLfloat)))
	glEnableVertexAttribArray(3)

	glVertexAttribPointer(4, 4, GL_FLOAT, GL_FALSE, sizeof(RenderingVertex), Ptr{Cvoid}(11 * sizeof(GLfloat)))
	glEnableVertexAttribArray(4)

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO)
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, length(indexes) * sizeof(UInt32), C_NULL, GL_STATIC_DRAW)
	glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, length(indexes) * sizeof(UInt32), indexes)

	glBindVertexArray(0)

	glBindBuffer(GL_ARRAY_BUFFER, 0)
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

	return Mesh(VAO, VBO, EBO, vertices, triangles)
end

function SelectionBoxSetup()::Tuple{GLuint, GLuint, GLuint}
	VAORef = Ref{GLuint}(0)
	VBORef = Ref{GLuint}(0)
	EBORef = Ref{GLuint}(0)
	glGenVertexArrays(1, VAORef)
	glGenBuffers(1, VBORef)
	glGenBuffers(1, EBORef)

	VAO = VAORef[]
	VBO = VBORef[]
	EBO = EBORef[]

	data = GLint[0, 1, 2, 3]
	indexes = GLuint[0, 1, 1, 2, 2, 3, 3, 0]

	glBindVertexArray(VAO)

	glBindBuffer(GL_ARRAY_BUFFER, VBO)
	glBufferData(GL_ARRAY_BUFFER, length(data) * sizeof(GLint), C_NULL, GL_STATIC_DRAW)
	glBufferSubData(GL_ARRAY_BUFFER, 0, length(data) * sizeof(GLint), data)

	glVertexAttribIPointer(0, 1, GL_INT, sizeof(GLint), Ptr{Cvoid}(0 * sizeof(GLint)))
	glEnableVertexAttribArray(0)

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO)
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, length(indexes) * sizeof(GLuint), C_NULL, GL_STATIC_DRAW)
	glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, length(indexes) * sizeof(GLuint), indexes)

	glBindVertexArray(0)

	glBindBuffer(GL_ARRAY_BUFFER, 0)
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

	return VAO, VBO, EBO
end

function GraphicsMeshRender(shader::Shader, mesh::Mesh)
	glBindVertexArray(mesh.VAO)
	glUseProgram(shader)
	glDrawElements(GL_TRIANGLES, length(mesh.triangles) * 3, GL_UNSIGNED_INT, C_NULL)
	glUseProgram(0)
	glBindVertexArray(0)
end

function GraphicsSelectionBoxRender(ctx::GraphicsCtx, p1::Vec2, p2::Vec2)
	shader = ctx.selectionBoxShader
	glUseProgram(shader)
	glBindVertexArray(ctx.selectionBoxVAO)

	p1Location = glGetUniformLocation(shader, "p1")
	p2Location = glGetUniformLocation(shader, "p2")
	glUniform2f(p1Location, Float32(p1[1]), Float32(p1[2]))
	glUniform2f(p2Location, Float32(p2[1]), Float32(p2[2]))

	glDisable(GL_DEPTH_TEST)
	glDrawElements(GL_LINES, 8, GL_UNSIGNED_INT, C_NULL)
	glEnable(GL_DEPTH_TEST)

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
		entity.worldScale[1] 0 0 0
		0 entity.worldScale[2] 0 0
		0 0 entity.worldScale[3] 0
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
	modelMatrixArr = Matrix4ToFloat32Array(entity.modelMatrix)
	viewMatrixArr = Matrix4ToFloat32Array(CameraGetViewMatrix(camera))
	projectionMatrixArr = Matrix4ToFloat32Array(CameraGetProjectionMatrix(camera))
	glUniformMatrix4fv(modelMatrixLocation, 1, GL_TRUE, modelMatrixArr)
	glUniformMatrix4fv(viewMatrixLocation, 1, GL_TRUE, viewMatrixArr)
	glUniformMatrix4fv(projectionMatrixLocation, 1, GL_TRUE, projectionMatrixArr)
	GraphicsMeshRender(shader, entity.mesh)
	glUseProgram(0)
end

function GraphicsEntityRenderSelectionShader(ctx::GraphicsCtx, camera::Camera, entity::Entity)
	shader = ctx.selectionShader
	glUseProgram(shader)
	modelMatrixLocation = glGetUniformLocation(shader, "model_matrix")
	viewMatrixLocation = glGetUniformLocation(shader, "view_matrix")
	projectionMatrixLocation = glGetUniformLocation(shader, "projection_matrix")
	modelMatrixArr = Matrix4ToFloat32Array(entity.modelMatrix)
	viewMatrixArr = Matrix4ToFloat32Array(CameraGetViewMatrix(camera))
	projectionMatrixArr = Matrix4ToFloat32Array(CameraGetProjectionMatrix(camera))
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

	modelMatrixArr = Matrix4ToFloat32Array(entity.modelMatrix)
	viewMatrixArr = Matrix4ToFloat32Array(CameraGetViewMatrix(camera))
	projectionMatrixArr = Matrix4ToFloat32Array(CameraGetProjectionMatrix(camera))

	glUniform3f(cameraPositionLocation, Float32(CameraGetPosition(camera)[1]), Float32(CameraGetPosition(camera)[2]), Float32(CameraGetPosition(camera)[3]))
	glUniform1f(shininessLocation, Float32(128.0))
	glUniformMatrix4fv(modelMatrixLocation, 1, GL_TRUE, modelMatrixArr)
	glUniformMatrix4fv(viewMatrixLocation, 1, GL_TRUE, viewMatrixArr)
	glUniformMatrix4fv(projectionMatrixLocation, 1, GL_TRUE, projectionMatrixArr)
	glUniform4f(diffuseColorLocation, Float32(entity.diffuseColor[1]), Float32(entity.diffuseColor[2]),
		Float32(entity.diffuseColor[3]), Float32(entity.diffuseColor[4]))
	GraphicsMeshRender(shader, entity.mesh)
	glUseProgram(0)
end

function LightUpdateUniforms(lights::Vector{Light}, shader::Shader)
	numberOfLights = length(lights)
	glUseProgram(shader)

	for i = 1:numberOfLights
		light = lights[i]
		uniformPrefix = "lights[" * string(i - 1) * "]."
		lightPositionLocation = glGetUniformLocation(shader, uniformPrefix * "position")
		ambientColorLocation = glGetUniformLocation(shader, uniformPrefix * "ambient_color")
		diffuseColorLocation = glGetUniformLocation(shader, uniformPrefix * "diffuse_color")
		specularColorLocation = glGetUniformLocation(shader, uniformPrefix * "specular_color")
		glUniform3f(lightPositionLocation, Float32(light.position[1]), Float32(light.position[2]),
			Float32(light.position[3]))
		glUniform4f(ambientColorLocation, Float32(light.ambientColor[1]), Float32(light.ambientColor[2]),
			Float32(light.ambientColor[3]), Float32(light.ambientColor[4]))
		glUniform4f(diffuseColorLocation, Float32(light.diffuseColor[1]), Float32(light.diffuseColor[2]),
			Float32(light.diffuseColor[3]), Float32(light.diffuseColor[4]))
		glUniform4f(specularColorLocation, Float32(light.specularColor[1]), Float32(light.specularColor[2]),
			Float32(light.specularColor[3]), Float32(light.specularColor[4]))
	end

	lightQuantityLocation = glGetUniformLocation(shader, "light_quantity")
	glUniform1i(lightQuantityLocation, numberOfLights)
end

function GraphicsMeshCreateFromObj(objPath::String)::Mesh
	# Load a model mesh
	rawMesh = FileIO.load(objPath)

	# Transform the mesh data into a mesh container object
	# This is a brute force approach because the triangles do not point to the point positions in the array...
	# instead, they redefine every point...
	vertexToIdx = Dict()
	for i = 1:length(rawMesh.position)
		vertex = rawMesh.position[i]
		
		if haskey(vertexToIdx, vertex)
			println("Warning: found a duplicated vertex in the mesh. Attributes like normals and UVs may not be correct (MeshIO.jl limitation)")
		end

		vertexToIdx[vertex] = i
	end
	
	vertices = Vector{Vertex}()
	triangles = Vector{DVec3f}()
	mustGenerateNormals = !hasproperty(rawMesh, :normals)
	local generatedNormals
	hasUv = hasproperty(rawMesh, :uv)

	for triangle in rawMesh
		i1 = vertexToIdx[triangle[1]]
		i2 = vertexToIdx[triangle[2]]
		i3 = vertexToIdx[triangle[3]]
		push!(triangles, DVec3f(i1, i2, i3))
	end

	if mustGenerateNormals
		println("Object " * objPath * " does not have normals. Normals will be generated.")
		generatedNormals = fill(Vec3f(0, 0, 0), length(rawMesh.position))

		for t in triangles
			i1 = t[1]
			i2 = t[2]
			i3 = t[3]

			p1 = Vec3f(rawMesh.position[i1])
			p2 = Vec3f(rawMesh.position[i2])
			p3 = Vec3f(rawMesh.position[i3])

			e1 = p2 - p1
			e2 = p3 - p1

			normal = cross(e1, e2)

			generatedNormals[i1] += normal
			generatedNormals[i2] += normal
			generatedNormals[i3] += normal
		end
	end

	for i = 1:length(rawMesh.position)
		position = Vec3f(rawMesh.position[i])
		normal = !mustGenerateNormals ? Vec3f(rawMesh.normals[i]) : generatedNormals[i]
		uv = hasUv ? Vec2f(rawMesh.uv[i]) : Vec2f(0, 0)
		push!(vertices, Vertex(position, normal, uv))
	end

	return GraphicsMeshCreate(vertices, triangles)
end

function Matrix4ToFloat32Array(m::Matrix)::Vector{Float32}
	v = Vector{Float32}()

	push!(v, m[1, 1])
	push!(v, m[1, 2])
	push!(v, m[1, 3])
	push!(v, m[1, 4])
	push!(v, m[2, 1])
	push!(v, m[2, 2])
	push!(v, m[2, 3])
	push!(v, m[2, 4])
	push!(v, m[3, 1])
	push!(v, m[3, 2])
	push!(v, m[3, 3])
	push!(v, m[3, 4])
	push!(v, m[4, 1])
	push!(v, m[4, 2])
	push!(v, m[4, 3])
	push!(v, m[4, 4])

	return v
end