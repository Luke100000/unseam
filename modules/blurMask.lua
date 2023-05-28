local progress = require("modules/progress")

return function(env)
	local canvas1 = love.graphics.newCanvas(env.intersect, env.h, { format = "r32f" })
	local canvas2 = love.graphics.newCanvas(env.intersect, env.h, { format = "r32f" })

	--create target image
	love.graphics.setCanvas(canvas1)
	love.graphics.setBlendMode("replace")
	local rawMask = love.graphics.newImage(love.image.newImageData(env.intersect, env.h, "r32f", env.sourceSinkByteData))
	love.graphics.draw(rawMask)
	love.graphics.setCanvas()

	for epoch = math.ceil(env.settings.blurStrength * math.sqrt(env.intersect ^ 2 + env.h ^ 2)), 1, -1 do
		local size = math.sqrt(epoch)
		for i = 1, 2 do
			love.graphics.push("all")
			love.graphics.setCanvas(canvas2)
			love.graphics.setShader(env.shaders.blur)
			env.shaders.blur:send("contrast", env.contrastCanvas)
			env.shaders.blur:send("dir", i % 2 == 0 and { size / env.intersect, 0 } or { 0, size / env.h })
			love.graphics.setBlendMode("replace")
			love.graphics.draw(canvas1)
			love.graphics.setShader()
			love.graphics.pop()
			canvas2, canvas1 = canvas1, canvas2
		end

		progress(canvas1, epoch .. "%")
	end

	env.mask = canvas1
end