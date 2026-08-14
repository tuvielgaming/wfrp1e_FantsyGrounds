--[[
    WFRP1E
    Standard Test manager

    #10H resolves audited BASE targets.
    #10I adds the verified D100 roll lifecycle.
    #10J resolves one explicitly selected owned Skill modifier.
    #10K applies that selected Skill modifier to the executable target.
    #10L adds explicit named-test selection for ambiguous Skills without
    changing mechanics.

    #10M adds one audited runtime-context formula only:

        Pick Lock base = Dexterity - Lock Rating

    Lock Rating is supplied explicitly for one execution and is not persisted.
    The result is deliberately not clamped. No generic formula parser is added.

    Deliberate exclusions:
        - no automatic Skill applicability decision
        - no general situational/default modifier stack
        - no conditional/choice/derived/target-side Skill effects
        - no generic formula parser
        - no target/noise resolution
        - no persistent lock identity or Pick Lock failure counter
        - no margins/degrees/opposed tests/effects

    Supported locally resolvable bases:
        characteristic             direct current characteristic value
        s * 10                     current Strength multiplied by 10
        t * 10                     current Toughness multiplied by 10
        50                         fixed base 50
        dex - lockDifficulty       explicit Pick Lock runtime context

    Other context-dependent formulas still return a structured
    context-required result.
]]

local ROLL_TYPE = "wfrp1e_standard_test_base"


function onInit()
    Comm.addKeyedEventHandler(
        "onDiceLanded",
        ROLL_TYPE,
        onBaseTestDiceLanded
    )
end


function onClose()
    Comm.removeKeyedEventHandler(
        "onDiceLanded",
        ROLL_TYPE,
        onBaseTestDiceLanded
    )
end


local function failure(sReason, sTestId)
    return {
        success = false,
        valid = false,
        testId = tostring(sTestId or ""),
        reason = sReason
    }
end


local function normalizeId(sValue)
    return tostring(
        sValue or ""
    ):match(
        "^%s*(.-)%s*$"
    )
end


local function signedModifier(nModifier)
    nModifier = tonumber(nModifier) or 0

    if nModifier >= 0 then
        return "+" .. tostring(nModifier)
    end

    return tostring(nModifier)
end


local function getCurrentCharacteristic(nodeChar, sCharacteristic)
    if not nodeChar then
        return nil, "no-character"
    end

    if not DataCommonWFRP1E.getCharacteristicDefinition(sCharacteristic) then
        return nil, "unknown-characteristic"
    end

    local nodeCharacteristic =
        DB.getChild(
            nodeChar,
            "characteristics." .. sCharacteristic
        )

    if not nodeCharacteristic then
        return nil, "missing-characteristic"
    end

    local nInitial =
        DB.getValue(
            nodeCharacteristic,
            "initial",
            0
        )

    local nPurchased =
        DB.getValue(
            nodeCharacteristic,
            "purchased",
            0
        )

    local nCurrent =
        CharacteristicManagerWFRP1E.calculateCurrent(
            sCharacteristic,
            nInitial,
            nPurchased
        )

    if nCurrent == nil then
        return nil, "invalid-characteristic"
    end

    return nCurrent, nil
end


local function resolvedResult(
    sTestId,
    nBaseTarget,
    sSource,
    sCharacteristic,
    nDefaultModifier
)
    return {
        success = true,
        valid = true,
        testId = sTestId,
        baseTarget = nBaseTarget,
        source = sSource,
        characteristic = sCharacteristic,
        defaultModifier = tonumber(nDefaultModifier) or 0
    }
end


local function contextRequiredResult(tDefinition)
    return {
        success = false,
        valid = false,
        testId = tDefinition.id,
        reason = "context-required",
        formula = tDefinition.formula,
        defaultModifier = tonumber(tDefinition.defaultModifier) or 0
    }
end


