--[[
    WFRP1E
    Character Experience display/controller

    Persistent Character data:

        experience.totalAwarded
        experience.spent

    Visible Character-sheet value:

        available

    Available Experience is not stored independently.

    When manually edited:

        totalAwarded =
            spent + available

    When advancement mechanics change spent:

        available =
            totalAwarded - spent

    The visible Available control is intentionally unbound.
]]

local sTotalAwardedPath = nil
local sSpentPath = nil

local bWritingAvailable = false
local bUpdatingControl = false


function onInit()
    local nodeExperience =
        getDatabaseNode()

    if not nodeExperience then
        print(
            "WFRP1E | ERROR: Experience window has no database node."
        )

        return
    end

    sTotalAwardedPath =
        DB.getPath(
            nodeExperience,
            "totalAwarded"
        )

    sSpentPath =
        DB.getPath(
            nodeExperience,
            "spent"
        )

    DB.addHandler(
        sTotalAwardedPath,
        "onUpdate",
        onExperienceSourceUpdated
    )

    DB.addHandler(
        sSpentPath,
        "onUpdate",
        onExperienceSourceUpdated
    )

    updateAvailableControl()
end


function onClose()
    if sTotalAwardedPath then
        DB.removeHandler(
            sTotalAwardedPath,
            "onUpdate",
            onExperienceSourceUpdated
        )
    end

    if sSpentPath then
        DB.removeHandler(
            sSpentPath,
            "onUpdate",
            onExperienceSourceUpdated
        )
    end
end


function onExperienceSourceUpdated()
    if bWritingAvailable then
        return
    end

    updateAvailableControl()
end


function onAvailableValueChanged()
    if bUpdatingControl then
        return
    end

    local nodeExperience =
        getDatabaseNode()

    if not nodeExperience then
        return
    end

    local nodeChar =
        DB.getParent(
            nodeExperience
        )

    if not nodeChar then
        return
    end

    local nAvailable =
        tonumber(
            available.getValue()
        )

    if not ExperienceManagerWFRP1E.isValidExperienceValue(
        nAvailable
    ) then
        updateAvailableControl()

        return
    end

    bWritingAvailable = true

    local bSuccess =
        CharacterExperienceManagerWFRP1E.setAvailable(
            nodeChar,
            nAvailable
        )

    bWritingAvailable = false

    if not bSuccess then
        updateAvailableControl()
    end
end


function updateAvailableControl()
    local nodeExperience =
        getDatabaseNode()

    if not nodeExperience then
        return
    end

    local nodeChar =
        DB.getParent(
            nodeExperience
        )

    if not nodeChar then
        return
    end

    local nAvailable =
        CharacterExperienceManagerWFRP1E.getAvailable(
            nodeChar
        )

    if nAvailable == nil then
        print(
            "WFRP1E | ERROR: Character has an invalid Experience ledger."
        )

        return
    end

    bUpdatingControl = true

    available.setValue(
        nAvailable
    )

    bUpdatingControl = false
end