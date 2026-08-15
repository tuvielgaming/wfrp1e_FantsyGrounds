--[[
    WFRP1E
    Hide runtime-context preview resolver

    Mechanics authority: WFRP 1e Core Rulebook, Hide / Ukrywanie sie and the
    relevant Skill descriptions.

    Verified #10R BASE:
        Current Initiative + Current Cool - target Initiative

    Against a group, use the highest Initiative in that group; the GM supplies
    that value as runtime context.

    #10S adds ONE explicitly selected owned Skill effect:
        Shadowing                       +10%
        Concealment Rural / Urban       +20% stationary OR +5% cautious movement

    Rural/Urban applicability remains a GM decision. Another owned Hide-related
    Skill is never stacked automatically. A separate Other GM modifier remains
    explicit runtime context.

    Silent Move is deliberately NOT a Hide modifier here; its audited effects
    belong to Listen/Sneak procedures.

    Still excluded:
        - no automatic Skill applicability or multi-Skill stacking
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


local function normalizeId(sValue)
    return tostring(
        sValue or ""
    ):match(
        "^%s*(.-)%s*$"
    )
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


local function resolveSelectedHideSkillModifier(sRulesId, tContext)
    local sSkill = normalizeId(sRulesId)

    if sSkill == "" then
        return nil, "missing-skill-rules-id"
    end

    local tEffect =
        DataStandardTestSkillEffectsWFRP1E.getEffect(
            sSkill,
            "hide"
        )

    if not tEffect then
        return nil, "no-audited-hide-effect"
    end

    if tEffect.type == "fixed" then
        return {
            rulesId = sSkill,
            effectType = "fixed",
            modifier = tonumber(tEffect.value) or 0
        }, nil
    end

    if tEffect.type == "choice" then
        local sMode =
            normalizeId(
                tContext
                and tContext.skillMode
                or ""
            )

        local nModifier =
            tEffect.choices
            and tonumber(tEffect.choices[sMode])
            or nil

        if nModifier == nil then
            return nil, "hide-skill-choice-required"
        end

        return {
            rulesId = sSkill,
            effectType = "choice",
            mode = sMode,
            condition = tEffect.condition,
            modifier = nModifier
        }, nil
    end

    return nil, "unsupported-hide-effect-type"
end


function resolvePreview(nodeChar, sRulesId, tContext)
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

    local tSkill, sSkillReason =
        resolveSelectedHideSkillModifier(
            sRulesId,
            tContext
        )

    if not tSkill then
        return failure(sSkillReason)
    end

    local nOtherModifier =
        tonumber(tContext.otherModifier)
        or 0

    local nBaseTarget =
        nInitiative
        + nCool
        - nTargetInitiative

    return {
        success = true,
        valid = true,
        testId = "hide",
        rulesId = tSkill.rulesId,
        effectType = tSkill.effectType,
        skillMode = tSkill.mode,
        skillCondition = tSkill.condition,
        initiative = nInitiative,
        cool = nCool,
        targetInitiative = nTargetInitiative,
        baseTarget = nBaseTarget,
        skillModifier = tSkill.modifier,
        otherModifier = nOtherModifier,
        target = nBaseTarget
            + tSkill.modifier
            + nOtherModifier
    }
end
