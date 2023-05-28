local ffi = require("ffi")

local function getTargetWidth(env, w)
	if env.settings.scaleToNextN2 then
		local minOverlap = math.ceil(w * env.settings.minOverlap)
		local nextResolution = 2 ^ math.floor(math.log(w, 2))
		if w - nextResolution < minOverlap then
			nextResolution = nextResolution / 2
		end
		return nextResolution
	else
		local intersect = math.ceil(env.settings.overlap * w)
		return w - intersect
	end
end

return function(env)
	local targetWidth = getTargetWidth(env, env.w)

	--Crop to make it a square
	if env.settings.outputSquare and env.dimension == 1 then
		targetWidth = math.min(targetWidth, getTargetWidth(env, env.h))
	end

	--Crop it respectively
	local maxOverlap = math.floor(env.w / 2)
	env.intersect = math.min(maxOverlap, env.w - targetWidth)
	env.crop = math.max(0, (env.w - targetWidth) - env.intersect)

	--Create workspace canvases
	env.rightImage = love.graphics.newCanvas(env.intersect, env.h, { format = "rgba32f" })
	env.leftImage = love.graphics.newCanvas(env.intersect, env.h, { format = "rgba32f" })
	env.finalCanvas = love.graphics.newCanvas(env.w - env.intersect - env.crop, env.h, { format = "rgba32f" })

	local image = love.graphics.newImage(env.imageData)

	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setCanvas(env.finalCanvas)
	love.graphics.draw(image, -env.intersect / 2, 0)
	love.graphics.setCanvas(env.leftImage)
	love.graphics.draw(image, 0, 0)
	love.graphics.setCanvas(env.rightImage)
	love.graphics.draw(image, env.intersect - env.w + env.crop, 0)
	love.graphics.pop()

	env.leftImageData = env.leftImage:newImageData()
	env.leftImagePointer = ffi.cast("float_pixel_t*", env.leftImageData:getFFIPointer())

	env.rightImageData = env.rightImage:newImageData()
	env.rightImagePointer = ffi.cast("float_pixel_t*", env.rightImageData:getFFIPointer())
end