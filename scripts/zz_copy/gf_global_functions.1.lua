--Green Framework. Please, don't copy any files or functions from this mod, because it can break other mods based on the GF.
local GF = {}

rawset(_G, "GFVersion", 1.3)
rawset(_G, "GF", GF)

function GF.CheckVersion() return true end
function GF.GetVersion() return 1.3 end

--init global storages for items
local DialogueNodes = {}
local DialogueNodesIDs = {}
rawset(GF, "DialogueNodes", DialogueNodes)
rawset(GF, "DialogueNodesIDs", DialogueNodesIDs)

local StatusEffects = {}
local StatusEffectsIDs = {}
rawset(GF, "StatusEffects", StatusEffects)
rawset(GF, "StatusEffectsIDs", StatusEffectsIDs)

local Spells = {}
local SpellsIDs = {}
rawset(GF, "Spells", Spells)
rawset(GF, "SpellsIDs", SpellsIDs)

local Quests = {}
local QuestsIDs = {}
rawset(GF, "Quests", Quests)
rawset(GF, "QuestsIDs", QuestsIDs)

local itemTypes = 
{
    dialogue_node = 
    {
        all = DialogueNodes,
        ids = DialogueNodesIDs,
        dir = "ALL_DIALOGUE_NODES/",
        str = "dialogue node",
    },
    status_effect = 
    {
        all = StatusEffects,
        ids = StatusEffectsIDs,
        dir = "effects/",
        str = "effect",
    },
    spell = 
    {
        all = Spells,
        ids = SpellsIDs,
        dir = "spells/",
        str = "spell",
    },
    quest = 
    {
        all = Quests,
        ids = QuestsIDs,
        dir = "quests/",
        str = "quest",
    },
}

--methods for modmain.lua---------------------
--this one loads an item from a file and adds it to the game
function GF.InitItemOfType(type, route)
    local type = itemTypes[type]
    if type == nil then print ("attemp to init incorrect type " .. tostring(type)) return end
    
    local items = require(type.dir .. route)
    assert(items, "could not load an item " .. type.dir .. route)

    for _, item in pairs(items) do
        local id = #(type.ids) + 1

        if type.all[item.name] ~= nil then
            id = type.all[item.name].id
            print(("dialogue node with %s already exists! Overwriting..."):format(item.name))
        end

        item.id = id
        type.all[item.name] = item
        type.ids[item.id] = item.name

        print(("%s <%s> was initialized with ID %i"):format(type.str, item.name, id))
    end
end

--this may be used to make some changes in an existing item
function GF.PostInitItemOfType(type, name, fn)
    local type = itemTypes[type]
    if type == nil then print ("attemp to post init incorrect type " .. tostring(type)) return end

    local item = type.all[name] 
    if item ~= nil then
        print(("DialogueNodePostInit: node %s exists, calling the post init function"):format(name))
        fn(item)
    else
        print(("DialogueNodePostInit: node %s doesn't exist!"):format(name))
    end
end

--############################################
--DIALOGUE NODES------------------------------
--############################################

--*modmain* - this one loads a node from a file and adds it to the game
function GF.InitDialogueNode(route)
    GF.InitItemOfType("dialogue_node", route)
end

--*modmain* - this may be used to make some changes in an existing node
function GF.DialogueNodePostInit(name, fn)
    GF.PostInitItemOfType("dialogue_node", name, fn)
end

--returns an instance of the dialogue_node class
--should be used like the CreateEntity function but for nodes
function GF.CreateDialogueNode()
    local item = require "gf_dialogue_node"
    return item()
end

--should be used as the Prefab function 
--to return a post constructor for the dialogue_node class
function GF.DialogueNode(name, fn)
    local node = fn()
    node.name = name

    return node
end

function GF.GetDialogueNodes()
    return GF.DialogueNodes
end

function GF.GetDialogueNodesIDs()
    return GF.DialogueNodesIDs
end

--############################################
--STATUS EFFECTS------------------------------
--############################################

--*modmain* - this one loads a node from a file and adds it to the game
function GF.InitStatusEffect(route)
    GF.InitItemOfType("status_effect", route)
