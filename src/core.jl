mutable struct CoreCtx
	graphicsCtx::GraphicsCtx
	uiCtx::UiCtx
	isUiActive::Bool

	lights::Vector{Light}
	e::Entity
	wireframe::Bool

	# Camera-related atrtibutes
	camera::Camera
	useFreeCamera::Bool
	isRotatingCamera::Bool
	isPanningCamera::Bool
	alternativePanningMethod::Bool # if true, pan via shift instead of mouse3
	mouseChangeXPosOld::Real
	mouseChangeYPosOld::Real

	# Window/Input State
	windowWidth::Integer
	windowHeight::Integer
	framebufferWidth::Integer
	framebufferHeight::Integer
	keyState::AbstractDict{GLFW.Key, Bool}
end

function CreateFreeCamera(windowWidth::Integer, windowHeight::Integer)::FreeCamera
	cameraPosition = Vec3(0.0, 0.0, 4.0)
	cameraNearPlane = -0.01
	cameraFarPlane = -1000.0
	cameraFov = 45.0
	movementSpeed = 3.0
	rotationSpeed = 0.05
	return FreeCamera(cameraPosition, cameraNearPlane, cameraFarPlane, cameraFov, windowWidth, windowHeight, true, movementSpeed,
		rotationSpeed)
end

function CreateLookAtCamera(windowWidth::Integer, windowHeight::Integer)::LookAtCamera
	lookAtPosition = Vec3(0.0, 0.0, 0.0)
	lookAtDistance = 4.0
	cameraNearPlane = -0.01
	cameraFarPlane = -1000.0
	cameraFov = 45.0
	zoomSpeed = 0.2
	rotationSpeed = 0.1
	panningSpeed = 0.001
	return LookAtCamera(lookAtPosition, lookAtDistance, cameraNearPlane, cameraFarPlane, cameraFov, windowWidth, windowHeight, true,
		zoomSpeed, rotationSpeed, panningSpeed)
end

function CreateLights()::Vector{Light}
	lights = Vector{Light}()

	lightPosition = Vec3(0.0, 0.0, 15.0)
	ambientColor = Vec4(0.1, 0.1, 0.1, 1.0)
	diffuseColor = Vec4(0.8, 0.8, 0.8, 1.0)
	specularColor = Vec4(0.5, 0.5, 0.5, 1.0)
	light = Light(lightPosition, ambientColor, diffuseColor, specularColor)
	push!(lights, light)

	lightPosition = Vec3(0.0, 0.0, -15.0)
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

function CoreInit(windowWidth::Integer, windowHeight::Integer, framebufferWidth::Integer, framebufferHeight::Integer)::CoreCtx
	glViewport(0, 0, framebufferWidth, framebufferHeight)
	graphicsCtx = GraphicsInit()
	uiCtx = UiInit()

	useFreeCamera = false
	camera = useFreeCamera ? CreateFreeCamera(windowWidth, windowHeight) : CreateLookAtCamera(windowWidth, windowHeight)
	lights = CreateLights()
	e = CreateEntity()
	wireframe = false
	keyState = DefaultDict{GLFW.Key, Bool}(false)

	return CoreCtx(graphicsCtx, uiCtx, false, lights, e, wireframe, camera, useFreeCamera, false, false, false, 0, 0,
		windowWidth, windowHeight, framebufferWidth, framebufferHeight, keyState)
end

function CoreDestroy(ctx::CoreCtx)
	UiDestroy(ctx.uiCtx)
end

function CoreUpdate(ctx::CoreCtx, deltaTime::Real)
end

function CoreRender(ctx::CoreCtx)
	GraphicsEntityRenderPhongShader(ctx.graphicsCtx, ctx.camera, ctx.e, ctx.lights)
	UiRender(ctx.uiCtx, ctx.isUiActive)
end

