using Pkg
Pkg.activate(joinpath(@__DIR__, "../juliadeps/julia-basic-engine"))
Pkg.instantiate()

using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using CImGui.GLFWBackend
using CImGui.OpenGLBackend
using CImGui.GLFWBackend.GLFW
using CImGui.OpenGLBackend.ModernGL
using Printf
using StaticArrays
using FileIO
using MeshIO
using LinearAlgebra
using DataStructures
#using Images

const defaultWindowWidth = 1366
const defaultWindowHeight = 768

include("vectors.jl")
include("quaternion.jl")
include("camera.jl")
include("graphics.jl")
include("selection.jl")
include("ui.jl")
include("core.jl")
include("util.jl")

function Start()
	function GlfwKeyCallback(window::GLFW.Window, key::GLFW.Key, scanCode::Integer, action::GLFW.Action, mods::Integer)
		if !isMenuVisible
			CoreKeyPressProcess(coreCtx, key, scanCode, action, mods)
		end

		if key == GLFW.KEY_ESCAPE && action == GLFW.PRESS
			if isMenuVisible
				#GLFW.SetInputMode(window, GLFW.CURSOR, GLFW.CURSOR_DISABLED)
			else
				GLFW.SetInputMode(window, GLFW.CURSOR, GLFW.CURSOR_NORMAL)
			end

			isMenuVisible = !isMenuVisible
		end
	end

	function GlfwCursorCallback(window::GLFW.Window, xPos::Real, yPos::Real)
		if !isMenuVisible
			CoreMouseChangeProcess(coreCtx, resetCoreMouseMovement, xPos, yPos)
			resetCoreMouseMovement = false
		else
			resetCoreMouseMovement = true
		end
	end

	function GlfwMouseButtonCallback(window::GLFW.Window, button::GLFW.MouseButton, action::GLFW.Action, mods::Integer)
		xPos, yPos = GLFW.GetCursorPos(window)
		
		if !isMenuVisible
			CoreMouseClickProcess(coreCtx, button, action, mods, xPos, yPos)
		end
	end

	function GlfwScrollCallback(window::GLFW.Window, xOffset::Real, yOffset::Real)
		if !isMenuVisible
			CoreScrollChangeProcess(coreCtx, xOffset, yOffset)
		end
	end

	function GlfwResizeCallback(window::GLFW.Window, width::Integer, height::Integer)
		glViewport(0, 0, width, height)
		CoreWindowResizeProcess(coreCtx, width, height)
	end

	function GlfwCharCallback(window::GLFW.Window, c::Char)
	end

	function GlfwInit()::GLFW.Window
		# OpenGL 3.3
		GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
		GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
		GLFW.WindowHint(GLFW.RESIZABLE, true)
		GLFW.WindowHint(GLFW.RESIZABLE, true)
		GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, true)
		GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
		#GLFW.WindowHint(GLFW.OPENGL_DEBUG_CONTEXT, true)

		# setup GLFW error callback
		ErrorCallback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
		GLFW.SetErrorCallback(ErrorCallback)

		# create window
		window = GLFW.CreateWindow(defaultWindowWidth, defaultWindowHeight, "Julia Basic Engine")
		@assert window != C_NULL
		GLFW.SetWindowPos(window, 50, 50)
		GLFW.MakeContextCurrent(window)
		GLFW.SwapInterval(1)	# enable vsync

		GLFW.SetKeyCallback(window, GlfwKeyCallback)
		GLFW.SetCursorPosCallback(window, GlfwCursorCallback)
		GLFW.SetWindowSizeCallback(window, GlfwResizeCallback)
		GLFW.SetInputMode(window, GLFW.CURSOR, GLFW.CURSOR_NORMAL)

		CImGui.SetCustomKeyCallback(GlfwKeyCallback)
		CImGui.SetCustomMouseButtonCallback(GlfwMouseButtonCallback)
		CImGui.SetCustomScrollCallback(GlfwScrollCallback)
		CImGui.SetCustomCharCallback(GlfwCharCallback)

		return window
	end

	# Used in GLFW callbacks
	isMenuVisible = true
	resetCoreMouseMovement = true

	deltaTime = 0.0
	window = GlfwInit()

	coreCtx = CoreInit(defaultWindowWidth, defaultWindowHeight)

	glEnable(GL_DEPTH_TEST)
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

	lastFrame = time()
	frameNumber = trunc(Int, lastFrame)
	fps = 0

	imGuiCtx = UiInit(window)

	try
		while !GLFW.WindowShouldClose(window)
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
			glClearColor(0.8, 0.8, 0.8, 1.0)

			CoreUpdate(coreCtx, deltaTime)
			CoreRender(coreCtx)
			if !isMenuVisible
				CoreInputProcess(coreCtx, deltaTime)
			else
				UiRender()
			end

			GLFW.PollEvents()
			GLFW.SwapBuffers(window)

			currentFrame = time()
			if trunc(Int, currentFrame) > frameNumber
				fps = 0
				frameNumber = frameNumber + 1
			else
				fps = fps + 1
			end

			deltaTime = currentFrame - lastFrame
			lastFrame = currentFrame
		end
	catch ex
		@error "Error in renderloop!" exception=ex
		Base.show_backtrace(stderr, catch_backtrace())
	finally
		UiDestroy(imGuiCtx)
		GLFW.DestroyWindow(window)
	end
end

Start()