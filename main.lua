local ffi = require("ffi")

ffi.cdef([[
	typedef struct { uint8_t r, g, b, a; } pixel_t;
]])

ffi.cdef([[
	typedef struct { float r, g, b, a; } float_pixel_t;
]])

local shaders = {
	r = love.graphics.newShader("shaders/r.glsl"),
	blur = love.graphics.newShader("shaders/blur.glsl"),
	step = love.graphics.newShader("shaders/step.glsl"),
	preMerge = love.graphics.newShader("shaders/preMerge.glsl"),
}

local upcastImage = require("modules/upcastImage")
local generateMask = require("modules/generateMask")
local blurMask = require("modules/blurMask")
local poissonBlend = require("modules/poissonBlend")
local shiftImage = require("modules/shiftImage")
local brightnessCorrection = require("modules/brightnessCorrection")
local downCast = require("modules/downCast")

local function process(settings)
	local env = { shaders = shaders, settings = settings }
	env.imageData = love.image.newImageData(settings.path)
	env.imagePointer = ffi.cast("pixel_t*", env.imageData:getFFIPointer())
	env.w, env.h = env.imageData:getDimensions()
	env.hw = math.floor(env.w / 2)

	--upcast to float to minimize loss
	upcastImage(env)

	--create shifted source image
	brightnessCorrection(env)

	env.image = love.graphics.newImage(env.imageData)

	--create shifted source image
	shiftImage(env)

	--generate blend mask
	generateMask(env)

	--blur blend mask
	blurMask(env)

	--poisson blend
	poissonBlend(env)

	--downcast to 8bit
	downCast(env)

	--save
	env.finalImageData:encode("png", "output.png")
end

process({
	path = "examples/1.jpg",
	blurStrength = 0.01,
})
os.exit()