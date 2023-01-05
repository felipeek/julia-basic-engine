mutable struct SelectionBoxState
	active::Bool
	p1::Vec2
	p2::Vec2
end

mutable struct CameraMovementState
	isRotatingCamera::Bool
	isPanningCamera::Bool
	mouseChangeXPosOld::Real
	mouseChangeYPosOld::Real
	rotationSpeed::Real
	zoomSpeed::Real
	panningSpeed::Real
end

mutable struct CoreCtx
	graphicsCtx::GraphicsCtx

	camera::LookAtCamera
	lights::Vector{Light}
	e::Entity
	selectedTriangles::Vector{Bool}
	wireframe::Bool
	cameraMovementState::CameraMovementState
	selectionBoxState::SelectionBoxState

	windowWidth::Integer
	windowHeight::Integer
	keyState::AbstractDict{GLFW.Key, Bool}
end

function CreateCamera(windowWidth::Integer, windowHeight::Integer)::LookAtCamera
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
	#mesh = GraphicsMeshCreateFromObj("./res/spot.obj")
	#mesh = GraphicsMeshCreateFromObj("/home/felipeek/Development/masters/meshes/bunny.obj")
	mesh = GraphicsMeshCreateFromObj("/home/felipeek/Development/masters/meshes/scallop/scallop_half.obj")

	return GraphicsEntityCreate(mesh, Vec3(0.0, 0.0, 0.0), QuaternionNew(Vec3(0.0, 1.0, 0.0), 0.0), Vec3(1.0, 1.0, 1.0),
		Vec4(0.8, 0.8, 0.8, 1))
end

function CoreInit(windowWidth::Integer, windowHeight::Integer)::CoreCtx
	graphicsCtx = GraphicsInit()

	camera = CreateCamera(windowWidth, windowHeight)
	lights = CreateLights()
	e = CreateEntity()
	selectedTriangles = [false for i = 1:length(e.mesh.triangles)]
	wireframe = false
	keyState = DefaultDict{GLFW.Key, Bool}(false)
	cameraMovementState = CameraMovementState(false, false, 0, 0, 0.2, 0.1, 0.001)
	selectionBoxState = SelectionBoxState(false, Vec2(0, 0), Vec2(0, 0))

	return CoreCtx(graphicsCtx, camera, lights, e, selectedTriangles, wireframe, cameraMovementState,
		selectionBoxState, windowWidth, windowHeight, keyState)
end

function CoreDestroy(ctx::CoreCtx)
end

function CoreUpdate(ctx::CoreCtx, deltaTime::Real)
end

function CoreRender(ctx::CoreCtx)
	GraphicsEntityRenderPhongShader(ctx.graphicsCtx, ctx.camera, ctx.e, ctx.lights)
	#GraphicsEntityRenderBasicShader(ctx.graphicsCtx, ctx.camera, ctx.e)
	#GraphicsEntityRenderSelectionShader(ctx.graphicsCtx, ctx.camera, ctx.e)

	if ctx.selectionBoxState.active
		GraphicsSelectionBoxRender(
			ctx.graphicsCtx,
			MapRange(0.0, 1.0, -1.0, 1.0, ctx.selectionBoxState.p1),
			MapRange(0.0, 1.0, -1.0, 1.0, ctx.selectionBoxState.p2)
		)
	end
end

