mutable struct CoreCtx
	graphicsCtx::GraphicsCtx

	# Camera-related atrtibutes
	camera::Camera
	useFreeCamera::Bool
	isRotatingCamera::Bool
	isPanningCamera::Bool
	alternativePanningMethod::Bool
	rotationSpeed::Real
	zoomSpeed::Real
	panningSpeed::Real
	considerMouseClickCoordsWhenRotating::Bool

	lights::Vector{Light}
	e::Entity
	wireframe::Bool
	mouseChangeXPosOld::Real
	mouseChangeYPosOld::Real

	windowWidth::Integer
	windowHeight::Integer
	keyState::AbstractDict{GLFW.Key, Bool}
end

function CreateFreeCamera(windowWidth::Integer, windowHeight::Integer)::FreeCamera
	cameraPosition = Vec3(0.0, 0.0, 4.0)
	cameraNearPlane = -0.01
	cameraFarPlane = -1000.0
	cameraFov = 45.0
	return FreeCamera(cameraPosition, cameraNearPlane, cameraFarPlane, cameraFov, windowWidth, windowHeight)
end

function CreateLookAtCamera(windowWidth::Integer, windowHeight::Integer)::LookAtCamera
	lookAtPosition = Vec3(0.0, 0.0, 0.0)
	lookAtDistance = 4.0
	cameraNearPlane = -0.01
	cameraFarPlane = -1000.0
	cameraFov = 45.0
	return LookAtCamera(lookAtPosition, lookAtDistance, cameraNearPlane, cameraFarPlane, cameraFov, windowWidth, windowHeight)
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

function CoreInit(windowWidth::Integer, windowHeight::Integer, useFreeCamera::Bool)::CoreCtx
	graphicsCtx = GraphicsInit()

	camera = useFreeCamera ? CreateFreeCamera(windowWidth, windowHeight) : CreateLookAtCamera(windowWidth, windowHeight)
	lights = CreateLights()
	e = CreateEntity()
	wireframe = false
	keyState = DefaultDict{GLFW.Key, Bool}(false)

	return CoreCtx(graphicsCtx, camera, useFreeCamera, false, false, false,  0.2, 0.1, 0.001, true, lights, e, wireframe, 0, 0, windowWidth, windowHeight, keyState)
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

	if ctx.keyState[GLFW.KEY_LEFT_SHIFT]
		movementSpeed = 0.5
	end
	if ctx.keyState[GLFW.KEY_RIGHT_SHIFT]
		movementSpeed = 0.1
	end

	if ctx.useFreeCamera
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
	xDiff = xPos - ctx.mouseChangeXPosOld
	yDiff = yPos - ctx.mouseChangeYPosOld

	if ctx.useFreeCamera
		if !reset
			cameraMouseSpeed = 0.1
			CameraRotateX(ctx.camera, cameraMouseSpeed * xDiff)
			CameraRotateY(ctx.camera, cameraMouseSpeed * yDiff)
		end
	else
		yPos = ctx.windowHeight - yPos

		if ctx.isRotatingCamera
			if !reset
				pitch = -ctx.rotationSpeed * xDiff
				yaw = ctx.rotationSpeed * yDiff

				if ctx.considerMouseClickCoordsWhenRotating
					mouseX, mouseY = WindowNormalizeCoordsToNdc(ctx.mouseChangeXPosOld, ctx.mouseChangeYPosOld,
						ctx.windowWidth, ctx.windowHeight)
					LookAtCameraRotateConsideringClickCoords(ctx.camera, -pitch, -yaw, -mouseX, mouseY)
				else
					LookAtCameraRotate(ctx.camera, -pitch, -yaw)
				end
			end
		end

		if ctx.isPanningCamera
			if !reset
				yAxis = CameraGetYAxis(ctx.camera)
				inc = -ctx.panningSpeed * LookAtCameraGetLookAtDistance(ctx.camera) * yDiff * yAxis
				LookAtCameraSetLookAtPosition(ctx.camera, LookAtCameraGetLookAtPosition(ctx.camera) + inc)

				xAxis = CameraGetXAxis(ctx.camera)
				inc = -ctx.panningSpeed * LookAtCameraGetLookAtDistance(ctx.camera) * xDiff * xAxis
				LookAtCameraSetLookAtPosition(ctx.camera, LookAtCameraGetLookAtPosition(ctx.camera) + inc)
			end
		end
	end

	ctx.mouseChangeXPosOld = xPos
	ctx.mouseChangeYPosOld = yPos
end

function CoreMouseClickProcess(ctx::CoreCtx, button::GLFW.MouseButton, action::GLFW.Action, xPos::Real, yPos::Real)
	yPos = ctx.windowHeight - yPos

	if !ctx.useFreeCamera
		if button == GLFW.MOUSE_BUTTON_2 # right click
			if action == GLFW.PRESS
				ctx.isRotatingCamera = true
			end

			if action == GLFW.RELEASE
				ctx.isRotatingCamera = false
			end
		elseif button == GLFW.MOUSE_BUTTON_3
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
		currentLookAtDistance = LookAtCameraGetLookAtDistance(ctx.camera)
		LookAtCameraSetLookAtDistance(ctx.camera, currentLookAtDistance - yOffset * ctx.zoomSpeed)
	end
end

function CoreWindowResizeProcess(ctx::CoreCtx, windowWidth::Integer, windowHeight::Integer)
	ctx.windowWidth = windowWidth
	ctx.windowHeight = windowHeight
	CameraForceMatrixRecalculation(ctx.camera, windowWidth, windowHeight)
end
