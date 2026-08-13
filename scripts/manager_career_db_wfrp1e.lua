--[[
    WFRP1E
    Career database manager

    Owns persistence operations for Career records.

    Career rules remain in CareerManagerWFRP1E.

    Persistent Advance Scheme structure:

        advancescheme.<characteristic>.steps

    Example:

        advancescheme.ws.steps = 2

    means:

        WS +20

    because WS has an advancement step of 10.
]]

function ensureAdvanceScheme(nodeCareer)
    if not nodeCareer then
        return false
    end

    local nodeAdvanceScheme =
        DB.createChild(
            nodeCareer,
            "advancescheme"
        )

    if not nodeAdvanceScheme then
        return false
    end

    for _, sCharacteristic
        in ipairs(
            DataCommonWFRP1E.getCharacteristics()
        )
    do
        local nodeCharacteristic =
            DB.createChild(
                nodeAdvanceScheme,
                sCharacteristic
            )

        if not nodeCharacteristic then
            return false
        end

        local nodeSteps =
            DB.createChild(
                nodeCharacteristic,
                "steps",
                "number"
            )

        if not nodeSteps then
            return false
        end
    end

    return true
end


function getAdvanceSchemeCharacteristicNode(
    nodeCareer,
    sCharacteristic,
    bCreate
)
    if not nodeCareer then
        return nil
    end

    if not DataCommonWFRP1E.getCharacteristicDefinition(
        sCharacteristic
    ) then
        return nil
    end

    if bCreate then
        if not ensureAdvanceScheme(nodeCareer) then
            return nil
        end
    end

    local nodeAdvanceScheme =
        DB.getChild(
            nodeCareer,
            "advancescheme"
        )

    if not nodeAdvanceScheme then
        return nil
    end

    return DB.getChild(
        nodeAdvanceScheme,
        sCharacteristic
    )
end


function getAdvanceSchemeSteps(
    nodeCareer,
    sCharacteristic
)
    local nodeCharacteristic =
        getAdvanceSchemeCharacteristicNode(
            nodeCareer,
            sCharacteristic,
            false
        )

    if not nodeCharacteristic then
        return 0
    end

    local nSteps =
        DB.getValue(
            nodeCharacteristic,
            "steps",
            0
        )

    if not CareerManagerWFRP1E.isValidAdvanceStepCount(
        nSteps
    ) then
        return nil
    end

    return tonumber(nSteps)
end


function setAdvanceSchemeSteps(
    nodeCareer,
    sCharacteristic,
    nSteps
)
    if not CareerManagerWFRP1E.isValidAdvanceStepCount(
        nSteps
    ) then
        return false
    end

    local nodeCharacteristic =
        getAdvanceSchemeCharacteristicNode(
            nodeCareer,
            sCharacteristic,
            true
        )

    if not nodeCharacteristic then
        return false
    end

    DB.setValue(
        nodeCharacteristic,
        "steps",
        "number",
        tonumber(nSteps)
    )

    return true
end


function readAdvanceScheme(nodeCareer)
    if not nodeCareer then
        return nil
    end

    local tSource = {}

    for _, sCharacteristic
        in ipairs(
            DataCommonWFRP1E.getCharacteristics()
        )
    do
        local nSteps =
            getAdvanceSchemeSteps(
                nodeCareer,
                sCharacteristic
            )

        if nSteps == nil then
            return nil
        end

        tSource[sCharacteristic] = {
            steps = nSteps
        }
    end

    return CareerManagerWFRP1E.createAdvanceScheme(
        tSource
    )
end