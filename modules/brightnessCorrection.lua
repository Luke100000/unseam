return function(env)
	--Check the brightness balance
	local left, right = 0, 0
	for x = 0, env.w - 1 do
		local f = x / (env.w - 1)
		for y = 0, env.h - 1 do
			local p = env.imagePointer[x + y * env.w]
			local brightness = (p.r * 0.2126 + p.g * 0.7152 + p.b * 0.0722) / 255
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
			local p = env.imagePointer[x + y * env.w]
			p.r = math.min(255, math.max(0, p.r * adaption + 0.5))
			p.g = math.min(255, math.max(0, p.g * adaption + 0.5))
			p.b = math.min(255, math.max(0, p.b * adaption + 0.5))
		end
	end
end