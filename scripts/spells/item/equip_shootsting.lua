local SpellArchetype = require("spells/archetypes/shoot_archetype")

local function ProjOnDone(proj, victim)
    local bee = SpawnPrefab("bee")
    if bee ~= nil then
        bee.Transform:SetPosition(proj.Transform:GetWorldPosition())
    end
    if victim ~= nil then
        victim.components.combat:GetAttacked(bee or proj.shooter or proj, 50)
        if bee ~= nil then
            bee.components.combat:SetTarget(victim)
            bee.sg:GoToState("hit")
        end
    end
end

local function ProjOnHit(proj, victim)
    if victim ~= nil then
        victim.components.combat:GetAttacked(proj.shooter or proj, 50)
    end
end

local Spell = Class(SpellArchetype, function(self)
    SpellArchetype._ctor(self, "equip_shootsting") --inheritance
    --self.iconAtlas = "images/gficons.xml"
    --self.icon = "groundslam.tex"
    self.playerState = "gftdartshoot"
    self.pointer = 
    {
        isArrow = true,
        prefersTarget = false,
        pointerPrefab = "reticulelongmulti",
        validColour = { 75 / 255, 200 / 255, 255 / 255, .3 },
        range = self.range,
    }

    self.spellParams.ammoPrefab = "bee"
    self.spellParams.ammoPerShot = 1

    self.spellParams =
    {
        requiresAmmo = true,
        ammoPrefab = "bee",
        ammoPerShot = 1,
        projPenetrate = false,
        projPrefab = "gf_bee_dart_proj",
        projTTL = 0.5,
        projOnHit = ProjOnHit,
        projOnDone = ProjOnDone,
    }
    
    self.itemRecharge = 0
    self.doerRecharge = 0
end)

return Spell()