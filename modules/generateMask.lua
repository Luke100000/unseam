local ffi = require("ffi")
local PriorityQueue = require("libs/queue")

local progress = require("modules/progress")

return function(env)
	--construct error map
	local errorByteData = love.data.newByteData(ffi.sizeof("float") * env.intersect * env.h)
	local error = ffi.cast("float*", errorByteData:getFFIPointer())
	for x = 0, env.intersect - 1 do
		for y = 0, env.h - 1 do
			local a = env.leftImagePointer[x + y * env.intersect]
			local b = env.rightImagePointer[x + y * env.intersect]
			local gradient = 1 - math.sin(x / env.intersect * math.pi)
			local e = (a.r - b.r) ^ 2 + (a.g - b.g) ^ 2 + (a.b - b.b) ^ 2
			local a2 = env.leftImagePointer[x + (env.h - y-1) * env.intersect]
			local b2 = env.rightImagePointer[x + (env.h - y-1) * env.intersect]
			local e2 = (a2.r - b2.r) ^ 2 + (a2.g - b2.g) ^ 2 + (a2.b - b2.b) ^ 2
			error[x + y * env.intersect] = e + e2 + gradient ^ 32 + 0.00001
		end
	end

	--loss map
	local bestByteData = love.data.newByteData(ffi.sizeof("float") * env.intersect * env.h)
	local best = ffi.cast("float*", bestByteData:getFFIPointer())

	--source and sink map
	env.sourceSinkByteData = love.data.newByteData(ffi.sizeof("float") * env.intersect * env.h)
	local sourceSink = ffi.cast("float*", env.sourceSinkByteData:getFFIPointer())

	--find best cut
	local queue = PriorityQueue()
	local highest = math.huge
	local bestPosition = 0

	--clear
	for x = 0, env.intersect - 1 do
		for y = 0, env.h - 1 do
			best[x + y * env.intersect] = math.huge
		end
	end

	local function add(x, y, cost)
		if x >= 0 and x < env.intersect and y >= 0 and y < env.h then
			cost = cost + error[x + y * env.intersect]
			if cost < best[x + y * env.intersect] then
				queue:put({ x, y }, cost)
			end
		end
	end

	for x = 0, env.intersect - 1 do
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

		if cost < best[x + y * env.intersect] then
			best[x + y * env.intersect] = cost
			if cost < highest then
				add(x + 1, y, cost)
				add(x - 1, y, cost)
				add(x, y + 1, cost)
				add(x, y - 1, cost)
			end
		end

		iteration = iteration + 1
		if iteration % 1000000 == 0 then
			env.shaders.r:send("factor", 1 / cost)
			progress(love.graphics.newImage(love.image.newImageData(env.intersect, env.h, "r32f", bestByteData)), "Finding stitching seam...", env.shaders.r)
		end
	end

	--backtrace
	do
		local pos = bestPosition
		local function get(x, y)
			return x >= 0 and x < env.intersect and y >= 0 and y < env.h and best[x + y * env.intersect] or math.huge
		end
		local x, y = unpack(pos)
		while y ~= 0 do
			sourceSink[x + y * env.intersect] = 1
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
		sourceSink[x + y * env.intersect] = 1
	end

	--fill the rest
	local sources = { { 0, 0 } }
	local function fill(x, y)
		if x >= 0 and x < env.intersect and y >= 0 and y < env.h and sourceSink[x + y * env.intersect] == 0.0 then
			table.insert(sources, { x, y })
		end
	end
	while #sources > 0 do
		local x, y = unpack(table.remove(sources))
		sourceSink[x + y * env.intersect] = 1
		fill(x + 1, y)
		fill(x - 1, y)
		fill(x, y + 1)
		fill(x, y - 1)
	end
end