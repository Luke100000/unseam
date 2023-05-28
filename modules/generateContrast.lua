local progress = require("modules/progress")

return function(env)
	local scale = env.settings.contrastResolution / math.sqrt(env.intersect ^ 2 + env.h ^ 2)
	local w = math.ceil(env.intersect * scale)
	local h = math.ceil(env.h * scale)
	print(w, h)
	local canvasPre = env.settings.dynamicBlur and love.graphics.newCanvas(w, h, { format = "r32f" })
	env.contrastCanvas = love.graphics.newCanvas(w, h, { format = "r32f" })

	love.graphics.push("all")
	love.graphics.reset()

	--Alpha blend the two sides
	if env.settings.dynamicBlur then
		love.graphics.setCanvas(canvasPre)
		love.graphics.draw(env.leftImage, 0, 0, 0, w / env.leftImage:getWidth(), h / env.leftImage:getHeight())
		love.graphics.setColor(1, 1, 1, 0.5)
		love.graphics.draw(env.rightImage, 0, 0, 0, w / env.rightImage:getWidth(), h / env.rightImage:getHeight())
	end

	--Generate contrast
	love.graphics.setCanvas(env.contrastCanvas)

	if env.settings.dynamicBlur then
		love.graphics.setShader(env.shaders.contrast)
		love.graphics.draw(canvasPre)
	else
		love.graphics.clear(0.5, 0.5, 0.5, 1.0)
	end

	love.graphics.pop()

	env.shaders.r:send("factor", 1.0)
	progress(env.contrastCanvas, "Generating contrast", env.shaders.r)
end