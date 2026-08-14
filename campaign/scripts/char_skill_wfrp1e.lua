--[[
    WFRP1E
    Character-owned Skill row

    Repeated-acquisition information is derived from the Character's
    independent owned Skill instances. No acquisition count or rank is
    persisted on the Skill itself.

    Standard Test information shown here is also diagnostic/presentational
    only. The registry returns potentially relevant named Standard Tests for
    the Skill's stable rulesId. The Core Rulebook leaves actual applicability
    to the GM; this script does not apply modifiers or roll tests.
]]

local function getCharacterNode()
    local nodeOwnedSkill = getDatabaseNode()

    if not nodeOwnedSkill then
        return nil
    end

    local nodeSkills =
        DB.getParent(
            nodeOwnedSkill
        )

    if not nodeSkills then
        return nil
    end

    return DB.getParent(
        nodeSkills
    )
end


function refreshSkillTooltip()
    local nodeOwnedSkill = getDatabaseNode()
    local nodeChar = getCharacterNode()

    if not nodeOwnedSkill or not nodeChar then
        name.setTooltipText("")
        return
    end

    local sRulesId =
        DB.getValue(
            nodeOwnedSkill,
            "rulesId",
            ""
        )

    local nAcquisitions =
        CharacterSkillManagerWFRP1E.getAcquisitionCount(
            nodeChar,
            sRulesId
        )

    local nRepeatedModifier =
        CharacterSkillManagerWFRP1E.getRepeatedAcquisitionModifier(
            nodeChar,
            sRulesId
        )

    local aPotentialTests =
        DataStandardTestsWFRP1E.getPotentialStandardTestsForSkill(
            sRulesId
        )

    local aLines = {}

    if nAcquisitions > 1
        or nRepeatedModifier ~= nil
    then
        table.insert(
            aLines,
            "Acquisitions: "
            .. tostring(nAcquisitions)
        )
    end

    if nRepeatedModifier ~= nil then
        table.insert(
            aLines,
            "Repeat acquisition bonus: +"
            .. tostring(nRepeatedModifier)
            .. "%"
        )
    end

    if #aPotentialTests > 0 then
        table.insert(
            aLines,
            "Potential Standard Tests: "
            .. table.concat(
                aPotentialTests,
                ", "
            )
        )
    end

    name.setTooltipText(
        table.concat(
            aLines,
            "\n"
        )
    )
end


function onInit()
    refreshSkillTooltip()
end
