local ffi = require("ffi")

return function(env)
	env.intersect = math.ceil(env.settings.overlap * env.w)

	env.rightImage = love.graphics.newCanvas(env.intersect, env.h, { format = "rgba32f" })
	env.leftImage = love.graphics.newCanvas(env.intersect, env.h, { format = "rgba32f" })
	env.finalCanvas = love.graphics.newCanvas(env.w - env.intersect, env.h, { format = "rgba32f" })

	local image = love.graphics.newImage(env.imageData)

	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setCanvas(env.finalCanvas)
	love.graphics.draw(image, -env.intersect / 2, 0)
	love.graphics.setCanvas(env.leftImage)
	love.graphics.draw(image, 0, 0)
	love.graphics.setCanvas(env.rightImage)
	love.graphics.draw(image, env.intersect - env.w, 0)
	love.graphics.pop()

	env.leftImageData = env.leftImage:newImageData()
	env.leftImagePointer = ffi.cast("float_pixel_t*", env.leftImageData:getFFIPointer())

	env.rightImageData = env.rightImage:newImageData()
	env.rightImagePointer = ffi.cast("float_pixel_t*", env.rightImageData:getFFIPointer())
end