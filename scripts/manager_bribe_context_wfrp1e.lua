--[[
    WFRP1E
    Bribe runtime-context preview resolver

    #10P is deliberately non-rolling. It resolves the audited Bribe procedure
    inputs independently before dice execution is added later.

    Rule boundary used here:
        base chance = 100 - target WP
        Bribery Skill = audited selected-Skill modifier (+20%)
        alignment modifier = one of -20, -10, 0, +10, +20
        each extra 50% of the ORIGINAL minimum bribe = +10%
        other GM/circumstance modifier = explicit runtime input

    The GM remains responsible for establishing the minimum acceptable bribe.
    This manager stores nothing and does not clamp the resulting target.
]]

local function failure(sReason)
    return {
        success = false,
        valid = false,
        reason = sReason
    }
end


local function isAllowedAlignmentModifier(nModifier)
    return nModifier == -20
        or nModifier == -10
        or nModifier == 0
        or nModifier == 10
        or nModifier == 20
end


function resolvePreview(nodeChar, sRulesId, tContext)
    if not nodeChar then
        return failure("no-character")
    end

    tContext = tContext or {}

    local nTargetWP = tonumber(tContext.targetWP)
    if nTargetWP == nil
        or nTargetWP < 0
        or nTargetWP > 100
    then
        return failure("invalid-target-wp")
    end

    local nAlignmentModifier =
        tonumber(tContext.alignmentModifier) or 0

    if not isAllowedAlignmentModifier(nAlignmentModifier) then
        return failure("invalid-alignment-modifier")
    end

    local nOfferIncrements =
        tonumber(tContext.offerIncrements) or 0

    if nOfferIncrements < 0
        or nOfferIncrements % 1 ~= 0
    then
        return failure("invalid-offer-increments")
    end

    local nOtherModifier =
        tonumber(tContext.otherModifier) or 0

    local tSkill =
        StandardTestManagerWFRP1E.resolveSelectedSkillModifier(
            nodeChar,
            sRulesId,
            "bribe"
        )

    if not tSkill.valid then
        return {
            success = false,
            valid = false,
            reason = "selected-skill-modifier-unresolved",
            skillReason = tSkill.reason
        }
    end

    local nBaseTarget = 100 - nTargetWP
    local nSkillModifier = tonumber(tSkill.modifier) or 0
    local nOfferModifier = nOfferIncrements * 10

    return {
        success = true,
        valid = true,
        testId = "bribe",
        rulesId = tostring(sRulesId or ""),
        targetWP = nTargetWP,
        baseTarget = nBaseTarget,
        skillModifier = nSkillModifier,
        alignmentModifier = nAlignmentModifier,
        offerIncrements = nOfferIncrements,
        offerModifier = nOfferModifier,
        otherModifier = nOtherModifier,
        target = nBaseTarget
            + nSkillModifier
            + nAlignmentModifier
            + nOfferModifier
            + nOtherModifier
    }
end
