--[[
    WFRP1E
    Generic characteristic profile column

    Each instance is bound to one characteristic database node:

        characteristics.m
        characteristics.ws
        characteristics.bs
        ...

    Persistent data:
        initial
        career
        purchased

    Derived presentation:
        Advance Scheme
        Current Profile
        inline advancement header state

    Final advancement header states:

        WS        no advancement in current Career
        WS [+]    unfinished Career requirement
        WS ✓      Career requirement satisfied

    The abbreviation remains neutral. Only the state marker is colored.

    Header interaction:
        Left click
            buy one advance when currently permitted

        Ctrl + Left click
            refund one advance bought during the current edit
            transaction

    The transparent interaction control is limited to the existing
    38 x 20 header area. It does not cover characteristic values or
    the Experience control.
]]

local sCharacteristic = nil

local sInitialPath = nil
local sCareerPath = nil
local sPurchasedPath = nil

local bHeaderCanPurchase = false
local bHeaderCanRefund = false

local COLOR_ADVANCE_PENDING = "#FFC00000"
local COLOR_ADVANCE_COMPLETE = "#FF008000"


local function getCharacterNode()
    local nodeCharacteristic =
        getDatabaseNode()

    if not nodeCharacteristic then
        return nil
    end

    local nodeCharacteristics =
        DB.getParent(
            nodeCharacteristic
        )

    if not nodeCharacteristics then
        return nil
    end

    return DB.getParent(
        nodeCharacteristics
    )
end


local function setHeaderWithoutMarker()
    characteristic_id.setVisible(
        true
    )

    characteristic_id_with_state.setVisible(
        false
    )

    advance_state_marker.setVisible(
        false
    )

    advance_state_marker.setValue(
        ""
    )
end


local function setHeaderWithMarker(
    sMarker,
    sColor
)
    characteristic_id.setVisible(
        false
    )

    characteristic_id_with_state.setVisible(
        true
    )

    advance_state_marker.setValue(
        sMarker
    )

    advance_state_marker.setColor(
        sColor
    )

    advance_state_marker.setVisible(
        true
    )
end


local function buildAdvancementTooltip(
    nodeChar,
    nCareer,
    nPurchased,
    tState
)
    local bReadOnly =
        DB.isReadOnly(
            nodeChar
        )

    if bReadOnly then
        return "Character is read-only."
    end

    local bHasCareerRequirement =
        nCareer > 0

    local bCareerComplete =
        bHasCareerRequirement
        and nPurchased >= nCareer

    if not bHasCareerRequirement then
        if bHeaderCanRefund then
            return
                "No advancement in current Career. "
                .. "Ctrl+Left click: Refund transaction advance"
        end

        return "No advancement in current Career."
    end

    if bCareerComplete then
        if bHeaderCanRefund then
            return
                "Career requirement satisfied. "
                .. "Ctrl+Left click: Refund transaction advance"
        end

        return "Career requirement satisfied."
    end

    if tState
        and tState.valid
        and tState.reason
            == "insufficient-experience"
    then
        if bHeaderCanRefund then
            return
                "100 XP required to buy next advance. "
                .. "Ctrl+Left click: Refund transaction advance"
        end

        return "100 XP required to buy next advance."
    end

    if bHeaderCanPurchase then
        if bHeaderCanRefund then
            return
                "Left click: Buy advance (100 XP). "
                .. "Ctrl+Left click: Refund transaction advance"
        end

        return "Left click: Buy advance (100 XP)."
    end

    if bHeaderCanRefund then
        return
            "Ctrl+Left click: Refund transaction advance"
    end

    return "Advance unavailable."
end


function onInit()
    local nodeCharacteristic =
        getDatabaseNode()

    if not nodeCharacteristic then
        print(
            "WFRP1E | ERROR: Characteristic window has no database node."
        )

        return
    end

    sCharacteristic = DB.getName(
        nodeCharacteristic
    )

    if not DataCommonWFRP1E.getCharacteristicDefinition(
        sCharacteristic
    ) then
        print(
            "WFRP1E | ERROR: Unknown characteristic: "
            .. tostring(sCharacteristic)
        )

        return
    end

    sInitialPath = DB.getPath(
        nodeCharacteristic,
        "initial"
    )

    sCareerPath = DB.getPath(
        nodeCharacteristic,
        "career"
    )

    sPurchasedPath = DB.getPath(
        nodeCharacteristic,
        "purchased"
    )

    DB.addHandler(
        sInitialPath,
        "onUpdate",
        onCharacteristicSourceUpdated
    )

    DB.addHandler(
        sCareerPath,
        "onUpdate",
        onCharacteristicSourceUpdated
    )

    DB.addHandler(
        sPurchasedPath,
        "onUpdate",
        onCharacteristicSourceUpdated
    )

    local sAbbreviation =
        Interface.getString(
            "wfrp1e_char_abbrev_"
            .. sCharacteristic
        )

    characteristic_id.setValue(
        sAbbreviation
    )

    characteristic_id_with_state.setValue(
        sAbbreviation
    )

    updateDerivedValues()
