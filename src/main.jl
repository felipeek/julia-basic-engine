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

const defaultWindowWidth = 1366
const defaultWindowHeight = 768
const ImGuiCtx = Ptr{CImGui.ImGuiContext}

include("vectors.jl")
include("quaternion.jl")
include("camera/camera.jl")
include("camera/free.jl")
include("camera/lookat.jl")
include("graphics.jl")
include("ui.jl")
include("core.jl")
include("util.jl")

function Start()
	function GlfwKeyCallback(window::GLFW.Window, key::GLFW.Key, scanCode::Integer, action::GLFW.Action, mods::Integer)
		imGuiIO = CImGui.GetIO()
		if !imGuiIO.WantCaptureKeyboard
			CoreKeyPressProcess(coreCtx, key, scanCode, action, mods)
		end
	end

	function GlfwCursorCallback(window::GLFW.Window, xPos::Real, yPos::Real)
		imGuiIO = CImGui.GetIO()
		if !imGuiIO.WantCaptureMouse
			CoreMouseChangeProcess(coreCtx, xPos, yPos)
		end
	end

	function GlfwMouseButtonCallback(window::GLFW.Window, button::GLFW.MouseButton, action::GLFW.Action, mods::Integer)
		imGuiIO = CImGui.GetIO()
		if !imGuiIO.WantCaptureMouse
			xPos, yPos = GLFW.GetCursorPos(window)
			CoreMouseClickProcess(coreCtx, button, action, xPos, yPos)
		end
	end

	function GlfwScrollCallback(window::GLFW.Window, xOffset::Real, yOffset::Real)
		imGuiIO = CImGui.GetIO()
		if !imGuiIO.WantCaptureMouse
			CoreScrollChangeProcess(coreCtx, xOffset, yOffset)
		end
	end

	function GlfwWindowResizeCallback(window::GLFW.Window, width::Integer, height::Integer)
		CoreWindowResizeProcess(coreCtx, width, height)
	end

	function GlfwFramebufferResizeCallback(window::GLFW.Window, width::Integer, height::Integer)
		CoreFramebufferResizeProcess(coreCtx, width, height)
	end

	function GlfwCharCallback(window::GLFW.Window, c::Char)
		imGuiIO = CImGui.GetIO()
		if !imGuiIO.WantCaptureKeyboard
			# no-op
		end
	end

	function GlfwInit()::GLFW.Window
		# OpenGL 3.3
		GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
		GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
		GLFW.WindowHint(GLFW.RESIZABLE, true)
		GLFW.WindowHint(GLFW.RESIZABLE, true)
		GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, true)
		GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)

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
		GLFW.SetWindowSizeCallback(window, GlfwWindowResizeCallback)
		GLFW.SetFramebufferSizeCallback(window, GlfwFramebufferResizeCallback)
		GLFW.SetInputMode(window, GLFW.CURSOR, GLFW.CURSOR_NORMAL)

		CImGui.SetCustomKeyCallback(GlfwKeyCallback)
		CImGui.SetCustomMouseButtonCallback(GlfwMouseButtonCallback)
		CImGui.SetCustomScrollCallback(GlfwScrollCallback)
		CImGui.SetCustomCharCallback(GlfwCharCallback)

		return window
	end

	function ImGuiInit(window::GLFW.Window)::ImGuiCtx
		# setup Dear ImGui context
		imGuiCtx = CImGui.CreateContext()

		# setup Dear ImGui style
		#CImGui.StyleColorsDark()
		#CImGui.StyleColorsClassic()
		CImGui.StyleColorsLight()

		# setup Platform/Renderer bindings
		ImGui_ImplGlfw_InitForOpenGL(window, true)
		glslVersion = 330 # (need to match GLFW.CONTEXT_VERSION_MAJOR and GLFW.CONTEXT_VERSION_MINOR)
		ImGui_ImplOpenGL3_Init(glslVersion)

		return imGuiCtx
	end
	
	function ImGuiDestroy(imGuiCtx::ImGuiCtx)
		ImGui_ImplOpenGL3_Shutdown()
		ImGui_ImplGlfw_Shutdown()
		CImGui.DestroyContext(imGuiCtx)
	end

	deltaTime = 0.0
	window = GlfwInit()

	windowWidth, windowHeight = GLFW.GetWindowSize(window)
	framebufferWidth, framebufferHeight = GLFW.GetFramebufferSize(window)

	imGuiCtx = ImGuiInit(window)
	coreCtx = CoreInit(windowWidth, windowHeight, framebufferWidth, framebufferHeight)

	glEnable(GL_DEPTH_TEST)
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

	lastFrame = time()
	frameNumber = trunc(Int, lastFrame)
	fps = 0

	try
		while !GLFW.WindowShouldClose(window)
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
			glClearColor(0.8, 0.8, 0.8, 1.0)

			CoreInputProcess(coreCtx, deltaTime)
			CoreUpdate(coreCtx, deltaTime)
			CoreRender(coreCtx)

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
		CoreDestroy(coreCtx)
		ImGuiDestroy(imGuiCtx)
		GLFW.DestroyWindow(window)
	end
end

Start()