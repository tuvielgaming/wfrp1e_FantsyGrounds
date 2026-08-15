--[[
    WFRP1E
    Canonical core Skill identity registry

    English Core Rulebook printed p.45, INDEX TO THE SKILLS, is the
    canonical source for this 133-entry core Skill list.

    Persisted rulesId values are stable language-neutral mechanical IDs.
    Display labels come from string resources so localization never changes
    persisted identity.

    Compatibility note:
        The rulebook display name "Jest" retains the established mechanical
        identity "jester" used by the read-only Foundry reference.
]]

local tDefinitions = {
    { id = "acrobatics", textres = "wfrp1e_skill_identity_acrobatics" },
    { id = "acting", textres = "wfrp1e_skill_identity_acting" },
    { id = "acuteHearing", textres = "wfrp1e_skill_identity_acuteHearing" },
    { id = "ambidextrous", textres = "wfrp1e_skill_identity_ambidextrous" },
    { id = "animalCare", textres = "wfrp1e_skill_identity_animalCare" },
    { id = "animalTraining", textres = "wfrp1e_skill_identity_animalTraining" },
    { id = "arcaneLanguage", textres = "wfrp1e_skill_identity_arcaneLanguage" },
    { id = "art", textres = "wfrp1e_skill_identity_art" },
    { id = "astronomy", textres = "wfrp1e_skill_identity_astronomy" },
    { id = "begging", textres = "wfrp1e_skill_identity_begging" },
    { id = "blather", textres = "wfrp1e_skill_identity_blather" },
    { id = "boatBuilding", textres = "wfrp1e_skill_identity_boatBuilding" },
    { id = "brewing", textres = "wfrp1e_skill_identity_brewing" },
    { id = "bribery", textres = "wfrp1e_skill_identity_bribery" },
    { id = "carpentry", textres = "wfrp1e_skill_identity_carpentry" },
    { id = "cartography", textres = "wfrp1e_skill_identity_cartography" },
    { id = "castSpells", textres = "wfrp1e_skill_identity_castSpells" },
    { id = "charm", textres = "wfrp1e_skill_identity_charm" },
    { id = "charmAnimal", textres = "wfrp1e_skill_identity_charmAnimal" },
    { id = "chemistry", textres = "wfrp1e_skill_identity_chemistry" },
    { id = "clown", textres = "wfrp1e_skill_identity_clown" },
    { id = "comedian", textres = "wfrp1e_skill_identity_comedian" },
    { id = "concealmentRural", textres = "wfrp1e_skill_identity_concealmentRural" },
    { id = "concealmentUrban", textres = "wfrp1e_skill_identity_concealmentUrban" },
    { id = "consumeAlcohol", textres = "wfrp1e_skill_identity_consumeAlcohol" },
    { id = "contortionist", textres = "wfrp1e_skill_identity_contortionist" },
    { id = "cook", textres = "wfrp1e_skill_identity_cook" },
    { id = "cryptography", textres = "wfrp1e_skill_identity_cryptography" },
    { id = "cureDisease", textres = "wfrp1e_skill_identity_cureDisease" },
    { id = "dance", textres = "wfrp1e_skill_identity_dance" },
    { id = "demonLore", textres = "wfrp1e_skill_identity_demonLore" },
    { id = "disarm", textres = "wfrp1e_skill_identity_disarm" },
    { id = "disguise", textres = "wfrp1e_skill_identity_disguise" },
    { id = "divining", textres = "wfrp1e_skill_identity_divining" },
    { id = "dodgeBlow", textres = "wfrp1e_skill_identity_dodgeBlow" },
    { id = "dowsing", textres = "wfrp1e_skill_identity_dowsing" },
    { id = "driveCart", textres = "wfrp1e_skill_identity_driveCart" },
    { id = "embezzling", textres = "wfrp1e_skill_identity_embezzling" },
    { id = "engineer", textres = "wfrp1e_skill_identity_engineer" },
    { id = "escapology", textres = "wfrp1e_skill_identity_escapology" },
    { id = "etiquette", textres = "wfrp1e_skill_identity_etiquette" },
    { id = "evaluate", textres = "wfrp1e_skill_identity_evaluate" },
    { id = "excellentVision", textres = "wfrp1e_skill_identity_excellentVision" },
    { id = "fireEating", textres = "wfrp1e_skill_identity_fireEating" },
    { id = "fish", textres = "wfrp1e_skill_identity_fish" },
    { id = "flee", textres = "wfrp1e_skill_identity_flee" },
    { id = "fleetFooted", textres = "wfrp1e_skill_identity_fleetFooted" },
    { id = "followTrail", textres = "wfrp1e_skill_identity_followTrail" },
    { id = "frenziedAttack", textres = "wfrp1e_skill_identity_frenziedAttack" },
    { id = "gamble", textres = "wfrp1e_skill_identity_gamble" },
    { id = "gameHunting", textres = "wfrp1e_skill_identity_gameHunting" },
    { id = "gemCutting", textres = "wfrp1e_skill_identity_gemCutting" },
    { id = "haggle", textres = "wfrp1e_skill_identity_haggle" },
    { id = "healWounds", textres = "wfrp1e_skill_identity_healWounds" },
    { id = "heraldry", textres = "wfrp1e_skill_identity_heraldry" },
    { id = "herbLore", textres = "wfrp1e_skill_identity_herbLore" },
    { id = "history", textres = "wfrp1e_skill_identity_history" },
    { id = "hypnotise", textres = "wfrp1e_skill_identity_hypnotise" },
    { id = "identifyMagicalArtifact", textres = "wfrp1e_skill_identity_identifyMagicalArtifact" },
    { id = "identifyPlant", textres = "wfrp1e_skill_identity_identifyPlant" },
    { id = "identifyUndead", textres = "wfrp1e_skill_identity_identifyUndead" },
    { id = "immunityToDisease", textres = "wfrp1e_skill_identity_immunityToDisease" },
    { id = "immunityToPoison", textres = "wfrp1e_skill_identity_immunityToPoison" },
    { id = "jester", textres = "wfrp1e_skill_identity_jester" },
    { id = "juggle", textres = "wfrp1e_skill_identity_juggle" },
    { id = "law", textres = "wfrp1e_skill_identity_law" },
    { id = "lightningReflexes", textres = "wfrp1e_skill_identity_lightningReflexes" },
    { id = "linguistics", textres = "wfrp1e_skill_identity_linguistics" },
    { id = "lipReading", textres = "wfrp1e_skill_identity_lipReading" },
    { id = "luck", textres = "wfrp1e_skill_identity_luck" },
    { id = "magicalAwareness", textres = "wfrp1e_skill_identity_magicalAwareness" },
    { id = "magicalSense", textres = "wfrp1e_skill_identity_magicalSense" },
    { id = "manufactureDrugs", textres = "wfrp1e_skill_identity_manufactureDrugs" },
    { id = "manufactureMagicItems", textres = "wfrp1e_skill_identity_manufactureMagicItems" },
    { id = "manufacturePotions", textres = "wfrp1e_skill_identity_manufacturePotions" },
    { id = "manufactureScrolls", textres = "wfrp1e_skill_identity_manufactureScrolls" },
    { id = "marksmanship", textres = "wfrp1e_skill_identity_marksmanship" },
    { id = "meditation", textres = "wfrp1e_skill_identity_meditation" },
    { id = "metallurgy", textres = "wfrp1e_skill_identity_metallurgy" },
    { id = "mime", textres = "wfrp1e_skill_identity_mime" },
    { id = "mimic", textres = "wfrp1e_skill_identity_mimic" },
    { id = "mining", textres = "wfrp1e_skill_identity_mining" },
    { id = "musicianship", textres = "wfrp1e_skill_identity_musicianship" },
    { id = "nightVision", textres = "wfrp1e_skill_identity_nightVision" },
    { id = "numismatics", textres = "wfrp1e_skill_identity_numismatics" },
    { id = "orientation", textres = "wfrp1e_skill_identity_orientation" },
    { id = "palmistry", textres = "wfrp1e_skill_identity_palmistry" },
    { id = "palmObject", textres = "wfrp1e_skill_identity_palmObject" },
    { id = "pickLock", textres = "wfrp1e_skill_identity_pickLock" },
    { id = "pickPocket", textres = "wfrp1e_skill_identity_pickPocket" },
    { id = "preparePoisons", textres = "wfrp1e_skill_identity_preparePoisons" },
    { id = "publicSpeaking", textres = "wfrp1e_skill_identity_publicSpeaking" },
    { id = "readWrite", textres = "wfrp1e_skill_identity_readWrite" },
    { id = "ride", textres = "wfrp1e_skill_identity_ride" },
    { id = "riverLore", textres = "wfrp1e_skill_identity_riverLore" },
    { id = "row", textres = "wfrp1e_skill_identity_row" },
    { id = "runeLore", textres = "wfrp1e_skill_identity_runeLore" },
    { id = "runeMastery", textres = "wfrp1e_skill_identity_runeMastery" },
    { id = "sailing", textres = "wfrp1e_skill_identity_sailing" },
    { id = "scaleSheerSurface", textres = "wfrp1e_skill_identity_scaleSheerSurface" },
    { id = "scrollLore", textres = "wfrp1e_skill_identity_scrollLore" },
    { id = "secretLanguage", textres = "wfrp1e_skill_identity_secretLanguage" },
    { id = "secretSign", textres = "wfrp1e_skill_identity_secretSign" },
    { id = "seduction", textres = "wfrp1e_skill_identity_seduction" },
    { id = "setTrap", textres = "wfrp1e_skill_identity_setTrap" },
    { id = "shadowing", textres = "wfrp1e_skill_identity_shadowing" },
    { id = "silentMoveRural", textres = "wfrp1e_skill_identity_silentMoveRural" },
    { id = "silentMoveUrban", textres = "wfrp1e_skill_identity_silentMoveUrban" },
    { id = "sing", textres = "wfrp1e_skill_identity_sing" },
    { id = "sixthSense", textres = "wfrp1e_skill_identity_sixthSense" },
    { id = "smithing", textres = "wfrp1e_skill_identity_smithing" },
    { id = "speakAdditionalLanguage", textres = "wfrp1e_skill_identity_speakAdditionalLanguage" },
    { id = "specialistWeapon", textres = "wfrp1e_skill_identity_specialistWeapon" },
    { id = "spotTraps", textres = "wfrp1e_skill_identity_spotTraps" },
    { id = "stoneworking", textres = "wfrp1e_skill_identity_stoneworking" },
    { id = "storyTelling", textres = "wfrp1e_skill_identity_storyTelling" },
    { id = "streetFighter", textres = "wfrp1e_skill_identity_streetFighter" },
    { id = "strikeMightyBlow", textres = "wfrp1e_skill_identity_strikeMightyBlow" },
    { id = "strikeToInjure", textres = "wfrp1e_skill_identity_strikeToInjure" },
    { id = "strikeToStun", textres = "wfrp1e_skill_identity_strikeToStun" },
    { id = "strongman", textres = "wfrp1e_skill_identity_strongman" },
    { id = "superNumerate", textres = "wfrp1e_skill_identity_superNumerate" },
    { id = "surgery", textres = "wfrp1e_skill_identity_surgery" },
    { id = "swim", textres = "wfrp1e_skill_identity_swim" },
    { id = "tailor", textres = "wfrp1e_skill_identity_tailor" },
    { id = "theology", textres = "wfrp1e_skill_identity_theology" },
    { id = "torture", textres = "wfrp1e_skill_identity_torture" },
    { id = "trickRiding", textres = "wfrp1e_skill_identity_trickRiding" },
    { id = "ventriloquism", textres = "wfrp1e_skill_identity_ventriloquism" },
    { id = "veryResilient", textres = "wfrp1e_skill_identity_veryResilient" },
    { id = "veryStrong", textres = "wfrp1e_skill_identity_veryStrong" },
    { id = "wit", textres = "wfrp1e_skill_identity_wit" },
    { id = "wrestling", textres = "wfrp1e_skill_identity_wrestling" },
}

