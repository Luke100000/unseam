return function(env)
	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setCanvas(env.finalCanvas)
	love.graphics.draw(env.blendedImage, -env.intersect / 2, 0)
	love.graphics.draw(env.blendedImage, env.w - env.intersect - env.intersect / 2 - env.crop, 0)
	love.graphics.pop()

	env.imageData = env.finalCanvas:newImageData()
	env.w = env.w - env.intersect - env.crop
end