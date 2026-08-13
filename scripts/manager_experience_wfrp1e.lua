--[[
    WFRP1E
    Experience manager

    Owns WFRP 1e Experience Point calculations and validation.

    Persistent Character data will later use:

        experience.totalAwarded
        experience.spent

    Available Experience is derived:

        totalAwarded - spent

    This manager does not perform database writes.
]]

function isValidExperienceValue(nValue)
    nValue = tonumber(nValue)

    if not nValue then
        return false
    end

    if nValue < 0 then
        return false
    end

    return nValue == math.floor(nValue)
end


function isValidLedger(nTotalAwarded, nSpent)
    if not isValidExperienceValue(nTotalAwarded) then
        return false
    end

    if not isValidExperienceValue(nSpent) then
        return false
    end

    nTotalAwarded = tonumber(nTotalAwarded)
    nSpent = tonumber(nSpent)

    return nSpent <= nTotalAwarded
end


function calculateAvailable(nTotalAwarded, nSpent)
    if not isValidLedger(
        nTotalAwarded,
        nSpent
    ) then
        return nil
    end

    return
        tonumber(nTotalAwarded)
        - tonumber(nSpent)
end


function canSpend(
    nTotalAwarded,
    nSpent,
    nCost
)
    if not isValidLedger(
        nTotalAwarded,
        nSpent
    ) then
        return false
    end

    if not isValidExperienceValue(nCost) then
        return false
    end

    return calculateAvailable(
        nTotalAwarded,
        nSpent
    ) >= tonumber(nCost)
end