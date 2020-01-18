--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.
local GF = {}
local DEVMODE = false
local DisableCritical = false

rawset(_G, "GF", GF)
rawset(GF, "DevMode", DEVMODE)
rawset(GF, "DisableCritical", DisableCritical)

function GF.CheckVersion() return true end
function GF.GetVersion() return 2.2 end

--############################################
----------------------------------------------
--INIT THE SIM FUNCTIONS----------------------
----------------------------------------------
--############################################

function GFGetIsMasterSim()
    return TheWorld.ismastersim
end

function GFGetIsDedicatedNet()
    return TheNet:IsDedicated()
end

function GFGetPVPEnabled()
    return TheNet:GetPVPEnabled()
end

function GFGetWorld()
    return TheWorld
end

function GFGetPlayer()
    return ThePlayer
end

--############################################
----------------------------------------------
--INIT UNIQUE GREEN CLASSES AND STORAGES------
----------------------------------------------
--############################################

require "gf_init_particle_emitters"

--init global storages for items
local DialogueNodes = {}
local DialogueNodesIDs = {}
local DialogueNodesPostInits = {}
rawset(GF, "DialogueNodes", DialogueNodes)
rawset(GF, "DialogueNodesIDs", DialogueNodesIDs)

local StatusEffects = {}
local StatusEffectsIDs = {}
local StatusEffectsPostInits = {}
rawset(GF, "StatusEffects", StatusEffects)
rawset(GF, "StatusEffectsIDs", StatusEffectsIDs)

local Spells = {}
local SpellsIDs = {}
local SpellsPostInits = {}
rawset(GF, "Spells", Spells)
rawset(GF, "SpellsIDs", SpellsIDs)

local Quests = {}
local QuestsIDs = {}
local QuestsPostInits = {}
rawset(GF, "Quests", Quests)
rawset(GF, "QuestsIDs", QuestsIDs)

local Currencies = {}
local CurrenciesLinks = {}
local ShopItems = {}
local ShopItemsLinks = {}
rawset(GF, "Currencies", Currencies)
rawset(GF, "ShopItems", ShopItems)
rawset(GF, "CurrenciesLinks", CurrenciesLinks)
rawset(GF, "ShopItemsLinks", ShopItemsLinks)

function GF.PostInitItemOfType(type, name, fn)
    local itemTypes = 
    {
        dialogue_node = {DialogueNodes, DialogueNodesPostInits},
        status_effect = {StatusEffects, StatusEffectsPostInits},
        spell = {Spells, SpellsPostInits},
        quest = {Quests, QuestsPostInits},
    }

    if itemTypes[type] == nil then return end

    local all = itemTypes[type][1]
    local fns = itemTypes[type][2]

    if all[name] ~= nil then
        fn(item)
    end

    table.insert(fns, fn)
end

--############################################
--DIALOGUE NODES------------------------------
--############################################

--*modmain* - this one loads a node from a file and adds it to the game
function GF.InitDialogueNode(route)
    --if GF.DisableCritical then print("InitDialogueNode function is inaccessible. Critical content is disabled") return false end
    local res = require("dialogue_nodes/" .. route)
    assert(res, "could not load an node " .. route)
end

--*modmain* - this may be used to make some changes in an existing node
function GF.DialogueNodePostInit(name, fn)
    GF.PostInitItemOfType("dialogue_node", name, fn)
end

--returns an instance of the dialogue_node class
--should be used like the CreateEntity function but for nodes
function GF.CreateDialogueNode()
    local item = require "gf_class_dialogue_node"
    return item()
end

--should be used as the Prefab function 
--to return a post constructor for the dialogue_node class
function GF.DialogueNode(name, fn)
    local node = fn()
    node.name = name

    local id = #DialogueNodesIDs + 1
    if DialogueNodes[name] ~= nil then
        id = DialogueNodes[name].id
        print(("dialogue node with %s already exists! Overwriting..."):format(name))
    end

    node.id = id

    if DialogueNodesPostInits[name] ~= nil then
        for _, fn in pairs(DialogueNodesPostInits[name]) do
            fn(node)
        end
    end

    DialogueNodes[name] = node
    DialogueNodesIDs[id] = name

    print(("dialogue node %s was initialized with ID %i"):format(name, id))