end

--*modmain* - this may be used to make some changes in an existing node
function GF.StatusEffectPostInit(name, fn)
    GF.PostInitItemOfType("status_effect", name, fn)
end

--returns an instance of the dialogue_node class
--should be used like the CreateEntity function but for nodes
function GF.CreateStatusEffect()
    local effect = require "gf_effect"
    return effect()
end

--should be used as the Prefab function 
--to return a post constructor for the dialogue_node class
function GF.StatusEffect(name, fn)
    local effect = fn()
    effect.name = name

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
    GF.InitItemOfType("spell", route)
end

--*modmain* - this may be used to make some changes in an existing node
function GF.SpellPostInit(name, fn)
    GF.PostInitItemOfType("spell", name, fn)
end

--returns an instance of the dialogue_node class
--should be used like the CreateEntity function but for nodes
function GF.CreateSpell()
    local spell = require "gf_spell"
    return spell()
end

--should be used as the Prefab function 
--to return a post constructor for the dialogue_node class
function GF.Spell(name, fn)
    local spell = fn()
    spell.name = name

    return spell
end

--returns all effects
functionGF.GetSpells()
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
    GF.InitItemOfType("quest", route)
end

--*modmain* - this may be used to make some changes in an existing node
function GF.QuestPostInit(name, fn)
    GF.PostInitItemOfType("quest", name, fn)
end

--returns an instance of the dialogue_node class
--should be used like the CreateEntity function but for nodes
function GF.CreateQuest()
    local quest = require "gf_quest"
    return quest()
end

--should be used as the Prefab function 
--to return a post constructor for the dialogue_node class
function GF.Quest(name, fn)
    local quest = fn()
    quest.name = name

    return quest
end

--returns all effects
function GF.GetQuests()
    return GF.Quests
end

--returns all IDs for effects
function GF.GetQuestsIDs()
    return GF.QuestsIDs
end

local GFIsTogether = _G.TheNet ~= nil and true or false
rawset(_G, "GFIsTogether", GFIsTogether)
--print(("Green Framework: is together: %s"):format(tostring(GFIsTogether)))

local function ReturnTrue()
    return true
end

local function ReturnFalse()
    return false
end

local GFGetIsMasterSim
local GFGetIsDedicatedNet
local GFGetPVPEnabled
local GFGetWorld
local GFGetPlayer

if not GFIsTogether then
    GFGetIsMasterSim = ReturnTrue
    GFGetIsDedicatedNet = ReturnTrue
    GFGetPVPEnabled = ReturnTrue
    GFGetWorld = GetWorld
    GFGetPlayer = GetPlayer
else
    GFGetIsMasterSim = function()
        return TheWorld.ismastersim
    end
    GFGetIsDedicatedNet = function()
        return TheNet:IsDedicated()
    end
    GFGetPVPEnabled = function()
        return TheNet:GetPVPEnabled()
    end
    GFGetWorld = function()
        return TheWorld
    end
    GFGetPlayer = function()
        return ThePlayer
    end
end

rawset(_G, "GFGetIsMasterSim", GFGetIsMasterSim)
rawset(_G, "GFGetIsDedicatedNet", GFGetIsDedicatedNet)
rawset(_G, "GFGetPVPEnabled", GFGetPVPEnabled)
rawset(_G, "GFGetWorld", GFGetWorld)
rawset(_G, "GFGetPlayer", GFGetPlayer)

function GFDebugPrint(...)
    if GFDev then
        print(...)
    end
end

function GFAddCustomSpell(name, route, id)
    GFDebugPrint(string.format("GF-CUSTOM-EFFECT: initializing spell %s%s", name, route))

    id = (id and type(id) == "number") and id or #GF.GetSpellsIDs() + 1
    if GF.GetSpellsIDs()[id] ~= nil then
        error(("Spell with id %i already exists"):format(id), 3)
    end

    local s = require(route .. name)

    if s.name ~= nil then
        name = s.name
    else
        GFDebugPrint(string.format("GF: file %s doesn't have a quest name, setting it to the file name", name))
    end

    GF.GetSpells()[name] = s
    GF.GetSpells()[name].name = name
    GF.GetSpells()[name].id = id
    GFSpellNameToID[name] = id
    GF.GetSpellsIDs()[id] = name

    GFDebugPrint(("GF: SPELL %s created"):format(name))
