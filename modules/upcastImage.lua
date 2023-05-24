local ffi = require("ffi")

return function(env)
	if env.imageData:getFormat() ~= "rgba32f" then
		local newImageData = love.image.newImageData(env.w, env.h, "rgba32f") --todo make bitdepth a setting + fallback
		local newImagePointer = ffi.cast("float_pixel_t*", newImageData:getFFIPointer())
		--todo this cast only works for rgba8 to 32f
		for i = 0, env.w * env.h - 1 do
			newImagePointer[i].r = env.imagePointer[i].r / 255
			newImagePointer[i].g = env.imagePointer[i].g / 255
			newImagePointer[i].b = env.imagePointer[i].b / 255
			newImagePointer[i].a = env.imagePointer[i].a / 255
		end
		env.imageData = newImageData
		env.imagePointer = newImagePointer
	end
end