end


function onClose()
    if sInitialPath then
        DB.removeHandler(
            sInitialPath,
            "onUpdate",
            onCharacteristicSourceUpdated
        )
    end

    if sCareerPath then
        DB.removeHandler(
            sCareerPath,
            "onUpdate",
            onCharacteristicSourceUpdated
        )
    end

    if sPurchasedPath then
        DB.removeHandler(
            sPurchasedPath,
            "onUpdate",
            onCharacteristicSourceUpdated
        )
    end
end


function onCharacteristicSourceUpdated()
    updateDerivedValues()
end


function updateDerivedValues()
    if not sCharacteristic then
        return
    end

    local nodeCharacteristic =
        getDatabaseNode()

    if not nodeCharacteristic then
        return
    end

    local nInitial = DB.getValue(
        nodeCharacteristic,
        "initial",
        0
    )

    local nCareer = DB.getValue(
        nodeCharacteristic,
        "career",
        0
    )

    local nPurchased = DB.getValue(
        nodeCharacteristic,
        "purchased",
        0
    )


    local nCareerAdvance =
        CharacteristicManagerWFRP1E.calculateCareerAdvance(
            sCharacteristic,
            nCareer
        )

    if not nCareerAdvance or nCareerAdvance == 0 then
        career_display.setValue("")
    else
        career_display.setValue(
            "+" .. tostring(nCareerAdvance)
        )
    end


    local nCurrent =
        CharacteristicManagerWFRP1E.calculateCurrent(
            sCharacteristic,
            nInitial,
            nPurchased
        )

    current.setValue(
        nCurrent or 0
    )

    refreshAdvancementHeader()
end


function refreshAdvancementHeader()
    if not sCharacteristic then
        return
    end

    local nodeCharacteristic =
        getDatabaseNode()

    if not nodeCharacteristic then
        return
    end

    local nCareer =
        tonumber(
            DB.getValue(
                nodeCharacteristic,
                "career",
                0
            )
        ) or 0

    local nPurchased =
        tonumber(
            DB.getValue(
                nodeCharacteristic,
                "purchased",
                0
            )
        ) or 0

    if nCareer <= 0 then
        setHeaderWithoutMarker()
    elseif nPurchased >= nCareer then
        setHeaderWithMarker(
            Interface.getString(
                "wfrp1e_char_advancement_complete_marker"
            ),
            COLOR_ADVANCE_COMPLETE
        )
    else
        setHeaderWithMarker(
            "[+]",
            COLOR_ADVANCE_PENDING
        )
    end

    bHeaderCanPurchase = false
    bHeaderCanRefund = false

    local nodeChar =
        getCharacterNode()

    if not nodeChar then
        advance_header_hitbox.setHoverCursor(
            "arrow"
        )

        advance_header_hitbox.setTooltipText(
            ""
        )

        return
    end

    local bReadOnly =
        DB.isReadOnly(
            nodeChar
        )

    local tState =
        CharacterAdvancementManagerWFRP1E
            .getCharacteristicAdvanceState(
                nodeChar,
                sCharacteristic
            )

    if not bReadOnly
        and tState
        and tState.valid
        and tState.canPurchase
    then
        bHeaderCanPurchase = true
    end

    if not bReadOnly
        and CharacterAdvancementManagerWFRP1E
            .hasRefundableCharacteristicAdvance(
                nodeChar,
                sCharacteristic
            )
    then
        bHeaderCanRefund = true
    end

    if bHeaderCanPurchase or bHeaderCanRefund then
        advance_header_hitbox.setHoverCursor(
            "hand"
        )
    else
        advance_header_hitbox.setHoverCursor(
            "arrow"
        )
    end

    advance_header_hitbox.setTooltipText(
        buildAdvancementTooltip(
            nodeChar,
            nCareer,
            nPurchased,
            tState
        )
    )
end


function isAdvancementHeaderActionable()
    if Input.isControlPressed() then
        return bHeaderCanRefund
    end

    return bHeaderCanPurchase
end


function handleAdvancementHeaderClick()
    refreshAdvancementHeader()

    if not isAdvancementHeaderActionable() then
        return false
    end

    if not parentcontrol then
        return false
    end

    if not parentcontrol.window then
        return false
    end

    if not parentcontrol.window.purchaseCharacteristicAdvance then
        return false
    end

    parentcontrol.window.purchaseCharacteristicAdvance(
        sCharacteristic
    )

    refreshAdvancementHeader()

    return true
end