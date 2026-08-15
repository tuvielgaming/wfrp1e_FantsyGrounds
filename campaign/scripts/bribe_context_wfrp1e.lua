--[[
    WFRP1E
    Bribe runtime-context dialog

    #10P verified preview calculation and validation.
    #10Q keeps that preview and adds explicit roll execution from the same
    transient inputs. No Character/Skill/Career/XP data is written.
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


local function clearResult()
    result_line_1.setValue("")
    result_line_2.setValue("")
    result_line_3.setValue("")
end


local function setResultMessage(sText)
    result_line_1.setValue(
        tostring(sText or "")
    )
    result_line_2.setValue("")
    result_line_3.setValue("")
end


local function setCalculatedResult(tResult)
    result_line_1.setValue(
        "Base "
        .. tostring(tResult.baseTarget)
        .. "% (100 - WP "
        .. tostring(tResult.targetWP)
        .. ") | Skill "
        .. signedModifier(tResult.skillModifier)
        .. "%"
    )

    result_line_2.setValue(
        "Alignment "
        .. signedModifier(tResult.alignmentModifier)
        .. "% | Offer "
        .. signedModifier(tResult.offerModifier)
        .. "% | Other "
        .. signedModifier(tResult.otherModifier)
        .. "%"
    )

    result_line_3.setValue(
        "FINAL TARGET "
        .. tostring(tResult.target)
        .. "%"
    )
end


local function getContext()
    return {
        targetWP = target_wp.getValue(),
        alignmentModifier = alignment_modifier.getValue(),
        offerIncrements = offer_increments.getValue(),
        otherModifier = other_modifier.getValue()
    }
end


local function showResolutionError(tResult)
    local sReason =
        tostring(
            tResult
            and tResult.reason
            or "invalid-context"
        )

    if sReason == "invalid-target-wp" then
        setResultMessage("Target WP must be between 0% and 100%.")
    elseif sReason == "invalid-alignment-modifier" then
        setResultMessage("Alignment modifier must be -20, -10, 0, +10 or +20%.")
    elseif sReason == "invalid-offer-increments" then
        setResultMessage("Extra 50% steps must be a whole number of 0 or more.")
    else
        setResultMessage("Unable to resolve Bribe test: " .. sReason)
    end
end


function onInit()
    calculate_button.setText(
        "CALCULATE",
        "CALCULATE",
        "CALCULATE"
    )

    roll_button.setText(
        "ROLL",
        "ROLL",
        "ROLL"
    )
end


function setContext(nodeChar, sRulesId)
    nodeCharacter = nodeChar
    sSelectedSkillRulesId = tostring(sRulesId or "")

    target_wp.setValue(0)
    alignment_modifier.setValue(0)
    offer_increments.setValue(0)
    other_modifier.setValue(0)

    clearResult()
    setResultMessage(
        "Enter context. CALCULATE previews; ROLL executes the same target."
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
            getContext()
        )

    if not tResult.valid then
        showResolutionError(tResult)
        return false
    end

    setCalculatedResult(tResult)
    return true
end


function handleRoll()
    if not nodeCharacter then
        return false
    end

    local tResult =
        BribeContextManagerWFRP1E.performTest(
            nodeCharacter,
            sSelectedSkillRulesId,
            getContext()
        )

    if not tResult.valid
        or tResult.launched ~= true
    then
        showResolutionError(tResult)
        return false
    end

    setCalculatedResult(tResult)
    close()
    return true
end
