function UiInit(window::GLFW.Window)
	# setup Dear ImGui context
	ctx = CImGui.CreateContext()

	# setup Dear ImGui style
	CImGui.StyleColorsDark()
	# CImGui.StyleColorsClassic()
	# CImGui.StyleColorsLight()

	# setup Platform/Renderer bindings
	ImGui_ImplGlfw_InitForOpenGL(window, true)
	glslVersion = 330 # (need to match GLFW.CONTEXT_VERSION_MAJOR and GLFW.CONTEXT_VERSION_MINOR)
	ImGui_ImplOpenGL3_Init(glslVersion)

	return ctx
end

function DrawMainWindow()
	if !CImGui.Begin("Menu")
		# Early out if the window is collapsed, as an optimization.
		CImGui.End()
		return
	end

	if CImGui.Button("Dummy")
		println("Hello World!")
	end

	CImGui.End()
end

function UiRender()
	# Start the Dear ImGui frame
	ImGui_ImplOpenGL3_NewFrame()
	ImGui_ImplGlfw_NewFrame()
	CImGui.NewFrame()
	
	CImGui.SetNextWindowPos(CImGui.ImVec2(650, 20), CImGui.ImGuiCond_FirstUseEver)
	CImGui.SetNextWindowSize(CImGui.ImVec2(550, 680), CImGui.ImGuiCond_FirstUseEver)

	DrawMainWindow()

	# Rendering
	CImGui.Render()
	ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())
end

function UiDestroy(ctx)
	# Cleanup
	ImGui_ImplOpenGL3_Shutdown()
	ImGui_ImplGlfw_Shutdown()
	CImGui.DestroyContext(ctx)
end