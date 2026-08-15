--[[
    WFRP1E
    Bribe runtime-context preview dialog

    #10P calculates the final Bribe target only. It deliberately does not roll.
    All inputs are transient and no Character/Skill/Career/XP data is written.
]]

local nodeCharacter = nil
local sSelectedSkillRulesId = ""


local function signedModifier(nModifier)
    nModifier = tonumber(nModifier) or 0

    if nModifier >= 0 then
        return "+" .. tostring(nModifier)
    end

    return tostring(nModifier)
end


local function setResultText(sText)
    result_text.setValue(
        tostring(sText or "")
    )
end


function onInit()
    calculate_button.setText(
        "CALCULATE",
        "CALCULATE",
        "CALCULATE"
    )
end


function setContext(nodeChar, sRulesId)
    nodeCharacter = nodeChar
    sSelectedSkillRulesId = tostring(sRulesId or "")

    target_wp.setValue(0)
    alignment_modifier.setValue(0)
    offer_increments.setValue(0)
    other_modifier.setValue(0)

    setResultText(
        "Enter context and press CALCULATE. No dice will be rolled."
    )
end


function handleCalculate()
    if not nodeCharacter then
        return false
    end

    local tResult =
        BribeContextManagerWFRP1E.resolvePreview(
            nodeCharacter,
            sSelectedSkillRulesId,
            {
                targetWP = target_wp.getValue(),
                alignmentModifier = alignment_modifier.getValue(),
                offerIncrements = offer_increments.getValue(),
                otherModifier = other_modifier.getValue()
            }
        )

    if not tResult.valid then
        local sReason = tostring(tResult.reason or "invalid-context")

        if sReason == "invalid-target-wp" then
            setResultText("Target WP must be between 0% and 100%.")
        elseif sReason == "invalid-alignment-modifier" then
            setResultText("Alignment modifier must be -20, -10, 0, +10 or +20%.")
        elseif sReason == "invalid-offer-increments" then
            setResultText("Extra 50% steps must be a whole number of 0 or more.")
        else
            setResultText("Unable to resolve Bribe preview: " .. sReason)
        end

        return false
    end

    setResultText(
        "Base "
        .. tostring(tResult.baseTarget)
        .. "% (100 - WP "
        .. tostring(tResult.targetWP)
        .. ") | Skill "
        .. signedModifier(tResult.skillModifier)
        .. "% | Alignment "
        .. signedModifier(tResult.alignmentModifier)
        .. "% | Offer "
        .. signedModifier(tResult.offerModifier)
        .. "% | Other "
        .. signedModifier(tResult.otherModifier)
        .. "% | FINAL TARGET "
        .. tostring(tResult.target)
        .. "%"
    )

    return true
end
