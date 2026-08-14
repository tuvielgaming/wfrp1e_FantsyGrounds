--[[
    WFRP1E
    Standard Test base-target resolver

    Resolves only the audited base target that can be derived from Character
    data without situational inputs.

    Deliberate exclusions for this checkpoint:
        - no Skill applicability decision
        - no Skill modifier application
        - no generic formula parser
        - no target/noise/lock-difficulty resolution
        - no dice rolling

    Supported bases:
        characteristic     direct current characteristic value
        s * 10             current Strength multiplied by 10
        t * 10             current Toughness multiplied by 10
        50                 fixed base 50

    Context-dependent formulas return a structured context-required result.
]]

local function failure(sReason, sTestId)
    return {
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
        valid = false,
        testId = tDefinition.id,
        reason = "context-required",
        formula = tDefinition.formula,
        defaultModifier = tonumber(tDefinition.defaultModifier) or 0
    }
end
