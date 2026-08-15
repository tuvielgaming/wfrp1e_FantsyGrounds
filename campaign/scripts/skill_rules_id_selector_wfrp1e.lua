--[[
    WFRP1E
    Transient Skill Rules ID selector

    The selector is unbound. Its choice rows are also unbound and therefore do
    not create campaign records. Selecting one row writes only the stable
    `rulesId` string to the source Skill record.

    UX:
        - search remains transient and never touches the Skill record;
        - typing scrolls the list to the first matching localized label or ID;
        - search is focused automatically when the selector opens.
]]

local nodeSkill = nil
local sCurrentRulesId = ""

local aChoiceWindows = {}
local aChoiceSearchText = {}
local wCurrentChoice = nil

local function normalizeSearchText(sValue)
    return string.lower(
        tostring(sValue or "")
    )
end

local function scrollToChoice(wChoice)
    if not wChoice
        or not wChoice.choice
    then
        return false
    end

    choices.scrollToWindow(
        wChoice,
        wChoice.choice,
        true
    )

    return true
end

local function createChoice(
    sRulesId,
    sDisplay
)
    local wChoice =
        choices.createWindow(nil)

    if not wChoice
        or not wChoice.setChoice
    then
        return false
    end

    wChoice.setChoice(
        sRulesId,
        sDisplay
    )

    local nIndex = #aChoiceWindows + 1

    aChoiceWindows[nIndex] = wChoice
    aChoiceSearchText[nIndex] =
        normalizeSearchText(
            tostring(sDisplay or "")
            .. " "
            .. tostring(sRulesId or "")
        )

    if tostring(sRulesId or "") == sCurrentRulesId then
        wCurrentChoice = wChoice
    end

    return true
end

function scrollToSearchMatch(sSearch)
    local sNeedle =
        normalizeSearchText(sSearch):match(
            "^%s*(.-)%s*$"
        )

    if sNeedle == "" then
        return scrollToChoice(
            wCurrentChoice
            or aChoiceWindows[1]
        )
    end

    for nIndex = 1, #aChoiceWindows do
        local sSearchText =
            aChoiceSearchText[nIndex]
            or ""

        if string.find(
            sSearchText,
            sNeedle,
            1,
            true
        ) then
            return scrollToChoice(
                aChoiceWindows[nIndex]
            )
        end
    end

    return false
end

function setContext(nodeSourceSkill)
    nodeSkill = nodeSourceSkill

    if not nodeSkill then
        return 0
    end

    sCurrentRulesId =
        DB.getValue(
            nodeSkill,
            "rulesId",
            ""
        )

    choices.closeAll()

    aChoiceWindows = {}
    aChoiceSearchText = {}
    wCurrentChoice = nil

    local nCreated = 0

    local sUnlinked =
        DataSkillsWFRP1E.getDisplayText("")

    if sCurrentRulesId == "" then
        sUnlinked = "> " .. sUnlinked
    end

    if createChoice("", sUnlinked) then
        nCreated = nCreated + 1
    end

    local aDefinitions =
        DataSkillsWFRP1E.getDefinitions()

    for nIndex = 1, #aDefinitions do
        local tDefinition = aDefinitions[nIndex]

        local sDisplay =
            DataSkillsWFRP1E.getDisplayText(
                tDefinition.id
            )

        if tDefinition.id == sCurrentRulesId then
            sDisplay = "> " .. sDisplay
        end

        if createChoice(
            tDefinition.id,
            sDisplay
        ) then
            nCreated = nCreated + 1
        end
    end

    search.setValue("")

    scrollToSearchMatch("")
    search.setFocus()

    return nCreated
end

function applyRulesId(sRulesId)
    if not nodeSkill
        or DB.isReadOnly(nodeSkill)
    then
        return false
    end

    DB.setValue(
        nodeSkill,
        "rulesId",
        "string",
        tostring(sRulesId or "")
    )

    close()
    return true
end
