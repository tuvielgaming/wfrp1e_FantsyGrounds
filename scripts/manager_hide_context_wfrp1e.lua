--[[
    WFRP1E
    Hide runtime-context preview resolver

    Mechanics authority: WFRP 1e Core Rulebook, Hide / Ukrywanie sie.

    #10R resolves only the audited BASE chance:
        Current Initiative + Current Cool - target Initiative

    Against a group, the rule uses the highest Initiative in that group; the GM
    supplies that value as runtime context.

    Deliberate exclusions for this checkpoint:
        - no Silent Move +10 procedure modifier
        - no Concealment up-to-+20 procedure modifier
        - no other GM/situational modifiers
        - no dice roll
        - no persistent target/group data
        - no target clamp
]]

local function failure(sReason)
    return {
        success = false,
        valid = false,
        reason = sReason
    }
end


local function getCurrentCharacteristic(nodeChar, sCharacteristic)
    if not nodeChar then
        return nil
    end

    local nodeCharacteristic =
        DB.getChild(
            nodeChar,
            "characteristics." .. tostring(sCharacteristic or "")
        )

    if not nodeCharacteristic then
        return nil
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

    return
        CharacteristicManagerWFRP1E.calculateCurrent(
            sCharacteristic,
            nInitial,
            nPurchased
        )
end


function resolvePreview(nodeChar, tContext)
    if not nodeChar then
        return failure("no-character")
    end

    tContext = tContext or {}

    local nTargetInitiative =
        tonumber(tContext.targetInitiative)

    if nTargetInitiative == nil then
        return failure("invalid-target-initiative")
    end

    local nInitiative =
        getCurrentCharacteristic(
            nodeChar,
            "i"
        )

    local nCool =
        getCurrentCharacteristic(
            nodeChar,
            "cl"
        )

    if nInitiative == nil or nCool == nil then
        return failure("characteristic-unresolved")
    end

    return {
        success = true,
        valid = true,
        testId = "hide",
        initiative = nInitiative,
        cool = nCool,
        targetInitiative = nTargetInitiative,
        baseTarget = nInitiative + nCool - nTargetInitiative
    }
end