function resolveBaseTarget(nodeChar, sTestId, tContext)
    if not nodeChar then
        return failure("no-character", sTestId)
    end

    local tDefinition =
        DataStandardTestsWFRP1E.getNamedStandardTestDefinition(
            sTestId
        )

    if not tDefinition then
        return failure("unknown-test", sTestId)
    end

    if tDefinition.characteristic then
        local nCurrent, sReason =
            getCurrentCharacteristic(
                nodeChar,
                tDefinition.characteristic
            )

        if nCurrent == nil then
            return failure(sReason, tDefinition.id)
        end

        return resolvedResult(
            tDefinition.id,
            nCurrent,
            "characteristic",
            tDefinition.characteristic,
            tDefinition.defaultModifier
        )
    end

    if tDefinition.formula == "s * 10"
        or tDefinition.formula == "t * 10"
    then
        local sCharacteristic =
            string.sub(
                tDefinition.formula,
                1,
                1
            )

        local nCurrent, sReason =
            getCurrentCharacteristic(
                nodeChar,
                sCharacteristic
            )

        if nCurrent == nil then
            return failure(sReason, tDefinition.id)
        end

        return resolvedResult(
            tDefinition.id,
            nCurrent * 10,
            "non-percentage-characteristic",
            sCharacteristic,
            tDefinition.defaultModifier
        )
    end

    if tDefinition.formula == "50" then
        return resolvedResult(
            tDefinition.id,
            50,
            "fixed",
            nil,
            tDefinition.defaultModifier
        )
    end

    if tDefinition.formula == "dex - lockDifficulty" then
        local nLockDifficulty =
            tContext
            and tonumber(tContext.lockDifficulty)
            or nil

        if nLockDifficulty == nil then
            return contextRequiredResult(tDefinition)
        end

        if nLockDifficulty < 0
            or nLockDifficulty > 100
        then
            return {
                success = false,
                valid = false,
                testId = tDefinition.id,
                reason = "invalid-lock-rating",
                formula = tDefinition.formula,
                lockDifficulty = nLockDifficulty,
                defaultModifier = tonumber(tDefinition.defaultModifier) or 0
            }
        end

        local nDexterity, sReason =
            getCurrentCharacteristic(
                nodeChar,
                "dex"
            )

        if nDexterity == nil then
            return failure(sReason, tDefinition.id)
        end

        local tResult =
            resolvedResult(
                tDefinition.id,
                nDexterity - nLockDifficulty,
                "lock-difficulty",
                "dex",
                tDefinition.defaultModifier
            )

        tResult.characteristicValue = nDexterity
        tResult.lockDifficulty = nLockDifficulty

        return tResult
    end

    return contextRequiredResult(tDefinition)
end


function resolveSelectedSkillModifier(
    nodeChar,
    sRulesId,
    sTestId
)
    if not nodeChar then
        return {
            success = false,
            valid = false,
            reason = "no-character"
        }
    end

    local sSkill =
        normalizeId(
            sRulesId
        )

    local sTest =
        normalizeId(
            sTestId
        )

    if sSkill == "" then
        return {
            success = false,
            valid = false,
            reason = "missing-skill-rules-id"
        }
    end

    if sTest == "" then
        return {
            success = false,
            valid = false,
            reason = "missing-test-id"
        }
    end

    if not DataStandardTestsWFRP1E.isPotentialSkillForTest(
        sTest,
        sSkill
    ) then
        return {
            success = false,
            valid = false,
            rulesId = sSkill,
            testId = sTest,
            reason = "skill-not-candidate"
        }
    end

    local tEffect =
        DataStandardTestSkillEffectsWFRP1E.getEffect(
            sSkill,
            sTest
        )

    if not tEffect then
        return {
            success = false,
            valid = false,
            rulesId = sSkill,
            testId = sTest,
            reason = "no-audited-numeric-effect"
        }
    end

    if tEffect.type == "fixed" then
        return {
            success = true,
            valid = true,
            rulesId = sSkill,
            testId = sTest,
            effectType = "fixed",
            modifier = tonumber(tEffect.value) or 0
        }
    end

    if tEffect.type == "repeated-acquisition" then
        local nAcquisitions =
            CharacterSkillManagerWFRP1E.getAcquisitionCount(
                nodeChar,
                sSkill
            )

        if nAcquisitions < 1 then
            return {
                success = false,
                valid = false,
                rulesId = sSkill,
                testId = sTest,
                reason = "skill-not-owned"
            }
        end

        local nModifier =
            CharacterSkillManagerWFRP1E.getRepeatedAcquisitionModifier(
                nodeChar,
                sSkill
            )

        if nModifier == nil then
            return {
                success = false,
                valid = false,
                rulesId = sSkill,
                testId = sTest,
                reason = "missing-repeated-acquisition-rule"
            }
        end

        return {
            success = true,
            valid = true,
            rulesId = sSkill,
            testId = sTest,
            effectType = "repeated-acquisition",
            acquisitions = nAcquisitions,
            modifier = nModifier
        }
    end

    return {
        success = false,
        valid = false,
        rulesId = sSkill,
        testId = sTest,
        reason = "unsupported-skill-effect-type"
    }
