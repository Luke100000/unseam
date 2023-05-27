local ffi = require("ffi")

return function(env)
	local newImageData = love.image.newImageData(env.h, env.w, "rgba32f")
	local newImagePointer = ffi.cast("float_pixel_t*", newImageData:getFFIPointer())

	local imagePointer = ffi.cast("float_pixel_t*", env.imageData:getFFIPointer())

	for x = 0, env.w - 1 do
		for y = 0, env.h - 1 do
			local f = imagePointer[x + y * env.w]
			local t = newImagePointer[y + x * env.h]
			t.r = f.r
			t.g = f.g
			t.b = f.b
			t.a = f.a
		end
	end

	env.imageData = newImageData
	env.w, env.h = env.h, env.w
end