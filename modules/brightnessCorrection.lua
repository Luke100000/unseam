local ffi = require("ffi")

return function(env)
	local imagePointer = ffi.cast("float_pixel_t*", env.imageData:getFFIPointer())

	--Check the brightness balance
	local left, right = 0, 0
	for x = 0, env.w - 1 do
		local f = x / (env.w - 1)
		for y = 0, env.h - 1 do
			local p = imagePointer[x + y * env.w]
			local brightness = p.r * 0.2126 + p.g * 0.7152 + p.b * 0.0722
			left = left + brightness * (1 - f)
			right = right + brightness * f
		end
	end

	--normalize left and right weight
	left = left / (env.w * env.h)
	right = right / (env.w * env.h)
	left, right = left / right, right / left

	--apply weights
	for x = 0, env.w - 1 do
		local f = x / (env.w - 1)
		for y = 0, env.h - 1 do
			local adaption = (right * (1 - f) + left * f - 1) * 1.5 + 1
			local p = imagePointer[x + y * env.w]
			p.r = math.min(1, math.max(0, p.r * adaption))
			p.g = math.min(1, math.max(0, p.g * adaption))
			p.b = math.min(1, math.max(0, p.b * adaption))
		end
	end
end