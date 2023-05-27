local ffi = require("ffi")
local progress = require("modules/progress")

return function(env)
	local canvas1 = love.graphics.newCanvas(env.intersect, env.h, { format = "rgba32f" })
	local canvas2 = love.graphics.newCanvas(env.intersect, env.h, { format = "rgba32f" })

	--create target image
	love.graphics.push("all")
	love.graphics.setCanvas(canvas1)
	love.graphics.setShader(env.shaders.preMerge)
	env.shaders.preMerge:send("blend", env.mask)
	env.shaders.preMerge:send("second", env.rightImage)
	love.graphics.setBlendMode("replace")
	love.graphics.draw(env.leftImage)
	love.graphics.pop()

	--gradient
	local gradientImageData = love.image.newImageData(env.intersect, env.h, "rgba32f")
	local gradient = ffi.cast("float_pixel_t*", gradientImageData:getFFIPointer())
	local maskPointer = ffi.cast("float*", env.mask:newImageData():getFFIPointer())
	local function getGradient(x1, y1, x2, y2, r, g, b, a)
		local a1 = env.rightImagePointer[x1 + y1 * env.intersect]
		local a2 = env.rightImagePointer[x2 + y2 * env.intersect]
		local b1 = env.leftImagePointer[x1 + y1 * env.intersect]
		local b2 = env.leftImagePointer[x2 + y2 * env.intersect]
		local m = maskPointer[x2 + y2 * env.intersect]

		r = ((a1.r - a2.r) * m + (b1.r - b2.r) * (1 - m)) + r
		g = ((a1.g - a2.g) * m + (b1.g - b2.g) * (1 - m)) + g
		b = ((a1.b - a2.b) * m + (b1.b - b2.b) * (1 - m)) + b
		a = ((a1.a - a2.a) * m + (b1.a - b2.a) * (1 - m)) + a

		return r, g, b, a
	end
	for x = 0, env.intersect - 1 do
		for y = 0, env.h - 1 do
			local r, g, b, a = 0, 0, 0, 0
			if maskPointer[x + y * env.intersect] >= 0 then
				if x > 0 then
					r, g, b, a = getGradient(x, y, x - 1, y, r, g, b, a)
				end
				if x < env.intersect - 1 then
					r, g, b, a = getGradient(x, y, x + 1, y, r, g, b, a)
				end
				if y > 0 then
					r, g, b, a = getGradient(x, y, x, y - 1, r, g, b, a)
				end
				if y < env.h - 1 then
					r, g, b, a = getGradient(x, y, x, y + 1, r, g, b, a)
				end
			end
			gradient[x + y * env.intersect].r = r
			gradient[x + y * env.intersect].g = g
			gradient[x + y * env.intersect].b = b
			gradient[x + y * env.intersect].a = a
		end
	end
	progress(love.graphics.newImage(gradientImageData), "Finding stitching seam...")

	--poisson blend
	env.shaders.step:send("grad", love.graphics.newImage(gradientImageData))
	env.shaders.step:send("mask", env.mask)
	for epoch = 1, env.settings.poisson do
		for step = 1, 100 do
			love.graphics.push("all")
			love.graphics.setCanvas(canvas2)
			love.graphics.setShader(env.shaders.step)
			love.graphics.setBlendMode("replace")
			love.graphics.draw(canvas1)
			love.graphics.pop()
			canvas2, canvas1 = canvas1, canvas2
		end

		progress(canvas1, epoch)
	end

	--store result
	env.blendedImage = canvas1
end