function CoreInputProcess(ctx::CoreCtx, deltaTime::Real)
	cameraMovementMultiplier = 1.0

	if ctx.keyState[GLFW.KEY_LEFT_SHIFT]
		cameraMovementMultiplier = 0.5
	end
	if ctx.keyState[GLFW.KEY_RIGHT_SHIFT]
		cameraMovementMultiplier = 0.1
	end

	if ctx.useFreeCamera
		if ctx.keyState[GLFW.KEY_W]
			CameraMoveForward(ctx.camera, cameraMovementMultiplier * deltaTime)
		end
		if ctx.keyState[GLFW.KEY_S]
			CameraMoveForward(ctx.camera, -cameraMovementMultiplier * deltaTime)
		end
		if ctx.keyState[GLFW.KEY_A]
			CameraMoveRight(ctx.camera, -cameraMovementMultiplier * deltaTime)
		end
		if ctx.keyState[GLFW.KEY_D]
			CameraMoveRight(ctx.camera, cameraMovementMultiplier * deltaTime)
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

	if ctx.keyState[GLFW.KEY_KP_DECIMAL]
		if !ctx.useFreeCamera
			LookAtCameraSetLookAtPosition(ctx.camera, Vec3(0, 0, 0))
			ctx.keyState[GLFW.KEY_KP_DECIMAL] = false
		end
	end

	if ctx.alternativePanningMethod
		if !ctx.keyState[GLFW.KEY_LEFT_SHIFT] && !ctx.keyState[GLFW.KEY_RIGHT_SHIFT]
			ctx.isPanningCamera = false
		else
			ctx.isPanningCamera = true
		end
	end

	if ctx.keyState[GLFW.KEY_ESCAPE]
		ctx.isUiActive = !ctx.isUiActive
		ctx.keyState[GLFW.KEY_ESCAPE] = false
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

function CoreMouseChangeProcess(ctx::CoreCtx, xPos::Real, yPos::Real)
	xDiff = xPos - ctx.mouseChangeXPosOld
	yDiff = yPos - ctx.mouseChangeYPosOld

	mouseX, mouseY = WindowNormalizeCoordsToNdc(ctx.mouseChangeXPosOld, ctx.mouseChangeYPosOld,
		ctx.windowWidth, ctx.windowHeight)

	if ctx.isRotatingCamera
		CameraRotate(ctx.camera, xDiff, yDiff, mouseX, mouseY)
	end

	if ctx.isPanningCamera
		LookAtCameraPan(ctx.camera, xDiff, yDiff)
	end

	ctx.mouseChangeXPosOld = xPos
	ctx.mouseChangeYPosOld = yPos
end

function CoreMouseClickProcess(ctx::CoreCtx, button::GLFW.MouseButton, action::GLFW.Action, xPos::Real, yPos::Real)
	yPos = ctx.windowHeight - yPos

	if button == GLFW.MOUSE_BUTTON_2
		if action == GLFW.PRESS
			ctx.isRotatingCamera = true
		end

		if action == GLFW.RELEASE
			ctx.isRotatingCamera = false
		end
	end

	if !ctx.useFreeCamera
		if button == GLFW.MOUSE_BUTTON_3
			if !ctx.alternativePanningMethod
				if action == GLFW.PRESS
					ctx.isPanningCamera = true
				end

				if action == GLFW.RELEASE
					ctx.isPanningCamera = false
				end
			end
		end
	end
end

function CoreScrollChangeProcess(ctx::CoreCtx, xOffset::Real, yOffset::Real)
	if !ctx.useFreeCamera
		LookAtCameraApproximate(ctx.camera, yOffset)
	end
end

function CoreWindowResizeProcess(ctx::CoreCtx, windowWidth::Integer, windowHeight::Integer)
	ctx.windowWidth = windowWidth
	ctx.windowHeight = windowHeight
	CameraForceMatrixRecalculation(ctx.camera, windowWidth, windowHeight)
end

function CoreFramebufferResizeProcess(ctx::CoreCtx, framebufferWidth::Integer, framebufferHeight::Integer)
	ctx.framebufferWidth = framebufferWidth
	ctx.framebufferHeight = framebufferHeight
	glViewport(0, 0, ctx.framebufferWidth, ctx.framebufferHeight)
end
