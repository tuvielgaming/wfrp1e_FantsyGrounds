--[[
    WFRP1E
    Character Experience manager

    Owns Fantasy Grounds database operations for a Character's
    Experience Point ledger.

    Persistent Character data:

        experience.totalAwarded
        experience.spent

    Derived:

        available =
            totalAwarded - spent

    The normal Character-sheet editor exposes Available Experience,
    not the two internal ledger values.

    Manually setting Available Experience preserves the ledger
    relationship by calculating:

        totalAwarded =
            spent + available
]]

function ensureExperience(nodeChar)
    if not nodeChar then
        return nil
    end

    local nodeExperience =
        DB.createChild(
            nodeChar,
            "experience"
        )

    if not nodeExperience then
        return nil
    end

    local nodeTotalAwarded =
        DB.createChild(
            nodeExperience,
            "totalAwarded",
            "number"
        )

    if not nodeTotalAwarded then
        return nil
    end

    local nodeSpent =
        DB.createChild(
            nodeExperience,
            "spent",
            "number"
        )

    if not nodeSpent then
        return nil
    end

    return nodeExperience
end


function getLedger(nodeChar)
    if not nodeChar then
        return nil
    end

    local nodeExperience =
        DB.getChild(
            nodeChar,
            "experience"
        )

    if not nodeExperience then
        return nil
    end

    local nTotalAwarded =
        DB.getValue(
            nodeExperience,
            "totalAwarded",
            0
        )

    local nSpent =
        DB.getValue(
            nodeExperience,
            "spent",
            0
        )

    if not ExperienceManagerWFRP1E.isValidLedger(
        nTotalAwarded,
        nSpent
    ) then
        return nil
    end

    return {
        totalAwarded =
            tonumber(nTotalAwarded),

        spent =
            tonumber(nSpent)
    }
end


function getAvailable(nodeChar)
    local tLedger =
        getLedger(
            nodeChar
        )

    if not tLedger then
        return nil
    end

    return ExperienceManagerWFRP1E.calculateAvailable(
        tLedger.totalAwarded,
        tLedger.spent
    )
end


function setAvailable(
    nodeChar,
    nAvailable
)
    if not nodeChar then
        return false
    end

    if not ExperienceManagerWFRP1E.isValidExperienceValue(
        nAvailable
    ) then
        return false
    end

    local nodeExperience =
        ensureExperience(
            nodeChar
        )

    if not nodeExperience then
        return false
    end

    local nSpent =
        DB.getValue(
            nodeExperience,
            "spent",
            0
        )

    if not ExperienceManagerWFRP1E.isValidExperienceValue(
        nSpent
    ) then
        return false
    end

    nAvailable =
        tonumber(nAvailable)

    nSpent =
        tonumber(nSpent)

    local nTotalAwarded =
        nSpent + nAvailable

    DB.setValue(
        nodeExperience,
        "totalAwarded",
        "number",
        nTotalAwarded
    )

    return true
end