end

function GF.GetDialogueNodes()
    return DialogueNodes
end

function GF.GetDialogueNodesIDs()
    return DialogueNodesIDs
end

--############################################
--STATUS EFFECTS------------------------------
--############################################

--*modmain* - this one loads a node from a file and adds it to the game
function GF.InitStatusEffect(route)
    local res = require("effects/" .. route)
    assert(res, "could not load an effect " .. route)
end

--*modmain* - this may be used to make some changes in an existing node
function GF.StatusEffectPostInit(name, fn)
    GF.PostInitItemOfType("status_effect", name, fn)
end

--returns an instance of the dialogue_node class
--should be used like the CreateEntity function but for nodes
function GF.CreateStatusEffect()
    local effect = require "gf_class_effect"
    return effect()
end

--should be used as the Prefab function 
--to return a post constructor for the dialogue_node class
function GF.StatusEffect(name, fn)
    local effect = fn()
    effect.name = name

    local id = #StatusEffectsIDs + 1
    if StatusEffects[name] ~= nil then
        id = StatusEffects[name].id
        print(("effect node with %s already exists! Overwriting..."):format(name))
    end

    effect.id = id

    if StatusEffectsPostInits[name] ~= nil then
        for _, fn in pairs(StatusEffectsPostInits[name]) do
            fn(effect)
        end
    end

    StatusEffects[name] = effect
    StatusEffectsIDs[id] = name

    print(("effect %s was initialized with ID %i"):format(name, id))

    return effect
end

--returns all effects
function GF.GetStatusEffects()
    return GF.StatusEffects
end

--returns all IDs for effects
function GF.GetStatusEffectsIDs()
    return GF.StatusEffectsIDs
end

--############################################
--SPELLS--------------------------------------
--############################################

--*modmain* - this one loads a node from a file and adds it to the game
function GF.InitSpell(route)
    local res = require("spells/" .. route)
    assert(res, "could not load a spell " .. route)
end

--*modmain* - this may be used to make some changes in an existing node
function GF.SpellPostInit(name, fn)
    GF.PostInitItemOfType("spell", name, fn)
end

--returns an instance of the dialogue_node class
--should be used like the CreateEntity function but for nodes
function GF.CreateSpell(archetype)
    --local spell = archetype ~= nil and require "spells/archetypes/ .. archetype" or require "gf_class_spell"
    --assert(spell, "could not load a spell " .. (archetype or ""))
    local spell
    if archetype ~= nil then
        spell = require("spells/archetypes/" .. archetype)
        assert(spell, "could not load a spell " .. (archetype or ""))
    else
        spell = require "gf_class_spell"
    end

    return spell()
end

function GF.CopySpell(name)
    local function Copy(t, s)
        for k, v in pairs(s) do
            if type(v) == "table" then
                t[k] = {}
                Copy(t[k], v)
            else
                t[k] = v
            end
        end
    end 
    --local spell = archetype ~= nil and require "spells/archetypes/ .. archetype" or require "gf_class_spell"
    --assert(spell, "could not load a spell " .. (archetype or ""))
    local spell
    if name ~= nil or Spells[name] ~= nil then
        spell = require("gf_class_spell")()
        Copy(spell, Spells[name])
    else
        error(("could not copy a spell %s"):format(tostring(name)), 3)
    end

    return spell
end

--should be used as the Prefab function 
--to return a post constructor for the dialogue_node class
function GF.Spell(name, fn)
    local spell = fn()
    spell.name = name

    local id = #SpellsIDs + 1
    if Spells[name] ~= nil then
        id = Spells[name].id
        print(("spell with %s already exists! Overwriting..."):format(name))
    end

    spell.id = id

    if SpellsPostInits[name] ~= nil then
        for _, fn in pairs(SpellsPostInits[name]) do
            fn(spell)
        end
    end

    Spells[name] = spell
    SpellsIDs[id] = name

    print(("spell %s was initialized with ID %i"):format(name, id))
end

--returns all effects
function GF.GetSpells()
    return GF.Spells
end

--returns all IDs for effects
function GF.GetSpellsIDs()
    return GF.SpellsIDs
end

--############################################
--QUESTS--------------------------------------
--############################################

