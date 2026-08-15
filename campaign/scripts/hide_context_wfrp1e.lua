--[[
    WFRP1E
    Hide runtime-context preview dialog

    #10R previews only the Hide BASE target. All inputs are transient and no
    Character/Skill/Career/XP data is written.
]]

local nodeCharacter = nil


local function clearResult()
    result_line_1.setValue("")
    result_line_2.setValue("")
end


local function setResultMessage(sText)
    result_line_1.setValue(
        tostring(sText or "")
    )
    result_line_2.setValue("")
end


local function setCalculatedResult(tResult)
    result_line_1.setValue(
        "Current I "
        .. tostring(tResult.initiative)
        .. "% + Current Cl "
        .. tostring(tResult.cool)
        .. "% - Target I "
        .. tostring(tResult.targetInitiative)
        .. "%"
    )

    result_line_2.setValue(
        "BASE TARGET "
        .. tostring(tResult.baseTarget)
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


function setContext(nodeChar)
    nodeCharacter = nodeChar
    target_initiative.setValue(0)

    clearResult()
    setResultMessage(
        "Enter target Initiative and press CALCULATE. No dice will be rolled."
    )
end


function handleCalculate()
    if not nodeCharacter then
        return false
    end

    local tResult =
        HideContextManagerWFRP1E.resolvePreview(
            nodeCharacter,
            {
                targetInitiative = target_initiative.getValue()
            }
        )

    if not tResult.valid then
        setResultMessage(
            "Unable to resolve Hide preview: "
            .. tostring(tResult.reason or "invalid-context")
        )
        return false
    end

    setCalculatedResult(tResult)
    return true
end
