mutable struct CoreCtx
	graphicsCtx::GraphicsCtx

	camera::PerspectiveCamera
	lights::Vector{Light}
	e::Entity
	wireframe::Bool
	xPosOld::Real
	yPosOld::Real

	windowWidth::Integer
	windowHeight::Integer
	keyState::AbstractDict{GLFW.Key, Bool}
end

function CreateCamera(windowWidth::Integer, windowHeight::Integer)::PerspectiveCamera
	cameraPosition = Vec3(0.0, 0.0, 4.0)
	cameraNearPlane = -0.01
	cameraFarPlane = -1000.0
	cameraFov = 45.0
	return PerspectiveCamera(cameraPosition, cameraNearPlane, cameraFarPlane, cameraFov, windowWidth, windowHeight)
end

function CreateLights()::Vector{Light}
	lights = Vector{Light}()

	lightPosition = Vec3(0.0, 0.0, 15.0)
	ambientColor = Vec4(0.1, 0.1, 0.1, 1.0)
	diffuseColor = Vec4(0.8, 0.8, 0.8, 1.0)
	specularColor = Vec4(0.5, 0.5, 0.5, 1.0)
	light = Light(lightPosition, ambientColor, diffuseColor, specularColor)
	push!(lights, light)

	return lights
end

function CreateEntity()::Entity
	mesh = GraphicsMeshCreateFromObj("./res/spot.obj")
	return GraphicsEntityCreate(mesh, Vec3(0.0, 0.0, 0.0), QuaternionNew(Vec3(0.0, 1.0, 0.0), 135.0), Vec3(1.0, 1.0, 1.0),
		Vec4(113 / 255, 199 / 255, 236 / 255, 1))
end

function CoreInit(windowWidth::Integer, windowHeight::Integer)::CoreCtx
	graphicsCtx = GraphicsInit()

	camera = CreateCamera(windowWidth, windowHeight)
	lights = CreateLights()
	e = CreateEntity()
	wireframe = false
	keyState = DefaultDict{GLFW.Key, Bool}(false)

	return CoreCtx(graphicsCtx, camera, lights, e, wireframe, 0, 0, windowWidth, windowHeight, keyState)
end

function CoreDestroy(ctx::CoreCtx)
end

function CoreUpdate(ctx::CoreCtx, deltaTime::Real)
end

function CoreRender(ctx::CoreCtx)
	GraphicsEntityRenderPhongShader(ctx.graphicsCtx, ctx.camera, ctx.e, ctx.lights)
end

function CoreInputProcess(ctx::CoreCtx, deltaTime::Real)
	movementSpeed = 3.0
	rotationSpeed = 300.0

	if ctx.keyState[GLFW.KEY_LEFT_SHIFT]
		movementSpeed = 0.5
	end
	if ctx.keyState[GLFW.KEY_RIGHT_SHIFT]
		movementSpeed = 0.1
	end

	if ctx.keyState[GLFW.KEY_W]
		CameraMoveForward(ctx.camera, movementSpeed * deltaTime)
	end
	if ctx.keyState[GLFW.KEY_S]
		CameraMoveForward(ctx.camera, -movementSpeed * deltaTime)
	end
	if ctx.keyState[GLFW.KEY_A]
		CameraMoveRight(ctx.camera, -movementSpeed * deltaTime)
	end
	if ctx.keyState[GLFW.KEY_D]
		CameraMoveRight(ctx.camera, movementSpeed * deltaTime)
	end

	if ctx.keyState[GLFW.KEY_X]
		if ctx.keyState[GLFW.KEY_LEFT_SHIFT] || ctx.keyState[GLFW.KEY_RIGHT_SHIFT]
			rotation = QuaternionNew(Vec3(1.0, 0.0, 0.0), rotationSpeed * deltaTime)
			GraphicsEntitySetRotation(ctx.e, rotation * ctx.e.worldRotation)
		else
			rotation = QuaternionNew(Vec3(1.0, 0.0, 0.0), -rotationSpeed * deltaTime)
			GraphicsEntitySetRotation(ctx.e, rotation * ctx.e.worldRotation)
		end
	end
	if ctx.keyState[GLFW.KEY_Y]
		if ctx.keyState[GLFW.KEY_LEFT_SHIFT] || ctx.keyState[GLFW.KEY_RIGHT_SHIFT]
			rotation = QuaternionNew(Vec3(0.0, 1.0, 0.0), rotationSpeed * deltaTime)
			GraphicsEntitySetRotation(ctx.e, rotation * ctx.e.worldRotation)
		else
			rotation = QuaternionNew(Vec3(0.0, 1.0, 0.0), -rotationSpeed * deltaTime)
			GraphicsEntitySetRotation(ctx.e, rotation * ctx.e.worldRotation)
		end
	end
	if ctx.keyState[GLFW.KEY_Z]
		if ctx.keyState[GLFW.KEY_LEFT_SHIFT] || ctx.keyState[GLFW.KEY_RIGHT_SHIFT]
			rotation = QuaternionNew(Vec3(0.0, 0.0, 1.0), rotationSpeed * deltaTime)
			GraphicsEntitySetRotation(ctx.e, rotation * ctx.e.worldRotation)
		else
			rotation = QuaternionNew(Vec3(0.0, 0.0, 1.0), -rotationSpeed * deltaTime)
			GraphicsEntitySetRotation(ctx.e, rotation * ctx.e.worldRotation)
		end
	end

	if ctx.keyState[GLFW.KEY_L]
		if ctx.wireframe
			glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
		else
			glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
		end

		ctx.wireframe = !ctx.wireframe
		ctx.keyState[GLFW.KEY_L] = false
	end
end

function CoreKeyPressProcess(ctx::CoreCtx, key::GLFW.Key, scanCode::Integer, action::GLFW.Action, mods::Integer)
	if action == GLFW.PRESS
		ctx.keyState[key] = true
	end

	if action == GLFW.RELEASE
		ctx.keyState[key] = false
	end
end

function CoreMouseChangeProcess(ctx::CoreCtx, reset::Bool, xPos::Real, yPos::Real)
	# This constant is basically the mouse sensibility.
	# @TODO: Allow mouse sensibility to be configurable.
	cameraMouseSpeed = 0.1

	if !reset
		xDiff = xPos - ctx.xPosOld
		yDiff = yPos - ctx.yPosOld

		CameraRotateX(ctx.camera, cameraMouseSpeed * xDiff)
		CameraRotateY(ctx.camera, cameraMouseSpeed * yDiff)
	end

	ctx.xPosOld = xPos
	ctx.yPosOld = yPos
end

function CoreMouseClickProcess(ctx::CoreCtx, button::GLFW.MouseButton, action::GLFW.Action, xPos::Real, yPos::Real)
	yPos = ctx.windowHeight - yPos
end

function CoreScrollChangeProcess(ctx::CoreCtx, xOffset::Real, yOffset::Real)
end

function CoreWindowResizeProcess(ctx::CoreCtx, windowWidth::Integer, windowHeight::Integer)
	ctx.windowWidth = windowWidth
	ctx.windowHeight = windowHeight
	CameraForceMatrixRecalculation(ctx.camera, windowWidth, windowHeight)
end