function CoreInputProcess(ctx::CoreCtx, deltaTime::Real)
	if ctx.keyState[GLFW.KEY_Z]
		# TODO: calculate this dynamically
		LookAtCameraSetLookAtPosition(ctx.camera, Vec3(0.0, 0.0, 0.0))
		LookAtCameraSetLookAtDistance(ctx.camera, 4.0)
		ctx.keyState[GLFW.KEY_Z] = false
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

	if ctx.keyState[GLFW.KEY_M]
		GraphicsMeshUpdate(ctx.e.mesh, ctx.e.mesh.vertices, ctx.e.mesh.triangles,
			Bool[i % 2 == 0 ? true : false for i=1:length(ctx.e.mesh.triangles)])
		ctx.keyState[GLFW.KEY_M] = false
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
	yPos = ctx.windowHeight - yPos

	if ctx.selectionBoxState.active
		ctx.selectionBoxState.p2 = Vec2(xPos / ctx.windowWidth, yPos / ctx.windowHeight)
	end

	if ctx.cameraMovementState.isRotatingCamera
		if !reset
			xDiff = xPos - ctx.cameraMovementState.mouseChangeXPosOld
			yDiff = yPos - ctx.cameraMovementState.mouseChangeYPosOld

			pitch = -ctx.cameraMovementState.rotationSpeed * xDiff
			yaw = ctx.cameraMovementState.rotationSpeed * yDiff
			LookAtCameraRotate(ctx.camera, -pitch, -yaw)
		end
	end

	if ctx.cameraMovementState.isPanningCamera
		if !reset
			xDiff = xPos - ctx.cameraMovementState.mouseChangeXPosOld
			yDiff = yPos - ctx.cameraMovementState.mouseChangeYPosOld

			yAxis = CameraGetYAxis(ctx.camera)
			inc = -ctx.cameraMovementState.panningSpeed * LookAtCameraGetLookAtDistance(ctx.camera) * yDiff * yAxis
			LookAtCameraSetLookAtPosition(ctx.camera, LookAtCameraGetLookAtPosition(ctx.camera) + inc)

			xAxis = CameraGetXAxis(ctx.camera)
			inc = -ctx.cameraMovementState.panningSpeed * LookAtCameraGetLookAtDistance(ctx.camera) * xDiff * xAxis
			LookAtCameraSetLookAtPosition(ctx.camera, LookAtCameraGetLookAtPosition(ctx.camera) + inc)
		end
	end

	ctx.cameraMovementState.mouseChangeXPosOld = xPos
	ctx.cameraMovementState.mouseChangeYPosOld = yPos
end

function HandleSelection(ctx::CoreCtx, unselect::Bool)
	if ctx.selectionBoxState.p1 == ctx.selectionBoxState.p2
		return
	end

	selectedTrianglesIdxs = GetTrianglesWithinSelectionBox(ctx.e, ctx.graphicsCtx, ctx.camera, ctx.windowWidth, ctx.windowHeight,
		ctx.selectionBoxState.p1, ctx.selectionBoxState.p2, 2048)

	for idx in selectedTrianglesIdxs
		ctx.selectedTriangles[idx] = !unselect
	end

	GraphicsMeshUpdate(ctx.e.mesh, ctx.e.mesh.vertices, ctx.e.mesh.triangles, ctx.selectedTriangles)
end

function CoreMouseClickProcess(ctx::CoreCtx, button::GLFW.MouseButton, action::GLFW.Action, mods::Integer, xPos::Real, yPos::Real)
	yPos = ctx.windowHeight - yPos

	if button == GLFW.MOUSE_BUTTON_1 # left click
		if action == GLFW.PRESS
			if !ctx.selectionBoxState.active
				ctx.selectionBoxState.active = true
				ctx.selectionBoxState.p1 = Vec2(xPos / ctx.windowWidth, yPos / ctx.windowHeight)
				ctx.selectionBoxState.p2 = ctx.selectionBoxState.p1
			end
		end

		if action == GLFW.RELEASE
			if ctx.selectionBoxState.active
				ctx.selectionBoxState.active = false
				ctx.selectionBoxState.p2 = Vec2(xPos / ctx.windowWidth, yPos / ctx.windowHeight)
				HandleSelection(ctx, mods == GLFW.MOD_CONTROL)
			end
		end
	elseif button == GLFW.MOUSE_BUTTON_2 # right click
		if action == GLFW.PRESS
			ctx.cameraMovementState.isRotatingCamera = true
		end

		if action == GLFW.RELEASE
			ctx.cameraMovementState.isRotatingCamera = false
		end
	elseif button == GLFW.MOUSE_BUTTON_3
		if action == GLFW.PRESS
			ctx.cameraMovementState.isPanningCamera = true
		end

		if action == GLFW.RELEASE
			ctx.cameraMovementState.isPanningCamera = false
		end
	end
end

function CoreScrollChangeProcess(ctx::CoreCtx, xOffset::Real, yOffset::Real)
	currentLookAtDistance = LookAtCameraGetLookAtDistance(ctx.camera)
	LookAtCameraSetLookAtDistance(ctx.camera, currentLookAtDistance - yOffset *	ctx.cameraMovementState.zoomSpeed)
end

function CoreWindowResizeProcess(ctx::CoreCtx, windowWidth::Integer, windowHeight::Integer)
	ctx.windowWidth = windowWidth
	ctx.windowHeight = windowHeight
	CameraForceMatrixRecalculation(ctx.camera, windowWidth, windowHeight)
end
