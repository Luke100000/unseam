local font = love.graphics.newFont(32)

return function(image, message, shader)
	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.clear(0.2, 0.2, 0.2)

	local screenW, screenH = love.graphics.getDimensions()
	local w, h = image:getDimensions()
	local margin = 80
	local footerHeight = 50
	local scale = math.min((screenW - margin) / w, (screenH - margin - footerHeight) / h)
	local ox = (screenW - w * scale) / 2
	local oy = (screenH - footerHeight - h * scale) / 2

	love.graphics.setShader(shader)
	love.graphics.draw(image, ox, oy, 0, scale)
	love.graphics.setShader()

	local border = 5
	love.graphics.setColor(0.8, 0.8, 0.8)
	love.graphics.rectangle("line", ox, oy, w * scale, h * scale)
	love.graphics.rectangle("line", ox - border, oy - border, w * scale + border * 2, h * scale + border * 2)

	love.graphics.setFont(font)
	love.graphics.printf(message or "Processing", 0, screenH - footerHeight / 2 - font:getBaseline(), screenW, "center")

	love.graphics.pop()
	love.graphics.present()
end