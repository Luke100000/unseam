local ffi = require("ffi")
local progress = require("modules/progress")

return function(env)
	local canvas1 = love.graphics.newCanvas(env.w, env.h, { format = "rgba32f" })
	local canvas2 = love.graphics.newCanvas(env.w, env.h, { format = "rgba32f" })

	--create target image
	love.graphics.push("all")
	love.graphics.setCanvas(canvas1)
	love.graphics.setShader(env.shaders.preMerge)
	env.shaders.preMerge:send("blend", env.mask)
	env.shaders.preMerge:send("second", env.image)
	love.graphics.setBlendMode("replace")
	love.graphics.draw(env.shiftedImage)
	love.graphics.pop()

	--gradient
	local gradientImageData = love.image.newImageData(env.w, env.h, "rgba32f")
	local gradient = ffi.cast("float_pixel_t*", gradientImageData:getFFIPointer())
	local maskPointer = ffi.cast("float*", env.mask:newImageData():getFFIPointer())
	local function getGradient(x1, y1, x2, y2, r, g, b, a)
		local a1 = env.imagePointer[x1 + y1 * env.w]
		local a2 = env.imagePointer[x2 + y2 * env.w]
		local b1 = env.imagePointer[(x1 + env.hw) % env.w + y1 * env.w]
		local b2 = env.imagePointer[(x2 + env.hw) % env.w + y2 * env.w]
		local m = maskPointer[x1 + y1 * env.w]

		r = ((a1.r - a2.r) * m + (b1.r - b2.r) * (1 - m)) + r
		g = ((a1.g - a2.g) * m + (b1.g - b2.g) * (1 - m)) + g
		b = ((a1.b - a2.b) * m + (b1.b - b2.b) * (1 - m)) + b
		a = ((a1.a - a2.a) * m + (b1.a - b2.a) * (1 - m)) + a

		return r, g, b, a
	end
	for x = 0, env.w - 1 do
		for y = 0, env.h - 1 do
			local r, g, b, a = 0, 0, 0, 0
			if maskPointer[x + y * env.w] >= 0 then
				if x > 0 then
					r, g, b, a = getGradient(x - 1, y, x, y, r, g, b, a)
				end
				if x < env.w - 1 then
					r, g, b, a = getGradient(x + 1, y, x, y, r, g, b, a)
				end
				if y > 0 then
					r, g, b, a = getGradient(x, y - 1, x, y, r, g, b, a)
				end
				if y < env.h - 1 then
					r, g, b, a = getGradient(x, y + 1, x, y, r, g, b, a)
				end
			end
			gradient[x + y * env.w].r = -r --todo
			gradient[x + y * env.w].g = -g
			gradient[x + y * env.w].b = -b
			gradient[x + y * env.w].a = -a
		end
	end
	progress(love.graphics.newImage(gradientImageData), "Finding stitching seam...")

	--poisson blend
	env.shaders.step:send("grad", love.graphics.newImage(gradientImageData))
	env.shaders.step:send("mask", env.mask)
	for epoch = 1, 64 do
		for step = 1, 64 do
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
	env.finalImage = canvas1
end