local tById = {}
for _, tDefinition in ipairs(tDefinitions) do
    tById[tDefinition.id] = tDefinition
end

local function normalizeId(sValue)
    return tostring(sValue or ""):match("^%s*(.-)%s*$")
end

function getDefinitions()
    local aResult = {}
    for _, tDefinition in ipairs(tDefinitions) do
        table.insert(
            aResult,
            {
                id = tDefinition.id,
                textres = tDefinition.textres
            }
        )
    end
    return aResult
end

function getDefinition(sRulesId)
    local tDefinition = tById[normalizeId(sRulesId)]
    if not tDefinition then
        return nil
    end

    return {
        id = tDefinition.id,
        textres = tDefinition.textres
    }
end

function isCanonicalRulesId(sRulesId)
    return tById[normalizeId(sRulesId)] ~= nil
end

function getDisplayLabel(sRulesId)
    local sId = normalizeId(sRulesId)

    if sId == "" then
        return Interface.getString("wfrp1e_skill_rules_id_unlinked")
    end

    local tDefinition = tById[sId]
    if tDefinition then
        local sLabel = Interface.getString(tDefinition.textres)
        if sLabel ~= "" then
            return sLabel
        end
    end

    return
        Interface.getString("wfrp1e_skill_rules_id_custom")
        .. ": "
        .. sId
end

function getDisplayText(sRulesId)
    local sId = normalizeId(sRulesId)
    local sLabel = getDisplayLabel(sId)

    if sId == "" then
        return sLabel
    end

    return
        sLabel
        .. " ["
        .. sId
        .. "]"
end
