--[[
    WFRP1E
    Transient Skill Rules ID selector

    The selector is unbound. Its choice rows are also unbound and therefore do
    not create campaign records. Selecting one row writes only the stable
    `rulesId` string to the source Skill record.
]]

local nodeSkill = nil
local sCurrentRulesId = ""

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

    return true
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
