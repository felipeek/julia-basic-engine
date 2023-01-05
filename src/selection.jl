const NUM_SAMPLES_PER_CHANNEL = 1000

function TriangleIndexToUniqueColor(index::Integer)
	index = index - 1

	return Vec4f(
		(index % NUM_SAMPLES_PER_CHANNEL) / (NUM_SAMPLES_PER_CHANNEL - 1),
		((index / NUM_SAMPLES_PER_CHANNEL) % NUM_SAMPLES_PER_CHANNEL) / (NUM_SAMPLES_PER_CHANNEL - 1),
		(((index / NUM_SAMPLES_PER_CHANNEL) / NUM_SAMPLES_PER_CHANNEL) % NUM_SAMPLES_PER_CHANNEL) / (NUM_SAMPLES_PER_CHANNEL - 1),
		1.0
	)
end

function TriangleUniqueColorToIndex(color::Vec4f)
	rContribution = round(Int, color.r * (NUM_SAMPLES_PER_CHANNEL - 1))
	gContribution = round(Int, color.g * (NUM_SAMPLES_PER_CHANNEL - 1) * NUM_SAMPLES_PER_CHANNEL)
	bContribution = round(Int, color.b * (NUM_SAMPLES_PER_CHANNEL - 1) * NUM_SAMPLES_PER_CHANNEL * NUM_SAMPLES_PER_CHANNEL)

	return rContribution + gContribution + bContribution + 1
end