local ffi = require("ffi")

return function(env)
	if env.imageData:getFormat() ~= "rgba32f" then
		local newImageData = love.image.newImageData(env.w, env.h, "rgba32f") --todo make bitdepth a setting + fallback
		local newImagePointer = ffi.cast("float_pixel_t*", newImageData:getFFIPointer())
		local imagePointer = ffi.cast("pixel_t*", env.imageData:getFFIPointer())

		--todo this cast only works for rgba8 to 32f
		for i = 0, env.w * env.h - 1 do
			newImagePointer[i].r = imagePointer[i].r / 255
			newImagePointer[i].g = imagePointer[i].g / 255
			newImagePointer[i].b = imagePointer[i].b / 255
			newImagePointer[i].a = imagePointer[i].a / 255
		end

		env.imageData = newImageData
	end
end