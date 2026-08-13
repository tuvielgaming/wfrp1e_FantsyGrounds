--[[
    WFRP1E
    Characteristic manager

    Owns rules and calculations related to WFRP 1e characteristics.

    This manager does not own Character database state or UI presentation.

    Advancement semantics:

    - purchased is the total number of advances already acquired.
    - career is the number of advances permitted by the active
      Career's Advance Scheme.
    - purchased may legitimately be greater than career after
      changing Careers.
    - another advance may be purchased only when purchased < career.
    - one characteristic advance costs 100 Experience Points.
]]

local CHARACTERISTIC_ADVANCE_EXPERIENCE_COST = 100


function getAdvanceExperienceCost()
    return CHARACTERISTIC_ADVANCE_EXPERIENCE_COST
end


function isValidAdvanceCount(nValue)
    nValue = tonumber(nValue)

    if not nValue then
        return false
    end

    if nValue < 0 then
        return false
    end

    return nValue == math.floor(nValue)
end


function calculateCurrent(
    sCharacteristic,
    nInitial,
    nPurchased
)
    local nAdvanceStep =
        DataCommonWFRP1E.getAdvanceStep(
            sCharacteristic
        )

    if not nAdvanceStep then
        return nil
    end

    nInitial = tonumber(nInitial) or 0
    nPurchased = tonumber(nPurchased) or 0

    return
        nInitial
        + (nPurchased * nAdvanceStep)
end


function calculateCareerAdvance(
    sCharacteristic,
    nCareer
)
    local nAdvanceStep =
        DataCommonWFRP1E.getAdvanceStep(
            sCharacteristic
        )

    if not nAdvanceStep then
        return nil
    end

    nCareer = tonumber(nCareer) or 0

    return nCareer * nAdvanceStep
end


function canPurchaseAdvance(
    sCharacteristic,
    nPurchased,
    nCareer
)
    if not DataCommonWFRP1E.getCharacteristicDefinition(
        sCharacteristic
    ) then
        return false
    end

    if not isValidAdvanceCount(
        nPurchased
    ) then
        return false
    end

    if not isValidAdvanceCount(
        nCareer
    ) then
        return false
    end

    nPurchased = tonumber(nPurchased)
    nCareer = tonumber(nCareer)

    return nPurchased < nCareer
end