local ALL_QUESTS = GF.GetQuests()
local QUESTS_IDS = GF.GetQuestsIDs()
local ALL_DIALOGUE_NODES = GF.GetDialogueNodes()
local DIALOGUE_NODES_IDS = GF.GetDialogueNodesIDs()
local PopShop = require "screens/gf_shop"

local function TrackInterlocutor(inst, interlocutor)
    if not inst:IsValid() or not interlocutor:IsValid() or not inst:IsNear(interlocutor, 15) then
        inst.components.gfplayerdialog:CloseDialog() 
    end
end

local GFPlayerDialog = Class(function(self, inst)
    self.inst = inst

    if self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end

    self.canSpeak = true
    
    self._trackTask = nil
    self._trackInterlocutor = nil
    self._trackQuests = {} --quests
    self._trackNodes = {} --on click events
    --self._trackDialog = {} --info strings

    local function _trackFail()
        self:CloseDialog() 
    end

    inst:ListenForEvent("death", function() _trackFail() end)
    inst:ListenForEvent("onremove", function() _trackFail() end)
end)

-----------------------------------
--classified methods---------------
-----------------------------------
function GFPlayerDialog:AttachClassified(classified)
    if self.classified ~= nil then return end

    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function GFPlayerDialog:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

-----------------------------------
--conversation methods-------------
-----------------------------------
--unsafe, don't use it directly
function GFPlayerDialog:KeepConversation(interlocutor, data) 
    if data ~= nil then
        if self._trackInterlocutor == nil and interlocutor ~= nil then
            self:StartConversationWith(interlocutor, data)
        else
            self:PushDialog(data[1], data[2], data[3], data[4])
        end
    end
end

--safe
--args: interlocutor [entity with the gfinterlocutor component], data - <node name [string], choises [string[]], quests to offer [string[]], quests to complete [string[]]>
--return: nothing
--use this to show a dialogue without interlocutor
function GFPlayerDialog:StartConversation(data) 
    if data ~= nil then
        self:StopTrack()
        self:PushDialog(data[1], data[2], data[3], data[4])
    end
end

--safe
--args: interlocutor [entity with the gfinterlocutor component], data - <node name [string], choises [string[]], quests to offer [string[]], quests to complete [string[]]>
--return: nothing
--use this to start a conversation with an interlocutor
function GFPlayerDialog:StartConversationWith(interlocutor, data, pushQuests) --safe
    if not self.canSpeak or interlocutor == nil or data == nil or interlocutor.components.gfinterlocutor == nil then return false end

    if self._trackInterlocutor ~= interlocutor then
        self:StartTrack(interlocutor, true)
    end

    if pushQuests then
        local quests = (interlocutor.components.gfquestgiver ~= nil)
            and interlocutor.components.gfquestgiver:PickQuests(self.inst)
            or nil
        if quests ~= nil then
            self:PushDialog(data[1], data[2], quests.offer, quests.complete)
            return
        end
    end

    self:PushDialog(data[1], data[2], data[3], data[4])
end

