--[[
    WFRP1E
    Hide runtime-context preview dialog

    #10R verified the BASE formula.
    #10S adds one explicitly selected owned Hide Skill effect and a separate
    Other GM modifier. All data remains transient and no dice are rolled.
]]

local nodeCharacter = nil
local sSelectedSkillRulesId = ""
local sSkillMode = ""


local function signedModifier(nModifier)
    nModifier = tonumber(nModifier) or 0

    if nModifier >= 0 then
        return "+" .. tostring(nModifier)
    end

    return tostring(nModifier)
end


local function isConcealmentSkill()
    return
        sSelectedSkillRulesId == "concealmentRural"
        or sSelectedSkillRulesId == "concealmentUrban"
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


local function refreshSkillControls()
    local sLabel =
        DataSkillsWFRP1E.getDisplayLabel(
            sSelectedSkillRulesId
        )

    if isConcealmentSkill() then
        selected_skill_value.setValue(
            sLabel .. " — choose movement state below"
        )
        concealment_mode_label.setVisible(true)
        stationary_choice.setVisible(true)
        cautious_choice.setVisible(true)

        stationary_choice.setValue(
            (sSkillMode == "stationary" and "> " or "")
            .. "Stationary  +20%"
        )

        cautious_choice.setValue(
            (sSkillMode == "cautiousMovement" and "> " or "")
            .. "Cautious movement  +5%"
        )
    else
        selected_skill_value.setValue(
            sLabel .. "  +10%"
        )
        concealment_mode_label.setVisible(false)
        stationary_choice.setVisible(false)
        cautious_choice.setVisible(false)
    end
end


local function setCalculatedResult(tResult)
    result_line_1.setValue(
        "Base "
        .. tostring(tResult.baseTarget)
        .. "% = I "
        .. tostring(tResult.initiative)
        .. "% + Cl "
        .. tostring(tResult.cool)
        .. "% - Target I "
        .. tostring(tResult.targetInitiative)
        .. "%"
    )

    local sSkillText =
        DataSkillsWFRP1E.getDisplayLabel(
            tResult.rulesId
        )
        .. " "
        .. signedModifier(tResult.skillModifier)
        .. "%"

    if tResult.skillMode == "stationary" then
        sSkillText = sSkillText .. " (stationary)"
    elseif tResult.skillMode == "cautiousMovement" then
        sSkillText = sSkillText .. " (cautious movement)"
    end

    result_line_2.setValue(
        "Selected Skill "
        .. sSkillText
        .. " | Other "
        .. signedModifier(tResult.otherModifier)
        .. "%"
    )

    result_line_3.setValue(
        "FINAL TARGET "
        .. tostring(tResult.target)
        .. "%"
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
    sSkillMode = ""

    target_initiative.setValue(0)
    other_modifier.setValue(0)

    refreshSkillControls()
    clearResult()
    setResultMessage(
        "Enter target Initiative, choose any required Skill state, then press CALCULATE. No dice will be rolled."
    )
end


function setSkillMode(sMode)
    if not isConcealmentSkill() then
        return false
    end

    if sMode ~= "stationary"
        and sMode ~= "cautiousMovement"
    then
        return false
    end

    sSkillMode = sMode
    refreshSkillControls()
    clearResult()
    return true
end


function handleCalculate()
    if not nodeCharacter then
        return false
    end

    local tResult =
        HideContextManagerWFRP1E.resolvePreview(
            nodeCharacter,
            sSelectedSkillRulesId,
            {
                targetInitiative = target_initiative.getValue(),
                skillMode = sSkillMode,
                otherModifier = other_modifier.getValue()
            }
        )

    if not tResult.valid then
        if tResult.reason == "hide-skill-choice-required" then
            setResultMessage(
                "Choose Stationary +20% or Cautious movement +5% for the selected Concealment Skill."
            )
        else
            setResultMessage(
                "Unable to resolve Hide preview: "
                .. tostring(tResult.reason or "invalid-context")
            )
        end

        return false
    end

    setCalculatedResult(tResult)
    return true
end
