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
	contrast = love.graphics.newShader("shaders/contrast.glsl"),
}

local upcastImage = require("modules/upcastImage")
local generateMask = require("modules/generateMask")
local blurMask = require("modules/blurMask")
local poissonBlend = require("modules/poissonBlend")
local createWorkspace = require("modules/createWorkspace")
local brightnessCorrection = require("modules/brightnessCorrection")
local downCast = require("modules/downCast")
local combine = require("modules/combine")
local flip = require("modules/flip")
local generateContrast = require("modules/generateContrast")

local function process(path, output, settings)
	settings = settings or { }
	settings.blurStrength = settings.blurStrength or 0.01
	settings.dynamicBlur = settings.dynamicBlur or true
	settings.scaleToNextN2 = settings.scaleToNextN2 or false
	settings.outputSquare = settings.outputSquare or false
	settings.minOverlap = settings.minOverlap or 0.125
	settings.overlap = settings.overlap or 0.125
	settings.poisson = settings.poisson or 30
	settings.contrastResolution = settings.contrastResolution or 128

	local env = { shaders = shaders, settings = settings }
	env.path = path
	env.imageData = love.image.newImageData(path)
	env.w, env.h = env.imageData:getDimensions()

	--upcast to float to minimize loss
	upcastImage(env)

	for dimension = 1, 2 do
		env.dimension = dimension

		--create shifted source image
		brightnessCorrection(env)

		--create shifted source image
		createWorkspace(env)

		--create contrast map for blurring
		generateContrast(env)

		--generate blend mask
		generateMask(env)

		--blur blend mask
		blurMask(env)

		--poisson blend
		poissonBlend(env)

		--combine blend result with image
		combine(env)

		--flip
		flip(env)
	end

	--downcast to 8bit
	downCast(env)

	--save
	env.finalImageData:encode("png", output)
end

love.filesystem.createDirectory("output")

function love.filedropped(file)
	love.filesystem.write("temp", file:read())
	process("temp", "image.png")
	love.filesystem.remove("temp")
	love.system.openURL(love.filesystem.getSaveDirectory())
end

function love.directorydropped(file)
	love.filesystem.mount(file, "mount")
	for _, s in ipairs(love.filesystem.getDirectoryItems("mount")) do
		process("mount/" .. s, "output/" .. s .. ".png")
	end
	love.system.openURL(love.filesystem.getSaveDirectory() .. "/output")
end