--unsafe, do not use it directly
function GFPlayerDialog:PushDialog(strid, nodes, offer, complete) 
    self._trackQuests = {}
    self._trackNodes = {}
    --self._trackDialog = {}
    --dialog for a host palyer
    if GFGetPlayer() == self.inst and not GFGetIsDedicatedNet() then
        if offer ~= nil and #offer > 0 then
            for i = 1, #offer do
                if ALL_QUESTS[offer[i]] ~= nil then
                    self._trackQuests[offer[i]] = true
                end
            end
        end

        if complete ~= nil and #complete > 0 then
            for i = 1, #complete do
                if ALL_QUESTS[complete[i]] ~= nil then
                    self._trackQuests[complete[i]] = true
                end
            end
        end

        if nodes ~= nil and #nodes > 0 then
            for i = 1, #nodes do
                if ALL_DIALOGUE_NODES[nodes[i]] ~= nil then
                    self._trackNodes[nodes[i]] = true
                end
            end
        end

        self.inst:PushEvent("gfPDChoiseDialog", 
        {
            dString = strid ~= nil and string.upper(strid) or "DEFAULT",
            gQuests = offer or {},
            cQuests = complete or {},
            events = nodes or {},
        })

        --GFDebugPrint("Creating a dialog for host player")
        return true
    end

    if self.classified == nil then return false end

    local str = {strid ~= nil and string.upper(strid) or "DEFAULT"}

    --dialog for clients
    if offer ~= nil and #offer > 0 then
        for i = 1, #offer do
            self._trackQuests[offer[i]] = true
            offer[i] = ALL_QUESTS[offer[i]].id
        end
        str[2] = table.concat(offer, ';')
    else
        str[2] = '_'
    end

    if complete ~= nil and #complete > 0 then
        for i = 1, #complete do
            self._trackQuests[complete[i]] = true
            complete[i] = ALL_QUESTS[complete[i]].id
        end
        str[3] = table.concat(complete, ';')
    else
        str[3] = '_'
    end

    if nodes ~= nil and #nodes > 0 then
        for i = 1, #nodes do
            if ALL_DIALOGUE_NODES[nodes[i]] ~= nil then
                self._trackNodes[nodes[i]] = true
                nodes[i] = ALL_DIALOGUE_NODES[nodes[i]].id
            end
        end
        str[4] = table.concat(nodes, ';')
    else
        str[4] = '_'
    end

    str = table.concat(str, '^')
    self.classified._gfPDPushDialog:set_local(str)
    self.classified._gfPDPushDialog:set(str)

    --GFDebugPrint("Creating a dialog for client player")
    return true
end

--safe
--args: none
--return: nothing
--use this to stop a conversation
function GFPlayerDialog:CloseDialog()
    self._trackQuests = {} --quests
    self._trackNodes = {} --on click events
    --self._trackDialog = {} --info strings

    self:StopTrack()

    if self.inst == GFGetPlayer() then
        --GFDebugPrint("Closing a dialog for host player")
        self.inst:PushEvent("gfPDCloseDialog")
    elseif self.classified ~= nil then
        --GFDebugPrint("Closing a dialog for client player")
        self.classified._gfPDCloseDialog:push()
    end
end

function GFPlayerDialog:GetTrackingHash()
    return (self._trackInterlocutor ~= nil) 
        and self._trackInterlocutor.components.gfquestgiver:GetHash()
        or nil
end

function GFPlayerDialog:GetTrackingEntity()
    return self._trackInterlocutor
end

function GFPlayerDialog:CanSpeak()
    return self.canSpeak
end

-----------------------------------------
--track methods--------------------------
-----------------------------------------
--unsafe
function GFPlayerDialog:StartTrack(interlocutor, checkDistance)
    if interlocutor == nil or interlocutor.components.gfinterlocutor == nil then 
        --print("ilocutor is nil")
        self:StopTrack()
        return false 
    elseif self._trackInterlocutor == interlocutor then
        --print("ilocutor is same")
        return true
    end

    self:StopTrack()
    
    self._trackInterlocutor = interlocutor
    interlocutor.components.gfinterlocutor:SetListeners(self.inst)

    if checkDistance then
        self._trackTask = self.inst:DoPeriodicTask(0.5, TrackInterlocutor, nil, interlocutor)
    end

    --GFDebugPrint(("%s has started tracking %s"):format(tostring(self.inst), tostring(self._trackInterlocutor)))
    return true
end

--unsafe
function GFPlayerDialog:StopTrack()
    if self._trackInterlocutor == nil then return end

    self._trackInterlocutor.components.gfinterlocutor:RemoveListeners()

    if self._trackTask ~= nil then
        self._trackTask:Cancel()
        self._trackTask = nil
    end

    --GFDebugPrint(("%s has stopped tracking %s"):format(tostring(self.inst), tostring(self._trackInterlocutor)))
    self._trackInterlocutor = nil
end

