--[[
    WFRP1E
    Standard Test manager

    #10H resolves only the audited BASE target that can be derived from
    Character data without situational inputs.

    #10I adds one deliberately narrow executable path:
        - roll a plain D100 against an already-resolved BASE target;
        - success when roll <= target;
        - report roll, target and success/failure to chat.

    Deliberate exclusions:
        - no Skill applicability decision
        - no Skill modifier application
        - no repeated-acquisition modifier application
        - no situational modifiers
        - no generic formula parser
        - no target/noise/lock-difficulty resolution
        - no test-selection dialog
        - no margins/degrees/opposed tests/effects

    Supported locally resolvable bases:
        characteristic     direct current characteristic value
        s * 10             current Strength multiplied by 10
        t * 10             current Toughness multiplied by 10
        50                 fixed base 50

    Context-dependent formulas return a structured context-required result.
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


function resolveBaseTarget(nodeChar, sTestId)
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

    return {
        success = false,
        valid = false,
        testId = tDefinition.id,
        reason = "context-required",
        formula = tDefinition.formula,
        defaultModifier = tonumber(tDefinition.defaultModifier) or 0
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


function performBaseTest(nodeChar, sTestId)
    local tResolved =
        resolveBaseTarget(
            nodeChar,
            sTestId
        )

    if not tResolved.valid then
        return tResolved
    end

    local tRollData = {
        testId = tResolved.testId,
        target = tResolved.baseTarget,
        characterName = getCharacterDisplayName(nodeChar)
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
        baseTarget = tResolved.baseTarget
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
