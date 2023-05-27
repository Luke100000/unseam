local ffi = require("ffi")

return function(env)
	env.finalImageData = love.image.newImageData(env.w, env.h)
	local finalImagePointer = ffi.cast("pixel_t*", env.finalImageData:getFFIPointer())
	local imagePointer = ffi.cast("float_pixel_t*", env.imageData:getFFIPointer())

	--Atkinson diffusion
	local function addError(x, y, er, eg, eb)
		if x >= 0 and x < env.w and y >= 0 and y < env.h then
			local e = imagePointer[x + y * env.w]
			e.r = e.r + er / 8
			e.g = e.g + eg / 8
			e.b = e.b + eb / 8
		end
	end

	for x = 0, env.w - 1 do
		for y = 0, env.h - 1 do
			--round
			local p = imagePointer[x + y * env.w]
			local r = math.floor(p.r * 255 + 0.5)
			local g = math.floor(p.g * 255 + 0.5)
			local b = math.floor(p.b * 255 + 0.5)
			local er = p.r - r / 255
			local eg = p.g - g / 255
			local eb = p.b - b / 255

			--diffuse error
			addError(x + 1, y, er, eg, eb)
			addError(x + 2, y, er, eg, eb)
			addError(x - 1, y + 1, er, eg, eb)
			addError(x, y + 1, er, eg, eb)
			addError(x + 1, y + 1, er, eg, eb)
			addError(x, y + 2, er, eg, eb)

			--cast
			local n = finalImagePointer[x + y * env.w]
			n.r = math.min(255, math.max(0, r))
			n.g = math.min(255, math.max(0, g))
			n.b = math.min(255, math.max(0, b))
			n.a = 255
		end
	end
end