--*modmain* - this one loads a node from a file and adds it to the game
function GF.InitQuest(route)
    --if GF.DisableCritical then print("InitQuest function is inaccessible. Critical content is disabled") return false end
    local res = require("quests/" .. route)
    assert(res, "could not load a quest " .. route)
end

--*modmain* - this may be used to make some changes in an existing node
function GF.QuestPostInit(name, fn)
    GF.PostInitItemOfType("quest", name, fn)
end

--returns an instance of the dialogue_node class
--should be used like the CreateEntity function but for nodes
function GF.CreateQuest(archetype)
    local quest

    if archetype ~= nil then
        quest = require("quests/archetypes/" .. archetype)
        assert(quest, "could not load a spell " .. (archetype or ""))
    else
        quest = require "gf_class_quest"
    end

    return quest()
end

--should be used as the Prefab function 
--to return a post constructor for the dialogue_node class
function GF.Quest(name, fn)
    local quest = fn()
    quest.name = name

    local id = #QuestsIDs + 1
    if Quests[name] ~= nil then
        id = Quests[name].id
        print(("quest with %s already exists! Overwriting..."):format(name))
    end

    quest.id = id

    if QuestsPostInits[name] ~= nil then
        for _, fn in pairs(QuestsPostInits[name]) do
            fn(quest)
        end
    end

    Quests[name] = quest
    QuestsIDs[id] = name

    print(("quest %s was initialized with ID %i"):format(name, id))
end

--returns all effects
function GF.GetQuests()
    return GF.Quests
end

--returns all IDs for effects
function GF.GetQuestsIDs()
    return GF.QuestsIDs
end

--############################################
--OLD API-------------------------------------
--############################################

local function IsDepreciated()
    local info = debug.getinfo(2, "n")
    local call = info ~= nil and info.name or "<no source>"

    print("GREEN: function " .. call .. " is depreciated!")
end

function GFAddCustomSpell()
    IsDepreciated()
end

function GFAddCustomEffect()
    IsDepreciated()
end

function GFAddCustomQuest()
    IsDepreciated()
end

function GFAddBaseSpells()
    IsDepreciated()
end

function GFAddBaseEffects()
    IsDepreciated()
end

--[[BLODD COLOURS]]
local BLOOD_COLOURS = 
{
    OIL = {0, 0.1, 0.2, 1},
    GHOST_ESSENCE = {0.1, 0.1, 0.1, 1},
    PLANT_JUICE = {115 / 255, 160 / 255, 50 / 255, 1},
}

local bloodColours = 
{
    -- character
    wx78     = BLOOD_COLOURS.OIL,
    wormwood = BLOOD_COLOURS.PLANT_JUICE,
    -- chess
    knight = BLOOD_COLOURS.OIL,
    bishop = BLOOD_COLOURS.OIL,
    rook   = BLOOD_COLOURS.OIL,
    bishop_nightmare = BLOOD_COLOURS.OIL,
    knight_nightmare = BLOOD_COLOURS.OIL,
    rook_nightmare   = BLOOD_COLOURS.OIL,
    -- ghost and shadows
    ghost          = BLOOD_COLOURS.GHOST_ESSENCE,
    terrorbeak     = BLOOD_COLOURS.GHOST_ESSENCE,
    crawlinghorror = BLOOD_COLOURS.GHOST_ESSENCE,
}

rawset(GF, "BloodColours", bloodColours)

function GF.SetBloodColour(prefab, colour)
    if type(colour) == "string" then
        if BLOOD_COLOURS[colour] ~= nil then
            colour = BLOOD_COLOURS[colour]
        elseif PLAYERCOLOURS[colour] ~= nil then
            colour = PLAYERCOLOURS[colour]
        end
    end

    if type(colour) == "table" then
        GF.BloodColours[prefab] = colour
    end
end

function GF.GetBloodColour(prefab)
    return bloodColours[prefab] or {0.5, 0.1, 0.1, 1}
end

--############################################
----------------------------------------------
--INIT FOR ENTITIES---------------------------
----------------------------------------------
--############################################

local PostGreenInit = {player = {}}
local EntitiesBaseEffects = {}
local EntitiesBaseSpells = {}
local InterlocutorOffsets = 
{
    pigman = 3;
}

