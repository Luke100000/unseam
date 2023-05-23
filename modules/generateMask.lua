local ffi = require("ffi")
local PriorityQueue = require("libs/queue")

local progress = require("modules/progress")

return function(env)
	--construct error map
	local errorByteData = love.data.newByteData(ffi.sizeof("float") * env.w * env.h)
	local error = ffi.cast('float*', errorByteData:getFFIPointer())
	local focusFactor = 0.01
	for x = 0, env.w - 1 do
		for y = 0, env.h - 1 do
			local a = env.imagePointer[x + y * env.w]
			local b = env.imagePointer[((x + env.hw) % env.w) + y * env.w]
			local gradient = 1 - math.abs(math.sin(x / env.w * math.pi * 2))
			local focus = math.abs(x / env.w * 2 - 1)
			local e = ((a.r - b.r) / 255) ^ 2 + ((a.g - b.g) / 255) ^ 2 + ((a.b - b.b) / 255) ^ 2
			error[x + y * env.w] = e + gradient ^ 32 + focus * focusFactor + 0.00001
		end
	end

	--loss map
	local bestByteData = love.data.newByteData(ffi.sizeof("float") * env.w * env.h)
	local best = ffi.cast('float*', bestByteData:getFFIPointer())

	--source and sink map
	env.sourceSinkByteData = love.data.newByteData(ffi.sizeof("float") * env.w * env.h)
	local sourceSink = ffi.cast('float*', env.sourceSinkByteData:getFFIPointer())
	for x = 0, env.w - 1 do
		for y = 0, env.h - 1 do
			sourceSink[x + y * env.w] = 0
		end
	end

	--find best cut
	for side = 0, 1 do
		local queue = PriorityQueue()
		local highest = math.huge
		local bestPosition = 0

		for x = 0, env.w - 1 - env.hw * side do
			for y = 0, env.h - 1 do
				best[x + y * env.w] = math.huge
			end
		end

		local function add(x, y, cost)
			if x >= env.hw * side and x < env.hw * side + env.hw and y >= 0 and y < env.h then
				cost = cost + error[x + y * env.w]
				if cost < best[x + y * env.w] then
					queue:put({ x, y }, cost)
				end
			end
		end

		for x = env.hw * side, env.hw * side + env.hw do
			queue:put({ x, 0 }, error[x])
		end

		local iteration = 0
		while not queue:empty() do
			local xy, cost = queue:pop()
			local x, y = xy[1], xy[2]

			if cost < highest and y == env.h - 1 then
				highest = cost
				bestPosition = xy
			end

			if cost < best[x + y * env.w] then
				best[x + y * env.w] = cost
				if cost < highest then
					add(x + 1, y, cost)
					add(x - 1, y, cost)
					add(x, y + 1, cost)
					add(x, y - 1, cost)
				end
			end

			iteration = iteration + 1
			if iteration % 100000 == 0 then
				env.shaders.r:send("factor", 1 / cost)
				progress(love.graphics.newImage(love.image.newImageData(env.w, env.h, "r32f", bestByteData)), "Finding stitching seam...", env.shaders.r)
			end
		end

		--backtrace
		local pos = bestPosition
		local function get(x, y)
			return x >= 0 and x < env.w and y >= 0 and y < env.h and best[x + y * env.w] or math.huge
		end
		local x, y = unpack(pos)
		while y ~= 0 do
			sourceSink[x + y * env.w] = 1
			local x1 = get(x + 1, y)
			local x2 = get(x - 1, y)
			local x3 = get(x, y + 1)
			local x4 = get(x, y - 1)
			local m = math.min(x1, x2, x3, x4)
			if x1 == m then
				x = x + 1
			elseif x2 == m then
				x = x - 1
			elseif x3 == m then
				y = y + 1
			else
				y = y - 1
			end
		end
		sourceSink[x + y * env.w] = 1
	end

	--fill the rest
	local sources = { { env.hw, 0 } }
	local function add(x, y)
		if x >= 0 and x < env.w and y >= 0 and y < env.h and sourceSink[x + y * env.w] == 0.0 then
			table.insert(sources, { x, y })
		end
	end
	while #sources > 0 do
		local x, y = unpack(table.remove(sources))
		sourceSink[x + y * env.w] = 1
		add(x + 1, y)
		add(x - 1, y)
		add(x, y + 1)
		add(x, y - 1)
	end
end