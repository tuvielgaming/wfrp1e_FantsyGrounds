--[[
    WFRP1E
    Campaign Skill Rules ID selector controller

    The Skill record persists only `rulesId`. The visible control is an
    unbound button whose label is derived from DataSkillsWFRP1E, allowing later
    localization without changing the stable mechanical ID.
]]

local sRulesIdPath = nil

local function getSkillNode()
    return getDatabaseNode()
end

function refreshRulesIdDisplay()
    local nodeSkill = getSkillNode()

    if not nodeSkill then
        rules_id_selector.setText("", "", "")
        rules_id_selector.setTooltipText("")
        return
    end

    local sRulesId =
        DB.getValue(
            nodeSkill,
            "rulesId",
            ""
        )

    local sDisplay =
        DataSkillsWFRP1E.getDisplayText(
            sRulesId
        )
        .. "  v"

    rules_id_selector.setText(
        sDisplay,
        sDisplay,
        sDisplay
    )

    if sRulesId == "" then
        rules_id_selector.setTooltipText(
            DataSkillsWFRP1E.getDisplayLabel("")
        )
    else
        rules_id_selector.setTooltipText(
            "rulesId: " .. sRulesId
        )
    end
end

function openRulesIdSelector()
    local nodeSkill = getSkillNode()

    if not nodeSkill
        or DB.isReadOnly(nodeSkill)
    then
        return false
    end

    local wSelector =
        Interface.openWindow(
            "wfrp1e_skill_rules_id_selector",
            ""
        )

    if not wSelector
        or not wSelector.setContext
    then
        return false
    end

    local nCreated =
        wSelector.setContext(
            nodeSkill
        )

    if not nCreated
        or nCreated < 1
    then
        wSelector.close()
        return false
    end

    return true
end

function onInit()
    local nodeSkill = getSkillNode()

    if nodeSkill then
        sRulesIdPath =
            DB.getPath(
                nodeSkill,
                "rulesId"
            )

        DB.addHandler(
            sRulesIdPath,
            "onUpdate",
            refreshRulesIdDisplay
        )
    end

    refreshRulesIdDisplay()
end

function onClose()
    if not sRulesIdPath then
        return
    end

    DB.removeHandler(
        sRulesIdPath,
        "onUpdate",
        refreshRulesIdDisplay
    )

    sRulesIdPath = nil
end
