--[[
    WFRP1E
    Hide runtime-context resolver and roll execution

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

    #10V reuses the verified resolved target for percentile dice execution.
    The manager still stores nothing and does not clamp the resulting target.

    Still excluded:
        - no automatic Skill applicability or multi-Skill stacking
        - no persistent target/group data
        - no target clamp
]]

local ROLL_TYPE = "wfrp1e_hide_test"


function onInit()
    Comm.addKeyedEventHandler(
        "onDiceLanded",
        ROLL_TYPE,
        onHideDiceLanded
    )
end


function onClose()
    Comm.removeKeyedEventHandler(
        "onDiceLanded",
        ROLL_TYPE,
        onHideDiceLanded
    )
end


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


local function signedModifier(nModifier)
    nModifier = tonumber(nModifier) or 0

    if nModifier >= 0 then
        return "+" .. tostring(nModifier)
    end

    return tostring(nModifier)
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
        initiative = tResolved.initiative,
        cool = tResolved.cool,
        targetInitiative = tResolved.targetInitiative,
        baseTarget = tResolved.baseTarget,
        skillModifier = tResolved.skillModifier,
        skillMode = tResolved.skillMode,
        otherModifier = tResolved.otherModifier,
        target = tResolved.target
    }

    -- FGU d100 automatically supplies the companion d10. Pass only d100;
    -- explicitly adding d10 would reproduce the rejected #10I extra-die bug.
    Comm.throwDice(
        ROLL_TYPE,
        { "d100" },
        0,
        "[WFRP1E HIDE] hide vs "
            .. tostring(tResolved.target)
            .. "%",
        tRollData
    )

    tResolved.launched = true
    return tResolved
end


function onHideDiceLanded(draginfo)
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

    local sSkillLabel =
        DataSkillsWFRP1E.getDisplayLabel(
            tostring(tRollData.rulesId or "")
        )

    local sSkillMode = ""
    if tRollData.skillMode == "stationary" then
        sSkillMode = " (stationary)"
    elseif tRollData.skillMode == "cautiousMovement" then
        sSkillMode = " (cautious movement)"
    end

    local sText =
        "[WFRP1E HIDE] "
        .. tostring(tRollData.characterName or "Character")
        .. " | Roll "
        .. tostring(nRoll)
        .. " | Base "
        .. tostring(tRollData.baseTarget or 0)
        .. "% (I "
        .. tostring(tRollData.initiative or 0)
        .. "% + Cl "
        .. tostring(tRollData.cool or 0)
        .. "% - Target I "
        .. tostring(tRollData.targetInitiative or 0)
        .. "%) | Skill "
        .. sSkillLabel
        .. " "
        .. signedModifier(tRollData.skillModifier)
        .. "%"
        .. sSkillMode
        .. " | Other "
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
