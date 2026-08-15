--[[
    WFRP1E
    Bribe runtime-context resolver and roll execution

    #10P established and verified the Bribe calculation independently.
    #10Q reuses that exact resolved result for percentile dice execution.

    Rule boundary:
        base chance = 100 - target WP
        Bribery Skill = audited selected-Skill modifier (+20%)
        alignment modifier = one of -20, -10, 0, +10, +20
        each extra 50% of the ORIGINAL minimum bribe = +10%
        other GM/circumstance modifier = explicit runtime input

    The GM remains responsible for establishing the minimum acceptable bribe.
    This manager stores nothing and does not clamp the resulting target.
]]

local ROLL_TYPE = "wfrp1e_bribe_test"


function onInit()
    Comm.addKeyedEventHandler(
        "onDiceLanded",
        ROLL_TYPE,
        onBribeDiceLanded
    )
end


function onClose()
    Comm.removeKeyedEventHandler(
        "onDiceLanded",
        ROLL_TYPE,
        onBribeDiceLanded
    )
end


local function failure(sReason)
    return {
        success = false,
        valid = false,
        reason = sReason
    }
end


local function signedModifier(nModifier)
    nModifier = tonumber(nModifier) or 0

    if nModifier >= 0 then
        return "+" .. tostring(nModifier)
    end

    return tostring(nModifier)
end


local function isAllowedAlignmentModifier(nModifier)
    return nModifier == -20
        or nModifier == -10
        or nModifier == 0
        or nModifier == 10
        or nModifier == 20
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


function performTest(nodeChar, sRulesId, tContext)
    local tResolved =
        resolvePreview(
            nodeChar,
            sRulesId,
            tContext
        )

    if not tResolved.valid then
        return tResolved
    end

    local tRollData = {
        testId = tResolved.testId,
        rulesId = tResolved.rulesId,
        characterName = getCharacterDisplayName(nodeChar),
        targetWP = tResolved.targetWP,
        baseTarget = tResolved.baseTarget,
        skillModifier = tResolved.skillModifier,
        alignmentModifier = tResolved.alignmentModifier,
        offerModifier = tResolved.offerModifier,
        otherModifier = tResolved.otherModifier,
        target = tResolved.target
    }

    -- FGU d100 automatically supplies the companion d10. Pass only d100;
    -- explicitly adding d10 would reproduce the rejected #10I extra-die bug.
    Comm.throwDice(
        ROLL_TYPE,
        { "d100" },
        0,
        "[WFRP1E BRIBE] bribe vs "
            .. tostring(tResolved.target)
            .. "%",
        tRollData
    )

    tResolved.launched = true
    return tResolved
end


function onBribeDiceLanded(draginfo)
    if not draginfo then
        return
    end

    local tRollData =
        draginfo.getCustomData()

    if type(tRollData) ~= "table" then
        return
    end

    local nTarget = tonumber(tRollData.target)
    if nTarget == nil then
        return
    end

    local tDiceData =
        draginfo.getDiceData()

    local nRoll =
        tDiceData
        and tonumber(tDiceData.total)
        or nil

    if nRoll == nil then
        return
    end

    local sOutcome =
        nRoll <= nTarget
        and "SUCCESS"
        or "FAILURE"

    local sText =
        "[WFRP1E BRIBE] "
        .. tostring(tRollData.characterName or "Character")
        .. " | Roll "
        .. tostring(nRoll)
        .. " | Base "
        .. tostring(tRollData.baseTarget or 0)
        .. "% (100 - WP "
        .. tostring(tRollData.targetWP or 0)
        .. ") | Skill "
        .. tostring(tRollData.rulesId or "bribery")
        .. " "
        .. signedModifier(tRollData.skillModifier)
        .. "% | Alignment "
        .. signedModifier(tRollData.alignmentModifier)
        .. "% | Offer "
        .. signedModifier(tRollData.offerModifier)
        .. "% | Other "
        .. signedModifier(tRollData.otherModifier)
        .. "% | Target "
        .. tostring(nTarget)
        .. "% | "
        .. sOutcome

    Comm.deliverChatMessage({
        text = sText,
        mode = "system",
        type = ROLL_TYPE
    })
end