end

function GFAddCustomEffect(name, route, id)
    GFDebugPrint(string.format("GF-CUSTOM-SPELL: initializing effect %s%s", name, route))

    id = (id and type(id) == "number") and id or #GFEffectIDToName + 1
    if GFEffectIDToName[id] ~= nil then
        error(("Effect with id %i already exists"):format(id), 3)
    end

    local e = require(route .. name)

    if e.name ~= nil then
        name = e.name
    else
        GFDebugPrint(string.format("GF: file %s doesn't have a quest name, setting it to the file name", name))
    end

    GF.GetStatusEffects()[name] = e
    GF.GetStatusEffects()[name].name = name
    GF.GetStatusEffects()[name].id = id
    GF.GetStatusEffectsIDs()[name] = id
    GFEffectIDToName[id] = name

    GFDebugPrint(("GF: EFFECT %s created"):format(name))
end

function GFAddCustomQuest(name, route, modname, id)
    GFDebugPrint(string.format("GF-CUSTOM-QUEST: initializing quest %s%s", name, route))
    --id for quest should be unique
    id = (id and type(id) == "number") and id or #GF.GetQuestsIDs() + 1
    if GF.GetQuestsIDs()[id] ~= nil then
        error(("Quest with id %i already exists"):format(id), 3)
    end

    local q = require(route .. name)

    if q.name ~= nil then
        name = q.name
    else
        GFDebugPrint(string.format("GF: file %s doesn't have a quest name, setting it to the file name", name))
    end
    
    GF.GetQuests[name] = q     --It's a "database" for quests
    GF.GetQuests[name].id = id --unique ID for quest (works only in current session, may change in another)
                                --id are used only for network things, all server/client stuff works with names

    --well, it should help if the quest has an error
    if modname ~= nil then
        GF.GetQuests[name]._modname = modname
    end

    GF.GetQuestsIDs()[id] = name --cached quests IDs
    GFDebugPrint(("GF: QUEST %s created"):format(name))
end

function GFAddBaseAffixes(prefab, type, chance, ...)
    if GFEntitiesBaseAffixes[prefab] == nil then
        GFEntitiesBaseAffixes[prefab] = {}
    end
    local aff = GFEntitiesBaseAffixes[prefab]
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

function GFAddCasterCreature(prefab, fn)
    GFCasterCreatures[prefab] = fn ~= nil and fn or true
end

function GFAddBaseSpells(prefab, ...)
    if GFEntitiesBaseSpells[prefab] == nil then
        GFEntitiesBaseSpells[prefab] = {}
    end

    for i = 1, arg.n do
        table.insert(GFEntitiesBaseSpells[prefab], arg[i])
    end 
end

function GFAddCommunicative(prefab, phrase, wantsToTalkFn, reactFn, isQuestGiver, markOffset)
    if GFCommunicative[prefab] == nil then
        GFCommunicative[prefab] = {}
    end

    GFCommunicative[prefab].quests = isQuestGiver == true and {} or nil
    GFCommunicative[prefab].conversations = {}
    GFCommunicative[prefab].reactFn = reactFn
    GFCommunicative[prefab].wantsToTalkFn = wantsToTalkFn
    GFCommunicative[prefab].markOffset = markOffset
    GFCommunicative[prefab].phrase = phrase
end

function GFAddBaseQuests(prefab, ...)
    if GFCommunicative[prefab] == nil or GFCommunicative[prefab].quests == nil then
        print("can't add quests to", prefab, "because it's not defined as quest giver")
        return 
    end

    for i = 1, arg.n do
        if type(arg[i + 1]) == "number" then
            GFCommunicative[prefab].quests[arg[i]] = arg[i + 1]
            i = i + 1
        else
            GFCommunicative[prefab].quests[arg[i]] = 0
        end
        --table.insert(GFCommunicative[prefab].quests, arg[i])
    end 