end


function resolveSelectedSkillTarget(
    nodeChar,
    sRulesId,
    sTestId,
    tContext
)
    local tBase =
        resolveBaseTarget(
            nodeChar,
            sTestId,
            tContext
        )

    if not tBase.valid then
        return tBase
    end

    local tSkill =
        resolveSelectedSkillModifier(
            nodeChar,
            sRulesId,
            sTestId
        )

    if not tSkill.valid then
        return {
            success = false,
            valid = false,
            testId = tBase.testId,
            rulesId = normalizeId(sRulesId),
            baseTarget = tBase.baseTarget,
            reason = "selected-skill-modifier-unresolved",
            skillReason = tSkill.reason
        }
    end

    local nSkillModifier =
        tonumber(tSkill.modifier) or 0

    return {
        success = true,
        valid = true,
        testId = tBase.testId,
        rulesId = tSkill.rulesId,
        baseTarget = tBase.baseTarget,
        skillModifier = nSkillModifier,
        target = tBase.baseTarget + nSkillModifier,
        effectType = tSkill.effectType,
        acquisitions = tSkill.acquisitions,
        characteristic = tBase.characteristic,
        characteristicValue = tBase.characteristicValue,
        lockDifficulty = tBase.lockDifficulty
    }
end


local function getCharacterDisplayName(nodeChar)
    local sName =
        DB.getValue(
            nodeChar,
            "name",
            ""
        )

    if sName == "" then
        return "Character"
    end

    return sName
end


function performBaseTest(nodeChar, sTestId, tContext)
    local tResolved =
        resolveBaseTarget(
            nodeChar,
            sTestId,
            tContext
        )

    if not tResolved.valid then
        return tResolved
    end

    local tRollData = {
        testId = tResolved.testId,
        target = tResolved.baseTarget,
        characterName = getCharacterDisplayName(nodeChar),
        characteristicValue = tResolved.characteristicValue,
        lockDifficulty = tResolved.lockDifficulty
    }

    -- FGU treats d100 as its percentile tens die and automatically adds the
    -- companion d10. Supplying d10 explicitly would therefore create a third
    -- die and inflate the roll pool.
    Comm.throwDice(
        ROLL_TYPE,
        { "d100" },
        0,
        "[WFRP1E BASE TEST] "
            .. tResolved.testId
            .. " vs "
            .. tostring(tResolved.baseTarget)
            .. "%",
        tRollData
    )

    return {
        success = true,
        valid = true,
        launched = true,
        testId = tResolved.testId,
        baseTarget = tResolved.baseTarget,
        target = tResolved.baseTarget,
        characteristicValue = tResolved.characteristicValue,
        lockDifficulty = tResolved.lockDifficulty
    }
end


