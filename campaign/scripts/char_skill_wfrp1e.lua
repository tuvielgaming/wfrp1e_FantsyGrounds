--[[
    WFRP1E
    Character-owned Skill row

    Repeated-acquisition information is derived from the Character's
    independent owned Skill instances. No acquisition count or rank is
    persisted on the Skill itself.

    Standard Test information shown here is diagnostic/presentational only.
    The registry returns potentially relevant named Standard Tests for the
    Skill's stable rulesId. The Core Rulebook leaves actual Skill applicability
    to the GM.

    #10H exposes resolvable BASE target numbers.

    #10I adds an intentionally narrow roll launcher:
        Ctrl+Double-click the owned Skill name only when the Skill maps to
        exactly one named Standard Test and that test's BASE target can be
        resolved locally.

    #10J diagnoses what this explicitly selected owned Skill contributes when
    that effect is a context-free fixed modifier or a verified repeated-
    acquisition modifier.

    #10K feeds that already-verified selected Skill modifier into the roll
    target. The clicked owned Skill is the explicit applicability choice.

    Multiple candidate tests and context-dependent tests are deliberately not
    launched from this row because selecting/resolving them requires explicit
    GM/player input in later checkpoints.
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


local function getRulesId(nodeOwnedSkill)
    return
        DB.getValue(
            nodeOwnedSkill,
            "rulesId",
            ""
        )
end


local function signedModifier(nModifier)
    nModifier = tonumber(nModifier) or 0

    if nModifier >= 0 then
        return "+" .. tostring(nModifier)
    end

    return tostring(nModifier)
end


local function getUnambiguousBaseTest(
    nodeChar,
    sRulesId
)
    local aPotentialTests =
        DataStandardTestsWFRP1E.getPotentialStandardTestsForSkill(
            sRulesId
        )

    if #aPotentialTests ~= 1 then
        return nil, nil
    end

    local sTestId =
        aPotentialTests[1]

    local tResolved =
        StandardTestManagerWFRP1E.resolveBaseTarget(
            nodeChar,
            sTestId
        )

    if not tResolved.valid then
        return nil, tResolved
    end

    return sTestId, tResolved
end


local function addBaseTargetDiagnostics(
    nodeChar,
    aPotentialTests,
    aLines
)
    local aResolved = {}
    local aContextRequired = {}

    for _, sTestId in ipairs(aPotentialTests) do
        local tResult =
            StandardTestManagerWFRP1E.resolveBaseTarget(
                nodeChar,
                sTestId
            )

        if tResult.valid then
            table.insert(
                aResolved,
                sTestId
                .. " "
                .. tostring(tResult.baseTarget)
                .. "%"
            )
        elseif tResult.reason == "context-required" then
            table.insert(
                aContextRequired,
                sTestId
            )
        end
    end

    if #aResolved > 0 then
        table.insert(
            aLines,
            "Resolved base targets (no Skill bonus): "
            .. table.concat(
                aResolved,
                ", "
            )
        )
    end

    if #aContextRequired > 0 then
        table.insert(
            aLines,
            "Context required: "
            .. table.concat(
                aContextRequired,
                ", "
            )
        )
    end
end


local function addSelectedSkillModifierDiagnostics(
    nodeChar,
    sRulesId,
    aPotentialTests,
    aLines
)
    local aResolved = {}

    for _, sTestId in ipairs(aPotentialTests) do
        local tResult =
            StandardTestManagerWFRP1E.resolveSelectedSkillModifier(
                nodeChar,
                sRulesId,
                sTestId
            )

        if tResult.valid then
            local nModifier =
                tonumber(
                    tResult.modifier
                )
                or 0

            table.insert(
                aResolved,
                sTestId
                .. " "
                .. signedModifier(nModifier)
                .. "%"
            )
        end
    end

    if #aResolved > 0 then
        table.insert(
            aLines,
            "Selected Skill modifiers: "
            .. table.concat(
                aResolved,
                ", "
            )
        )
    end
end


function refreshSkillTooltip()
    local nodeOwnedSkill = getDatabaseNode()
    local nodeChar = getCharacterNode()

    if not nodeOwnedSkill or not nodeChar then
        name.setTooltipText("")
        return
    end

    local sRulesId =
        getRulesId(
            nodeOwnedSkill
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

        addBaseTargetDiagnostics(
            nodeChar,
            aPotentialTests,
            aLines
        )

        addSelectedSkillModifierDiagnostics(
            nodeChar,
            sRulesId,
            aPotentialTests,
            aLines
        )
    end

    local sRollTestId, tBaseTarget =
        getUnambiguousBaseTest(
            nodeChar,
            sRulesId
        )

    if sRollTestId and tBaseTarget then
        local tSelectedTarget =
            StandardTestManagerWFRP1E.resolveSelectedSkillTarget(
                nodeChar,
                sRulesId,
                sRollTestId
            )

        if tSelectedTarget.valid then
            table.insert(
                aLines,
                "Ctrl+Double-click: Roll "
                .. sRollTestId
                .. " test vs "
                .. tostring(tSelectedTarget.target)
                .. "% (base "
                .. tostring(tSelectedTarget.baseTarget)
                .. "% + Skill "
                .. signedModifier(tSelectedTarget.skillModifier)
                .. "%)"
            )
        else
            table.insert(
                aLines,
                "Ctrl+Double-click: Roll BASE "
                .. sRollTestId
                .. " test vs "
                .. tostring(tBaseTarget.baseTarget)
                .. "% (no audited numeric Skill modifier)"
            )
        end
    end

    name.setTooltipText(
        table.concat(
            aLines,
            "\n"
        )
    )
end


function handleBaseTestDoubleClick()
    if not Input.isControlPressed() then
        return false
    end

    local nodeOwnedSkill =
        getDatabaseNode()

    local nodeChar =
        getCharacterNode()

    if not nodeOwnedSkill or not nodeChar then
        return false
    end

    local sRulesId =
        getRulesId(
            nodeOwnedSkill
        )

    local sTestId =
        getUnambiguousBaseTest(
            nodeChar,
            sRulesId
        )

    if not sTestId then
        return false
    end

    local tSelectedTarget =
        StandardTestManagerWFRP1E.resolveSelectedSkillTarget(
            nodeChar,
            sRulesId,
            sTestId
        )

    local tResult

    if tSelectedTarget.valid then
        tResult =
            StandardTestManagerWFRP1E.performSelectedSkillTest(
                nodeChar,
                sRulesId,
                sTestId
            )
    else
        tResult =
            StandardTestManagerWFRP1E.performBaseTest(
                nodeChar,
                sTestId
            )
    end

    return
        tResult
        and tResult.launched == true
end


function onInit()
    refreshSkillTooltip()
end