-----------------------------------------
--network methods------------------------
-----------------------------------------
--unsafe
function GFPlayerDialog:HandleButton(event, name, hash)
    --client just need to send an rpc
    if not GFGetIsMasterSim() then
        SendModRPCToServer(MOD_RPC["GreenFramework"]["GFDIALOGRPC"], event, name, hash)
        return
    end

    --event: 0 - close, 1 - dialogue node, 2 - accept a quest, 3 - complete a quest, 4 - abandon a quest
    if event == 0 then
        self:CloseDialog()
    elseif event == 1 then
        --client has clicked a non-quest button in the dialogue window
        local nInst = ALL_DIALOGUE_NODES[name]
        local initiator = self:GetTrackingEntity()

        if self._trackNodes[name]
            and nInst ~= nil
            and nInst:Check(self.inst, initiator)
        then 
            nInst:RunNode(self.inst, initiator)
        else
            print(string.format("WARNING: %s tries to run impermissible event %s", tostring(self.inst), name)) 
        end
    elseif self.inst.components.gfquestdoer ~= nil then
        --client has clicked a quest button in the dialogue window
        if self._trackQuests[name] and ALL_QUESTS[name] ~= nil then
            local giver = self:GetTrackingEntity()
            if event == 2 then
                --client attempts to accept a quest
                local giver = self:GetTrackingEntity()
                if giver ~= nil then
                    if giver.components.gfquestgiver:IsGiverFor(name) then
                        self.inst.components.gfquestdoer:AcceptQuest(name, self:GetTrackingHash())
                        self:CloseDialog()
                    else
                        print(string.format("WARNING: %s tries to accept quest %s", tostring(self.inst), name)) 
                    end
                else
                    self.inst.components.gfquestdoer:AcceptQuest(name)
                    self:CloseDialog()
                end
            elseif event == 3 then
                --client attempts to complete a quest
                local giver = self:GetTrackingEntity()
                if giver ~= nil then
                    if giver.components.gfquestgiver:IsCompleterFor(name) then
                        self.inst.components.gfquestdoer:CompleteQuest(name, self:GetTrackingHash())
                        self:CloseDialog()
                    else
                        print(string.format("WARNING: %s tries to complete quest %s", tostring(self.inst), name)) 
                    end
                else
                    self.inst.components.gfquestdoer:CompleteQuest(name)
                    self:CloseDialog()
                end
            end
        elseif event == 4 then
            --abandon quest
            --actually this event is not from the player dialog window, but there is no reason to create a new rpc
            self.inst.components.gfquestdoer:AbandonQuest(name, hash)
        end
    else
        print(string.format("WARNING: unknown event %s from %s", tostring(event), tostring(self.inst))) 
    end
end

--unsafe, feature for the future update
--[[-----------------------------------
function GFPlayerDialog:StartTradingWith(shop)
    if shop == nil or shop.components.gfshop == nil then return false end
    if self:StartTrack(shop) then
        self:PushShopScreen(shop.components.gfshop:GetList())
    end
end

function GFPlayerDialog:PushShopScreen(list)
    if GFGetPlayer() == self.inst then
        local t = {}
        for k, v in pairs(list) do
            table.insert(t, {id = k, currency = v.currency, price = v.price})
        end

        self.inst:PushEvent("gfShopOpen", t)
        --TheFrontEnd:PushScreen(PopShop(self.inst, t))
    else
        local str = {}
        for id, item in pairs(list) do
            table.insert(str, string.format("%i;%i;%i", id, item.currency.id, item.price))
        end
        self.classified._gfShopString:set_local(str)
        self.classified._gfShopString:set(str)
    end
end

function GFPlayerDialog:HandleShopButton(event, itemID, num)
    --events - 0 close dialog, 1 - buy something
    if event == 0 then
        print(self.inst, "closed shop")
    elseif event == 1 then
        local shop = self:GetTrackingEntity()
        if shop ~= nil and shop.components.gfshop ~= nil and shop.components.gfshop:SellItems(self.inst, itemID, num) then
            print(self.inst, "bought", GF.ShopItems[itemID].dispname)
        end
    end
end
-------------------------------------]]

function GFPlayerDialog:GetDebugString()

    return string.format("talker: %s", tostring(self._trackInterlocutor))
end


return GFPlayerDialog