function performSelectedSkillTest(
    nodeChar,
    sRulesId,
    sTestId,
    tContext
)
    local tResolved =
        resolveSelectedSkillTarget(
            nodeChar,
            sRulesId,
            sTestId,
            tContext
        )

    if not tResolved.valid then
        return tResolved
    end

    local tRollData = {
        selectedSkill = true,
        testId = tResolved.testId,
        skillRulesId = tResolved.rulesId,
        baseTarget = tResolved.baseTarget,
        skillModifier = tResolved.skillModifier,
        target = tResolved.target,
        characterName = getCharacterDisplayName(nodeChar),
        characteristicValue = tResolved.characteristicValue,
        lockDifficulty = tResolved.lockDifficulty
    }

    Comm.throwDice(
        ROLL_TYPE,
        { "d100" },
        0,
        "[WFRP1E TEST] "
            .. tResolved.testId
            .. " vs "
            .. tostring(tResolved.target)
            .. "%",
        tRollData
    )

    return {
        success = true,
        valid = true,
        launched = true,
        testId = tResolved.testId,
        rulesId = tResolved.rulesId,
        baseTarget = tResolved.baseTarget,
        skillModifier = tResolved.skillModifier,
        target = tResolved.target,
        characteristicValue = tResolved.characteristicValue,
        lockDifficulty = tResolved.lockDifficulty
    }
end


function onBaseTestDiceLanded(draginfo)
    if not draginfo then
        return
    end

    local tRollData =
        draginfo.getCustomData()

    if type(tRollData) ~= "table" then
        return
    end

    local nTarget =
        tonumber(
            tRollData.target
        )

    if not nTarget then
        return
    end

    local tDiceData =
        draginfo.getDiceData()

    local nRoll =
        tDiceData
        and tonumber(tDiceData.total)
        or nil

    if not nRoll then
        return
    end

    local sTestId =
        tostring(
            tRollData.testId
            or "standardTest"
        )

    local sCharacterName =
        tostring(
            tRollData.characterName
            or "Character"
        )

    local bSuccess =
        nRoll <= nTarget

    local sOutcome =
        bSuccess
        and "SUCCESS"
        or "FAILURE"

    if tRollData.selectedSkill == true then
        local nBaseTarget =
            tonumber(tRollData.baseTarget)
            or nTarget

        local nSkillModifier =
            tonumber(tRollData.skillModifier)
            or 0

        local sSkillRulesId =
            tostring(
                tRollData.skillRulesId
                or "skill"
            )

        local sText =
            "[WFRP1E TEST] "
            .. sCharacterName
            .. " | "
            .. sTestId
            .. " | Roll "
            .. tostring(nRoll)

        local nLockDifficulty =
            tonumber(tRollData.lockDifficulty)

        local nCharacteristicValue =
            tonumber(tRollData.characteristicValue)

        if sTestId == "pickLock"
            and nLockDifficulty ~= nil
        then
            if nCharacteristicValue ~= nil then
                sText =
                    sText
                    .. " | Dex "
                    .. tostring(nCharacteristicValue)
                    .. "%"
            end

            sText =
                sText
                .. " | Lock Rating "
                .. tostring(nLockDifficulty)
                .. "%"
        end

        sText =
            sText
            .. " | Base "
            .. tostring(nBaseTarget)
            .. "% | Skill "
            .. sSkillRulesId
            .. " "
            .. signedModifier(nSkillModifier)
            .. "% | Target "
            .. tostring(nTarget)
            .. "% | "
            .. sOutcome

        if sTestId == "pickLock" then
            sText =
                sText
                .. " | Pick Lock procedure: one round/10 sec per attempt; after 3 failed attempts by this character on the same lock, further attempts automatically fail."
        end

        Comm.deliverChatMessage({
            text = sText,
            mode = "system",
            type = ROLL_TYPE
        })

        return
    end

    Comm.deliverChatMessage({
        text =
            "[WFRP1E BASE TEST] "
            .. sCharacterName
            .. " | "
            .. sTestId
            .. " | Roll "
            .. tostring(nRoll)
            .. " | Target "
            .. tostring(nTarget)
            .. "% | "
            .. sOutcome
            .. " | Skill modifiers not applied",
        mode = "system",
        type = ROLL_TYPE
    })
end
