# The more samples we have per channel, the more entities we will be able to process.
# However, if this number is too big, we might run into floating points issues
const NUM_SAMPLES_PER_CHANNEL = 1000

# NOTE(fek): We can only process NUM_SAMPLES_PER_CHANNEL * NUM_SAMPLES_PER_CHANNEL * NUM_SAMPLES_PER_CHANNEL triangles,
# because we use R, G, B channels.
# We need to discard one because we use <1, 1, 1> to indicate no entity.
const MAX_TRIANGLES = NUM_SAMPLES_PER_CHANNEL * NUM_SAMPLES_PER_CHANNEL * NUM_SAMPLES_PER_CHANNEL - 1;

function TriangleIndexToUniqueColor(index::Integer)::Vec4f
	index = index - 1

	@assert index < MAX_TRIANGLES - 1 "Index is too big"

	return Vec4f(
		(index % NUM_SAMPLES_PER_CHANNEL) / (NUM_SAMPLES_PER_CHANNEL - 1),
		((index ÷ NUM_SAMPLES_PER_CHANNEL) % NUM_SAMPLES_PER_CHANNEL) / (NUM_SAMPLES_PER_CHANNEL - 1),
		(((index ÷ NUM_SAMPLES_PER_CHANNEL) ÷ NUM_SAMPLES_PER_CHANNEL) % NUM_SAMPLES_PER_CHANNEL) / (NUM_SAMPLES_PER_CHANNEL - 1),
		1.0
	)
end

function TriangleUniqueColorToIndex(color::Vec4f)::Integer
	rContribution = round(Int, color[1] * (NUM_SAMPLES_PER_CHANNEL - 1))
	gContribution = round(Int, color[2] * (NUM_SAMPLES_PER_CHANNEL - 1) * NUM_SAMPLES_PER_CHANNEL)
	bContribution = round(Int, color[3] * (NUM_SAMPLES_PER_CHANNEL - 1) * NUM_SAMPLES_PER_CHANNEL * NUM_SAMPLES_PER_CHANNEL)

	return rContribution + gContribution + bContribution + 1
end

function AdjustSelectionBoxPoints(p1::Vec2, p2::Vec2, windowWidth::Integer, windowHeight::Integer)::Tuple{DVec2, DVec2}
	lowerLeftX = 0
	upperRightX = 0
	lowerLeftY = 0
	upperRightY = 0

	if p2[1] > p1[1]
      lowerLeftX = trunc(Int, p1[1] * windowWidth)
      upperRightX = trunc(Int, p2[1] * windowWidth)
    else
      lowerLeftX = trunc(Int, p2[1] * windowWidth)
      upperRightX = trunc(Int, p1[1] * windowWidth)
	end

    if p2[2] > p1[2]
      lowerLeftY = trunc(Int, p1[2] * windowHeight)
      upperRightY = trunc(Int, p2[2] * windowHeight)
    else
      lowerLeftY = trunc(Int, p2[2] * windowHeight)
      upperRightY = trunc(Int, p1[2] * windowHeight)
	end

	return DVec2(lowerLeftX, lowerLeftY), DVec2(upperRightX, upperRightY)
end

function GetTrianglesWithinSelectionBox(entity::Entity, graphicsCtx::GraphicsCtx, camera::Camera, windowWidth::Integer, windowHeight::Integer,
		selectionBoxP1::Vec2, selectionBoxP2::Vec2)
	fboRef = Ref{GLuint}(0)
	texRef = Ref{GLuint}(0)
	rboRef = Ref{GLuint}(0)
	glGenFramebuffers(1, fboRef)
	glGenTextures(1, texRef)
	glGenRenderbuffers(1, rboRef)

	fbo = fboRef[]
	tex = texRef[]
	rbo = rboRef[]

	glBindFramebuffer(GL_FRAMEBUFFER, fbo)
	glBindTexture(GL_TEXTURE_2D, tex)

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, windowWidth, windowHeight, 0, GL_RGBA, GL_FLOAT, C_NULL)
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0)

	glBindRenderbuffer(GL_RENDERBUFFER, rbo)
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, windowWidth, windowHeight)
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo)

	@assert glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE "Incomplete framebuffer"

	currentClearColorBuffer = fill(GLfloat(0.0), 4)
	glGetFloatv(GL_COLOR_CLEAR_VALUE, currentClearColorBuffer)

	glClearColor(1.0, 1.0, 1.0, 1.0)
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
	glEnable(GL_DEPTH_TEST)

	@assert length(entity.mesh.triangles) <= MAX_TRIANGLES

	GraphicsEntityRenderSelectionShader(graphicsCtx, camera, entity)

	lowerLeftBoxPoint, upperRightBoxPoint = AdjustSelectionBoxPoints(selectionBoxP1, selectionBoxP2, windowWidth, windowHeight)
	boxSize = DVec2(upperRightBoxPoint[1] - lowerLeftBoxPoint[1], upperRightBoxPoint[2] - lowerLeftBoxPoint[2])

	colorBufferChunk = fill(GLfloat(0.0), 4 * boxSize[1] * boxSize[2])

	glReadBuffer(GL_COLOR_ATTACHMENT0)
	glPixelStorei(GL_PACK_ALIGNMENT, 4)
	glReadPixels(lowerLeftBoxPoint[1], lowerLeftBoxPoint[2], boxSize[1], boxSize[2], GL_RGBA, GL_FLOAT, colorBufferChunk)

	selectedTrianglesIdxs = Set{Int64}()
	for i = 1:boxSize[1]
		for j = 1:boxSize[2]
			r = colorBufferChunk[1 + (j - 1) * boxSize[1] * 4 + (i - 1) * 4 + 0]
			g = colorBufferChunk[1 + (j - 1) * boxSize[1] * 4 + (i - 1) * 4 + 1]
			b = colorBufferChunk[1 + (j - 1) * boxSize[1] * 4 + (i - 1) * 4 + 2]

			entityIndex = TriangleUniqueColorToIndex(Vec4f(r, g, b, 1.0))
			@assert entityIndex - 1 <= MAX_TRIANGLES

			# If we got the final index, then it means there is no entity in this pixel
			if entityIndex - 1 == MAX_TRIANGLES
				continue
			end

			push!(selectedTrianglesIdxs, entityIndex)
		end
	end

	#img = Matrix{RGB{Float32}}(undef, boxSize[2], boxSize[1])

	#for i = 1:boxSize[2]
	#	for j = 1:boxSize[1]
	#		img[i, j] = RGB{Float32}(
	#			colorBufferChunk[1 + (i - 1) * boxSize[1] * 4 + (j - 1) * 4 + 0],
	#			colorBufferChunk[1 + (i - 1) * boxSize[1] * 4 + (j - 1) * 4 + 1],
	#			colorBufferChunk[1 + (i - 1) * boxSize[1] * 4 + (j - 1) * 4 + 2]
	#		)
	#	end
	#end

	#println("saving result.png ...")
	#save("result.png", img)
	#println("done.")

	glBindFramebuffer(GL_FRAMEBUFFER, 0)
	glDeleteRenderbuffers(1, rboRef)
	glDeleteTextures(1, texRef)
	glDeleteFramebuffers(1, fboRef)
	glClearColor(currentClearColorBuffer[1], currentClearColorBuffer[2], currentClearColorBuffer[3], currentClearColorBuffer[4])

	return selectedTrianglesIdxs
end