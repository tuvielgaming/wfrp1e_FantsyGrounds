--[[
    WFRP1E
    Common system data

    Contains static ruleset data shared by the WFRP1E implementation.
    No UI code and no campaign-specific state should be stored here.
]]

aCharacteristicOrder = {
    "m",
    "ws",
    "bs",
    "s",
    "t",
    "w",
    "i",
    "a",
    "dex",
    "ld",
    "int",
    "cl",
    "wp",
    "fel"
}

tCharacteristicDefinitions = {
    m = {
        advanceStep = 1
    },
    ws = {
        advanceStep = 10
    },
    bs = {
        advanceStep = 10
    },
    s = {
        advanceStep = 1
    },
    t = {
        advanceStep = 1
    },
    w = {
        advanceStep = 1
    },
    i = {
        advanceStep = 10
    },
    a = {
        advanceStep = 1
    },
    dex = {
        advanceStep = 10
    },
    ld = {
        advanceStep = 10
    },
    int = {
        advanceStep = 10
    },
    cl = {
        advanceStep = 10
    },
    wp = {
        advanceStep = 10
    },
    fel = {
        advanceStep = 10
    }
}

function getCharacteristics()
    return aCharacteristicOrder
end

function getCharacteristicCount()
    return #aCharacteristicOrder
end

function getCharacteristicDefinition(sCharacteristic)
    return tCharacteristicDefinitions[sCharacteristic]
end

function getAdvanceStep(sCharacteristic)
    local tDefinition = getCharacteristicDefinition(sCharacteristic)

    if not tDefinition then
        return nil
    end

    return tDefinition.advanceStep
end