rawset(GF, "PostGreenInit", PostGreenInit)
rawset(GF, "EntitiesBaseEffects", EntitiesBaseEffects)
rawset(GF, "EntitiesBaseSpells", EntitiesBaseSpells)
rawset(GF, "InterlocutorOffsets", InterlocutorOffsets)

function GF.AddPostGreenInit(prefab, fn)
    if PostGreenInit[prefab] == nil then
        PostGreenInit[prefab] = {}
    end

    table.insert(PostGreenInit[prefab], fn)
end

function GF.AddBaseStatusEffects(prefab, type, chance, ...)
    if EntitiesBaseEffects[prefab] == nil then
        EntitiesBaseEffects[prefab] = {}
    end
    local aff = EntitiesBaseEffects[prefab]
    if aff[type] == nil then
        aff[type] = {}
        aff[type].chance = 1
    end 
    if aff[type].list == nil then
        aff[type].list = {}
    end 
    if chance ~= nil then aff[type].chance = chance end
    for i = 1, arg.n do
        table.insert(aff[type].list, arg[i])
    end
end

function GF.AddBaseSpells(prefab, ...)
    if EntitiesBaseSpells[prefab] == nil then
        EntitiesBaseSpells[prefab] = {}
    end
    for i = 1, arg.n do
        table.insert(EntitiesBaseSpells[prefab], arg[i])
    end
end

GF.ThrowableParams = {}

function GF.MakeEquipThrowable(prefab, anim, onland, onhit, weight)
    GF.AddBaseSpells(prefab, "throw_weapon")
    GF.ThrowableParams[prefab] = anim
    --[[{
        anim = anim or "fly", --fly, hspin, vspin
        onland = onland,
        onhit = onhit,
        weight = weight,
    }]]
end

--############################################
--trading-------------------------------------
--############################################
function GF.AddCurrency(name, image, atlas, warning)
    --if GF.DisableCritical then print("AddCurrency function is inaccessible. Critical content is disabled") return false end
    if CurrenciesLinks[name] == nil then
        local currency = require("gf_class_currency")()
        local id = #Currencies + 1

        currency.name = name
        currency.atlas = atlas or "images/inventoryimages.xml"
        currency.image = image or "goldnugget.tex"
        currency.warning = warning
        currency.id = id

        Currencies[id] = currency
        CurrenciesLinks[name] = Currencies[id]
    end
end

function GF.AddShopItem(name, dispname, onbuy, currency, value, image, atlas)
    --if GF.DisableCritical then print("AddShopItem function is inaccessible. Critical content is disabled") return false end
    currency = currency or "gold"
    if ShopItemsLinks[name] == nil and CurrenciesLinks[currency] ~= nil then
        local item = require("gf_class_shop_item")()
        local id = #ShopItems + 1

        item.name = name
        item.dispname = dispname or name
        item.onbuy = onbuy
        item.currency = currency or "gold"
        item.price = value or 1
        item.atlas = atlas
        item.image = image
        item.id = id

        ShopItems[id] = item
        ShopItemsLinks[name] = ShopItems[id]

        print(string.format("Shop Item with id %s created - currency - %s, price - %i", name, currency or "gold", value or 1))
    end
end
--############################################
----------------------------------------------
--THE SIM HELPERS-----------------------------
----------------------------------------------
--############################################
function GF:ForceDisableCriticalContent()
    self.DisableCritical = true
end

function GF.PumpkinTest(entity)
    entity = entity or AllPlayers[1]
    local x, y, z = entity.Transform:GetWorldPosition()
    for i = 1, 12 do
        local pt = Vector3(x + math.cos(i * 30) * 10, y, z - math.sin(i * 30) * 10)
        SpawnPrefab("pumpkin_lantern").Transform:SetPosition(pt:Get())
    end
end

function GF.TestGlobalFunctions()
    print("GFGetIsMasterSim", GFGetIsMasterSim())
    print("GFGetIsDedicatedNet", GFGetIsDedicatedNet())
    print("GFGetPVPEnabled", GFGetPVPEnabled())
    print("GFGetWorld", GFGetWorld())
    print("GFGetPlayer", GFGetPlayer())
