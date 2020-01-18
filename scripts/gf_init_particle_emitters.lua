local function IntColour( r, g, b, a )
	return { r / 255.0, g / 255.0, b / 255.0, a / 255.0 }
end

local textures = 
{
	snow = "fx/wintersnow.tex",
	fire = "fx/torchfire.tex",
	smoke = "fx/smoke.tex",
	drop = "fx/edrop.tex",
	skull = "fx/eskull.tex",
	sparkle = "fx/esparkle.tex",
	square = "fx/esquare.tex",
}

local envelopeScaleVariety = 
{
    gfsmallnoscaleenvelope = 
    {
        { 0,	{ 0.25, 0.25 } },
        { 1,	{ 0.25, 0.25 } },
    },
    gfmediumnoscaleenvelope = 
    {
        { 0,	{ 0.5, 0.5 } },
        { 1,	{ 0.5, 0.5 } },
    },
    gfhugenoscaleenvelope = 
    {
        { 0,	{ 1, 1 } },
        { 1,	{ 1, 1 } },
    },
    gfgaintnoscaleenvelope = 
    {
        { 0,	{ 1.25, 1.25 } },
        { 1,	{ 1.25, 1.25 } },
    },
    gfdefaultscaleenvelope = 
    {
        { 0,	{ 0, 0 } },
        { 1,	{ 1, 1 } },
    },
    --small
    gfsmalldownscaleenvelope = 
    {
        { 0,	{ 0.50, 0.50 } },
        { 1,	{ 0.10, 0.10 } },
    },
    gfsmallupscaleenvelope = 
    {
        { 0,	{ 0.10, 0.10 } },
        { 1,	{ 0.50, 0.50 } },
    },
    --medium
    gfmediumdownscaleenvelope = 
    {
        { 0,	{ 0.75, 0.75 } },
        { 1,	{ 0.10, 0.10 } },
    },
    gfmediumupscaleenvelope = 
    {
        { 0,	{ 0.10, 0.10 } },
        { 1,	{ 0.75, 0.75 } },
    },
    --huge
    gfhugedownscaleenvelope = 
    {
        { 0,	{ 1.00, 1.00 } },
        { 1,	{ 0.10, 0.10 } },
    },
    gfhugeupscaleenvelope = 
    {
        { 0,	{ 0.10, 0.10 } },
        { 1,	{ 1.00, 1.00 } },
    },
}

local envelopeColourVariety = 
{
    gfdefaultcolourenvelope = 
    {
        { 0, {1, 1, 1, 0.5} },
		{ 1, {1, 1, 1, 0.0} },
    },
    gfbluecolourenvelope = 
    {
        { 0,	IntColour( 25,  25,  210, 128 ) },
		{ 1,	IntColour( 25,  25,  210, 0   ) },
    },
    gfredcolourenvelope = 
    {
        { 0,	IntColour( 210, 25,  25,  128 ) },
		{ 1,	IntColour( 210, 25,  25,  0   ) },
    },
    gfgreencolourenvelope = 
    {
        { 0,	IntColour( 25, 210,  25,  128 ) },
		{ 1,	IntColour( 25, 210,  25,  0   ) },
    },
    gfyellowcolourenvelope = 
    {
        { 0,	IntColour( 25, 210, 210, 128 ) },
		{ 1,	IntColour( 25, 210, 210, 0   ) },
    },
}

function GF.AddParticleEmitterScale(name, data)
    --[[--------------------------------
    data format:
    { { time, { x-scale, y-scale } } }
    example:
    {
        { 0,	{ 0.1, 0.1 } },
        { 0.5,	{ 0.4, 0.4 } },
        { 1,	{ 0.8, 0.8 } },
    }
    ----------------------------------]]
    envelopeScaleVariety[name] = data
end

function GF.AddParticleEmitterColour(name, data)
    --[[--------------------------------
    data format:
    { { time, { r, g, b, a } } }
    example:
    {
        { 0,	{ 0.1, 0.4, 0.1, 0.5 } },
        { 0.5,	{ 0.2, 0.2, 0.4, 0.3 } },
        { 1,	{ 0.4, 0.0, 0.8, 0.1 } },
    }
    ----------------------------------]]
    envelopeColourVariety[name] = data
end

local needToInit = true
function GF.InitParticleEmittersEnvelope()
	if EnvelopeManager ~= nil and needToInit then
        needToInit = false
        for k, v in pairs(envelopeScaleVariety) do
			EnvelopeManager:AddVector2Envelope(k, v)
		end
		for k, v in pairs(envelopeColourVariety) do
			EnvelopeManager:AddColourEnvelope(k, v)
		end
	end
end

--custom emitters
--position
function CreateSpinningEmitter(radius, speed)
    local r = radius
    local s = speed
    local cos = math.cos
    local sin = math.sin

    return function()
        local v = GetTime() * s
        return cos(v) * radius, 0, sin(v) * radius
    end
end

function CreateDoubleSpinningEmitter(radius, speed)
    local t = true
    local r = radius
    local s = speed
    local cos = math.cos
    local sin = math.sin

    return function()
        local v = GetTime() * s
        t = not t
        if t then
            return cos(v) * radius, 0, sin(v) * radius
        else
            return -cos(v) * radius, 0, -sin(v) * radius
        end
    end
end