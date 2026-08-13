--[[
    WFRP1E
    Career Advance Scheme column

    Database source example:

        career.id-00001.advancescheme.ws

    Persistent:
        steps

    Derived:
        displayed advancement amount
]]

local sCharacteristic = nil

local nLastValidSteps = 0
local bRestoringValue = false


function onInit()
    local nodeCharacteristic =
        getDatabaseNode()

    if not nodeCharacteristic then
        print(
            "WFRP1E | ERROR: Career advance column has no database node."
        )

        return
    end

    sCharacteristic =
        DB.getName(
            nodeCharacteristic
        )

    if not DataCommonWFRP1E.getCharacteristicDefinition(
        sCharacteristic
    ) then
        print(
            "WFRP1E | ERROR: Unknown Career characteristic: "
            .. tostring(sCharacteristic)
        )

        return
    end

    characteristic_id.setValue(
        Interface.getString(
            "wfrp1e_char_abbrev_"
            .. sCharacteristic
        )
    )

    local nSteps =
        tonumber(
            steps.getValue()
        ) or 0

    if not CareerManagerWFRP1E.isValidAdvanceStepCount(
        nSteps
    ) then
        nSteps = 0
        steps.setValue(0)
    end

    nLastValidSteps = nSteps

    updateAmount()
end


function onStepsValueChanged()
    if bRestoringValue then
        return
    end

    local nSteps =
        tonumber(
            steps.getValue()
        ) or 0

    if not CareerManagerWFRP1E.isValidAdvanceStepCount(
        nSteps
    ) then
        bRestoringValue = true

        steps.setValue(
            nLastValidSteps
        )

        bRestoringValue = false

        return
    end

    nLastValidSteps = nSteps

    updateAmount()
end


function updateAmount()
    if not sCharacteristic then
        return
    end

    local nAmount =
        CharacteristicManagerWFRP1E
            .calculateCareerAdvance(
                sCharacteristic,
                nLastValidSteps
            )

    if not nAmount or nAmount == 0 then
        amount.setValue("")
    else
        amount.setValue(
            "+" .. tostring(nAmount)
        )
    end
end


function onLockModeChanged(bReadOnly)
    steps.setReadOnly(
        bReadOnly
    )
end