end

function GFDebugPrint(...)
    if GF.DevMode then
        local info = debug.getinfo(2, "Sl")
        local call = info ~= nil and string.format("<[%s]:%d>", info.source, info.currentline) or "<no source>"
        print(call, ...)
    end
end

function GFGetValidSpawnPosition(x, y, z, minradius, maxradius, maxtries)
    local angle = math.random(360) * DEGREES
    maxtries = maxtries or 10
    minradius = minradius or 1
    maxradius = maxradius or (minradius or 10)
    local radius = minradius == maxradius and minradius or math.random(minradius, maxradius)
    local pt
    local try = 1
    repeat 
        pt = Vector3(x + math.cos(angle) * radius, y, z - math.sin(angle) * radius)
        if TheWorld.Map:IsPassableAtPoint(pt:Get()) then
            break
        end
        pt = nil
        try = try + 1
    until try < maxtries

    return pt
end

function GFIsEntityOnLine(ent, pt1, pt2) -- not net, geometry
	local xe, _, ye = ent.Transform:GetWorldPosition() 
    local radius = ent:GetPhysicsRadius(0) or 0.5

    local p1, p2 = {}, {}
    p1.x = pt1.x - xe
    p1.y = pt1.y - ye
    p2.x = pt2.x - xe
    p2.y = pt2.y - ye
    local dx = (p2.x - p1.x)
    local dy = (p2.y - p1.y)
    local a = dx * dx + dy * dy;
    local b = 2 * ( p1.x * dx + p1.y * dy);
    local c = p1.x * p1.x + p1.y * p1.y - radius * radius;

    if -b < 0 then return c < 0 end
    if -b < 2 * a then return 4 * a * c - b * b < 0 end
    return ((a + b + c < 0))
end

function GFIsEntityInside(polygon, ent)
	local pt = {}
	pt.x, pt.o, pt.y = ent.Transform:GetWorldPosition() -- "_" does't work, let it be pt.o
	local radius = ent:GetPhysicsRadius(0) or 0.5
	local intersections = 0
	local prev = #polygon
	local prevUnder = polygon[prev].y < pt.y
	for i = 1, #polygon do
		local currUnder = polygon[i].y < pt.y
		local p1, p2 = {}, {}
		p1.x = polygon[prev].x - pt.x
		p1.y = polygon[prev].y - pt.y
        p2.x = polygon[i].x - pt.x
		p2.y = polygon[i].y - pt.y
		local dx = (p2.x - p1.x)
		local dy = (p2.y - p1.y)
		local t = (p1.x * dy - p1.y * dx)
		
		local a = dx * dx + dy * dy;
        local b = 2 * ( p1.x * dx + p1.y * dy);
        local c = p1.x * p1.x + p1.y * p1.y - radius * radius;

        if -b < 0 and c < 0 then return true end
        if -b < 2 * a and 4 * a * c - b * b < 0  then return true end
        if (a + b + c < 0) then return true end
		
		if currUnder and not prevUnder then
            if (t > 0) then
                intersections = intersections + 1
			end
		end
        
        if not currUnder and prevUnder then
            if (t < 0) then
                intersections = intersections + 1
			end
		end
		
		prev = i
        prevUnder = currUnder
	end
	return not IsNumberEven(intersections)
end

