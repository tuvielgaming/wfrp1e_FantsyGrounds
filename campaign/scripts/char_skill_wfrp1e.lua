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

    #10I adds the narrow Ctrl+Double-click roll launcher for an unambiguous,
    locally resolvable named Standard Test.

    #10J diagnoses what this explicitly selected owned Skill contributes when
    that effect is a context-free fixed modifier or a verified repeated-
    acquisition modifier.

    #10K feeds that already-verified selected Skill modifier into the roll
    target. The clicked owned Skill is the explicit applicability choice.

    #10L adds explicit named Standard Test selection when the selected Skill
    has more than one candidate test. Ctrl+Double-click opens a transient,
    non-persistent selector containing only tests whose #10K selected-Skill
    target already resolves locally. Selecting one uses the same #10K roll
    path; no new test mechanics are introduced here.
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


local function getLocallyRollableSelectedTests(
    nodeChar,
    sRulesId,
    aPotentialTests
)
    local aRollable = {}

    for _, sTestId in ipairs(aPotentialTests or {}) do
        local tTarget =
            StandardTestManagerWFRP1E.resolveSelectedSkillTarget(
                nodeChar,
                sRulesId,
                sTestId
            )

        if tTarget.valid then
            table.insert(
                aRollable,
                {
                    testId = sTestId,
                    target = tTarget.target
                }
            )
        end
    end

    return aRollable
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


local function addRollActionDiagnostic(
    nodeChar,
    sRulesId,
    aPotentialTests,
    aLines
)
    if #aPotentialTests == 1 then
        local sRollTestId, tBaseTarget =
            getUnambiguousBaseTest(
                nodeChar,
                sRulesId
            )

        if not sRollTestId or not tBaseTarget then
            return
        end

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

        return
    end

    if #aPotentialTests < 2 then
        return
    end

    local aRollable =
        getLocallyRollableSelectedTests(
            nodeChar,
            sRulesId,
            aPotentialTests
        )

    if #aRollable == 0 then
        return
    end

    local aChoices = {}

    for _, tChoice in ipairs(aRollable) do
        table.insert(
            aChoices,
            tChoice.testId
                .. " "
                .. tostring(tChoice.target)
                .. "%"
        )
    end

    table.insert(
        aLines,
        "Ctrl+Double-click: Choose Standard Test: "
        .. table.concat(
            aChoices,
            ", "
        )
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

        addRollActionDiagnostic(
            nodeChar,
            sRulesId,
            aPotentialTests,
            aLines
        )
    end

    name.setTooltipText(
        table.concat(
            aLines,
            "\n"
        )
    )
end


local function launchUnambiguousTest(
    nodeChar,
    sRulesId
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


local function openAmbiguousTestSelector(
    nodeChar,
    sRulesId,
    aPotentialTests
)
    local aRollable =
        getLocallyRollableSelectedTests(
            nodeChar,
            sRulesId,
            aPotentialTests
        )

    if #aRollable == 0 then
        return false
    end

    local wSelector =
        Interface.openWindow(
            "wfrp1e_standard_test_selector",
            ""
        )

    if not wSelector
        or not wSelector.setContext
    then
        return false
    end

    local nCreated =
        wSelector.setContext(
            nodeChar,
            sRulesId,
            aPotentialTests
        )

    if not nCreated
        or nCreated < 1
    then
        wSelector.close()
        return false
    end

    return true
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

    local aPotentialTests =
        DataStandardTestsWFRP1E.getPotentialStandardTestsForSkill(
            sRulesId
        )

    if #aPotentialTests == 1 then
        return launchUnambiguousTest(
            nodeChar,
            sRulesId
        )
    end

    if #aPotentialTests > 1 then
        return openAmbiguousTestSelector(
            nodeChar,
            sRulesId,
            aPotentialTests
        )
    end

    return false
end


function onInit()
    refreshSkillTooltip()
end