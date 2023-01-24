const MENU_TITLE = "Menu (Press ESC to Show/Hide menu)"

mutable struct UiCtx
end

function UiInit()
	ctx = UiCtx()
	return ctx
end

function DrawMainWindow(ctx::UiCtx)
	if !CImGui.Begin(MENU_TITLE)
		# Early out if the window is collapsed, as an optimization.
		CImGui.End()
		return
	end

	if CImGui.Button("Dummy")
		println("Hello World!")
	end

	CImGui.End()
end

function UiRender(ctx::UiCtx, isUiActive::Bool)
	# Start the Dear ImGui frame
	ImGui_ImplOpenGL3_NewFrame()
	ImGui_ImplGlfw_NewFrame()
	CImGui.NewFrame()
	
	CImGui.SetNextWindowPos(CImGui.ImVec2(650, 20), CImGui.ImGuiCond_FirstUseEver)
	CImGui.SetNextWindowSize(CImGui.ImVec2(550, 680), CImGui.ImGuiCond_FirstUseEver)

	if isUiActive
		DrawMainWindow(ctx)
	end

	# Rendering
	CImGui.Render()
	ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())
end

function UiDestroy(ctx::UiCtx)
end