end

function GFAddBaseConversations(prefab, ...)
    if GFCommunicative[prefab] == nil then
        print("can't add quests to", prefab, "because it's not defined as interlocutor")
        return 
    end

    for i = 1, arg.n do
        table.insert(GFCommunicative[prefab].conversations, arg[i])
    end 
end

local function PlayerFFCheck(self, target)
    return (target:HasTag("player") and not GFGetPVPEnabled())
        or (self.inst.components.leader and self.inst.components.leader:IsFollower(target))
end

function GFMakePlayerCaster(inst, spells, friendfn)
    if not inst.gfmodified then
        inst.gfmodified = true
        --inst:AddTag("gfscclientside")
        inst._gfclientside = true
        if GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            inst.components.gfspellcaster:SetIsTargetFriendlyFn(friendfn or PlayerFFCheck)
            if spells ~= nil then
                inst.components.gfspellcaster:AddSpell(spells)
            end
        end
    else
        GFDebugPrint(string.format("GF: %s was already initiated ", tostring(inst)))
    end
end

function GFMakeCaster(inst, spells, friendfn)
    if not inst.gfmodified then
        inst.gfmodified = true
        if GFGetIsMasterSim() then
            inst:AddComponent("gfspellcaster")
            if type(friendfn) == "function" then
                inst.components.gfspellcaster:SetIsTargetFriendlyFn(friendfn)
            end
            if spells ~= nil then
                inst.components.gfspellcaster:AddSpells(spells)
            end
        end
    else
        GFDebugPrint(string.format("GF: %s was already initiated ", tostring(inst)))
    end
end

function GFMakeInventoryCastingItem(inst, spells)
    if not inst.gfmodified then
        inst.gfmodified = true
        if GFGetIsMasterSim() then
            inst:AddComponent("gfspellitem")
            if spells ~= nil then
                inst.components.gfspellitem:AddSpells(spells)
            end
        end
    else
        GFDebugPrint(string.format("GF: %s was already initiated ", tostring(inst)))
    end
end

function GFMakeCommunicative(inst, data)
    if GFGetIsMasterSim() then
        inst:AddComponent("gfinterlocutor")
        if data ~= nil then
            if data.phrase ~= nil then inst.components.gfinterlocutor.phrase = data.phrase end
            if data.reactFn ~= nil then inst.components.gfinterlocutor:SetReactFn(data.reactFn) end
            if data.wantsToTalkFn then inst.components.gfinterlocutor.wantsToTalkFn = data.wantsToTalkFn end
            if data.conversations ~= nil then
                for k, conv in pairs(data.conversations) do
                    inst.components.gfinterlocutor:AddConversation(conv)
                end
            end

            if data.quests ~= nil then
                inst:AddComponent("gfquestgiver")
                for k, v in pairs(data.quests) do
                    inst.components.gfquestgiver:AddQuest(k, v)
                end
            end
        end
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

function GFPumpkinTest(entity)
    entity = entity or AllPlayers[1]
    local x, y, z = entity.Transform:GetWorldPosition()
    for i = 1, 12 do
        local pt = Vector3(x + math.cos(i * 30) * 10, y, z - math.sin(i * 30) * 10)
        SpawnPrefab("pumpkin_lantern").Transform:SetPosition(pt:Get())
    end
end

function GFTestGlobalFunctions()
    print("GFGetIsMasterSim", GFGetIsMasterSim())
    print("GFGetIsDedicatedNet", GFGetIsDedicatedNet())
    print("GFGetPVPEnabled", GFGetPVPEnabled())
    print("GFGetWorld", GFGetWorld())
    print("GFGetPlayer", GFGetPlayer())
end

function GetQuestKey(qName, hash)
    if qName ~= nil and GF.GetQuests[qName] ~= nil then
        return GF.GetQuests[qName].unique
            and qName
            or (hash ~= nil and qName .. '#' .. hash or nil)
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

--rawset(_G, "GFTestGlobalFunctions", GFTestGlobalFunctions)