function GFSoftColourChange(inst, fc, sc, time, step)
    if sc == nil then sc = {1, 1, 1, 1} end
    if time == nil then time = 1 end
    if step == nil or step > 1 then step = 0.1 end
    local totalSteps = math.ceil (time / step)
    inst.AnimState:SetMultColour(sc[1], sc[2], sc[3], sc[4])
    local dRed      = (fc[1] - sc[1]) / totalSteps
    local dGreen    = (fc[2] - sc[2]) / totalSteps
    local dBlue     = (fc[3] - sc[3]) / totalSteps
    local dAlpha    = (fc[4] - sc[4]) / totalSteps
    local deltaColor = {dRed, dGreen, dBlue, dAlpha}
    local currStep = 0
    --local steps = 0
    if inst._softColorTask ~= nil then inst._softColorTask:Cancel() end

    --print(string.format([[starting soft color task: 
        --starting color's mults - red: %.2f, green: %.2f, blue: %.2f, alpha: %.2f 
        --finishcolors - red: %.2f, green: %.2f, blue: %.2f, alpha: %.2f
        --time for procssing: %.2f, step: %.2f
        --delta colors - red: %.2f, green: %.2f, blue: %.2f, alpha: %.2f]],
        --sc[1], sc[2], sc[3], sc[4], fc[1], fc[2], fc[3], fc[4], time, step, dRed, dGreen, dBlue, dAlpha ))

    inst._softColorTask = inst:DoPeriodicTask(step, function(inst)
        if currStep <= totalSteps then
            --print(time)
            inst.AnimState:SetMultColour(sc[1] + deltaColor[1] * currStep, 
                sc[2] + deltaColor[2] * currStep, 
                sc[3] + deltaColor[3] * currStep, 
                sc[4] + deltaColor[4] * currStep)
            currStep = currStep + 1
        else
            --print(string.format("soft color task complete: \nresult color's mults - red: %.2f, green: %.2f, blue: %.2f, alpha: %.2f", 
            --    sc[1] + deltaColor[1] * currStep, 
            --    sc[2] + deltaColor[2] * currStep, 
            --    sc[3] + deltaColor[3] * currStep, 
            --    sc[4] + deltaColor[4] * currStep))
            inst._softColorTask:Cancel() 
            inst._atask = nil
        end
    end, nil, deltaColor, totalSteps, currStep)
end

--############################################
----------------------------------------------
--STRING HELPERS------------------------------
----------------------------------------------
--############################################

--[[ function GetQuestKey(qName, hash)
    if qName ~= nil and Quests[qName] ~= nil then
        return Quests[qName].unique
            and qName
            or (hash ~= nil and qName .. '#' .. hash or nil)
    end

    return nil
end ]]

function GetQuestKey(qName, hash)
    if qName ~= nil and Quests[qName] ~= nil then
        return Quests[qName].unique
            and "_wld"
            or (hash ~= nil) and hash or "_wld"
    end

    return nil
end

function GetEffectString(eName, param)
    --local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
    --local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT
    param = param ~= nil and string.upper(param) or "TITLE"
    eName = string.upper(eName)
    local STR = STRINGS.GF.EFFECTS[eName]
    if STR ~= nil and STR[param] ~= nil then
        return STR[param]
    else
        param = param == "TITLE" and STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE or STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT
        return param
    end
end

function GetSpellString(eName, param, ignoreEmpty)
    --local INVALID_TITLE = STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE
    --local INVALID_TEXT = STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT
    param = param ~= nil and string.upper(param) or "TITLE"
    eName = string.upper(eName)
    local STR = STRINGS.GF.SPELLS[eName]
    if STR ~= nil and STR[param] ~= nil then
        return STR[param]
    elseif ignoreEmpty then
        return ""
    else
        param = param == "TITLE" and STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE or STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT
        return param
    end
end

function GetConversationString(inst, cName, param)
    param = param ~= nil and string.upper(param) or "TITLE"
    cName = string.upper(cName)
    local STR = STRINGS.GF.CONVERSATIONS[cName]
    if STR ~= nil and STR[param] ~= nil then
        local n = inst.name ~= nil and string.gsub(inst.name, "^%l", string.upper) or "Stranger"
        return string.gsub(STR[param], "&name", n)
    else
        param = param == "TITLE" and "" or STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT
        return param
    end
end

function GetQuestString(inst, qName, param)
    param = param ~= nil and string.upper(param) or "TITLE"
    qName = string.upper(qName)
    --local n = inst.prefab or "stranger"
    local STR = STRINGS.GF.QUESTS[qName]
    if STR ~= nil and STR[param] ~= nil then
        local n = inst.name ~= nil and string.gsub(inst.name, "^%l", string.upper) or "Stranger"
        return string.gsub(STR[param], "&name", n)
    elseif param == "REMINDER" then
        return STRINGS.GF.QUESTS.DEFAULT_REMINDER
    else
        param = param == "TITLE" and STRINGS.GF.HUD.INVALID_LINES.INVALID_TITLE or STRINGS.GF.HUD.INVALID_LINES.INVALID_TEXT
        return param
    end
end

return GF