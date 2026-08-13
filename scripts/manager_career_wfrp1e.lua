--[[
    WFRP1E
    Career manager

    Owns rules and data-shape operations related to WFRP 1e Careers.

    Checkpoint #8A implements only the Career Advance Scheme contract.

    Advance Scheme representation:

        advanceScheme.<characteristic>.steps

    Examples:

        WS +20
            ws.steps = 2

        S +1
            s.steps = 1

        W +2
            w.steps = 2

        I +10
            i.steps = 1

        No advance
            steps = 0

    The stored value is always the number of advancement steps,
    never the formatted characteristic increase.

    This manager does not yet:
        - assign Careers to Characters
        - modify Character characteristic.career values
        - purchase advances
        - spend Experience
        - own Career UI
]]

function isValidAdvanceStepCount(nSteps)
    nSteps = tonumber(nSteps)

    if not nSteps then
        return false
    end

    if nSteps < 0 then
        return false
    end

    return nSteps == math.floor(nSteps)
end


function createAdvanceScheme(tSource)
    local tAdvanceScheme = {}

    for _, sCharacteristic
        in ipairs(
            DataCommonWFRP1E.getCharacteristics()
        )
    do
        local nSteps = 0

        if tSource then
            local tSourceCharacteristic =
                tSource[sCharacteristic]

            if tSourceCharacteristic ~= nil then
                if type(tSourceCharacteristic) ~= "table" then
                    return nil
                end

                if tSourceCharacteristic.steps ~= nil then
                    if not isValidAdvanceStepCount(
                        tSourceCharacteristic.steps
                    ) then
                        return nil
                    end

                    nSteps =
                        tonumber(
                            tSourceCharacteristic.steps
                        )
                end
            end
        end

        tAdvanceScheme[sCharacteristic] = {
            steps = nSteps
        }
    end

    return tAdvanceScheme
end


function getAdvanceSchemeSteps(
    tAdvanceScheme,
    sCharacteristic
)
    if not DataCommonWFRP1E.getCharacteristicDefinition(
        sCharacteristic
    ) then
        return nil
    end

    if type(tAdvanceScheme) ~= "table" then
        return nil
    end

    local tCharacteristic =
        tAdvanceScheme[sCharacteristic]

    if not tCharacteristic then
        return 0
    end

    if not isValidAdvanceStepCount(
        tCharacteristic.steps
    ) then
        return nil
    end

    return tonumber(
        tCharacteristic.steps
    )
end


function setAdvanceSchemeSteps(
    tAdvanceScheme,
    sCharacteristic,
    nSteps
)
    if not DataCommonWFRP1E.getCharacteristicDefinition(
        sCharacteristic
    ) then
        return false
    end

    if type(tAdvanceScheme) ~= "table" then
        return false
    end

    if not isValidAdvanceStepCount(nSteps) then
        return false
    end

    tAdvanceScheme[sCharacteristic] = {
        steps = tonumber(nSteps)
    }

    return true
end


function calculateAdvanceSchemeAmount(
    tAdvanceScheme,
    sCharacteristic
)
    local nSteps =
        getAdvanceSchemeSteps(
            tAdvanceScheme,
            sCharacteristic
        )

    if nSteps == nil then
        return nil
    end

    return CharacteristicManagerWFRP1E.calculateCareerAdvance(
        sCharacteristic,
        nSteps
    )
end