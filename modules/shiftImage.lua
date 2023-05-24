local mesh = love.graphics.newMesh({
	{ 0, 0, 0.5, 0, 1, 1, 1, 1 },
	{ 1, 0, 1.5, 0, 1, 1, 1, 1 },
	{ 1, 1, 1.5, 1, 1, 1, 1, 1 },
	{ 0, 1, 0.5, 1, 1, 1, 1, 1 },
})

return function(env)
	env.shiftedImage = love.graphics.newCanvas(env.w, env.h, { format = "rgba32f" })

	love.graphics.setCanvas(env.shiftedImage)
	env.image:setWrap("repeat")
	mesh:setTexture(env.image)
	love.graphics.draw(mesh, 0, 0, 0, env.w, env.h)
	love.graphics.setCanvas()
end