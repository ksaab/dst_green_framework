local function fn()
    local spell = GF.CreateSpell("throw_archetype")

    spell:AddTag("action")

    spell.icon = "chainlightning.tex"
    spell.iconAtlas = "images/iconspack.xml"

    spell.pointer = 
    {
        pointerPrefab = "reticulelongmulti", --prefab
        isArrow = true,
        prefersTarget = false, --if true targets entity under cursor (mouse) or search for a target in front of the player (gamepad)
    }

    return spell
end

return GF.Spell("throw_weapon", fn)