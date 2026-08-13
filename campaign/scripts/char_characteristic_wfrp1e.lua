--[[
    WFRP1E
    Generic characteristic profile column

    Persistent data:
        initial
        career
        purchased

    Derived presentation:
        Advance Scheme
        Current Profile
        inline advancement header state

    Header states:
        WS        no advancement in current Career
        WS [+]    unfinished Career requirement
        WS check  Career requirement satisfied

    Marker color communicates whether the header is actionable now:
        red [+]      unfinished and purchase/refund is available
        black [+]    unfinished and no action is available
        green check  complete and transaction refund is available
        black check  complete and no action is available

    Left click buys one advance when permitted.
    Ctrl + Left click refunds one advance bought during the current
    edit transaction.

    The interaction surface remains limited to the existing 38 x 20
    characteristic header.

    Header geometry is selected by abbreviation length so one-, two-
    and three-letter characteristic names remain visually centered as
    a combined abbreviation + state-marker group.
]]

local sCharacteristic = nil

local sInitialPath = nil
local sCareerPath = nil
local sPurchasedPath = nil

local bHeaderCanPurchase = false
local bHeaderCanRefund = false

local COMPLETE_ICON =
    "wfrp1e_char_advancement_complete_icon"

local COLOR_MARKER_NEUTRAL = "#FF000000"
local COLOR_ADVANCE_PENDING = "#FFC00000"
local COLOR_ADVANCE_COMPLETE = "#FF008000"


local function getCharacterNode()
    local nodeCharacteristic = getDatabaseNode()

    if not nodeCharacteristic then
        return nil
    end

    local nodeCharacteristics = DB.getParent(nodeCharacteristic)

    if not nodeCharacteristics then
        return nil
    end

    return DB.getParent(nodeCharacteristics)
end


local function configureStateHeaderGeometry(sAbbreviation)
    -- Preserve the validated 38 px characteristic column while
    -- centering the combined abbreviation + marker group.
    --
    -- One-letter abbreviations need a compact group so the marker does
    -- not look detached. Two-letter abbreviations use most of the
    -- column. Three-letter abbreviations get the largest text area.

    local nLength = string.len(sAbbreviation or "")

    local nAbbrevX = 0
    local nAbbrevWidth = 23
    local nMarkerX = 23
    local nMarkerWidth = 15

    if nLength <= 1 then
        nAbbrevX = 4
        nAbbrevWidth = 15
        nMarkerX = 19
        nMarkerWidth = 15
    elseif nLength == 2 then
        nAbbrevX = 1
        nAbbrevWidth = 19
        nMarkerX = 20
        nMarkerWidth = 17
    end

    characteristic_id_with_state.setStaticBounds(
        nAbbrevX,
        0,
        nAbbrevWidth,
        20
    )

    advance_state_marker.setStaticBounds(
        nMarkerX,
        0,
        nMarkerWidth,
        20
    )

    local nCheckSize = 10
    local nCheckX =
        nMarkerX
        + math.floor(
            (nMarkerWidth - nCheckSize) / 2
        )

    advance_complete_marker.setStaticBounds(
        nCheckX,
        5,
        nCheckSize,
        nCheckSize
    )

    if Interface.isFont("sheettextsmall") then
        advance_state_marker.setFont("sheettextsmall")
    end
end


local function initializeCompleteMarker()
    if not Interface.isIcon(COMPLETE_ICON) then
        print(
            "WFRP1E | ERROR: Advancement completion icon resource is unavailable: "
            .. COMPLETE_ICON
        )

        return
    end

    -- Set the icon explicitly at runtime even though it is also declared
    -- in XML. This verifies the resolved icon resource is the one drawn
    -- by the control rather than relying only on initial XML state.
    advance_complete_marker.setIcon(
        COMPLETE_ICON
    )

    advance_complete_marker.setDrawMode(
        "fit"
    )

    advance_complete_marker.setEnabled(
        false
    )
end


local function setHeaderWithoutMarker()
    characteristic_id.setVisible(true)
    characteristic_id_with_state.setVisible(false)

    advance_state_marker.setValue("")
    advance_state_marker.setColor(COLOR_MARKER_NEUTRAL)
    advance_state_marker.setVisible(false)

    advance_complete_marker.setColor(COLOR_MARKER_NEUTRAL)
    advance_complete_marker.setVisible(false)
end


local function setHeaderPending(sColor)
    characteristic_id.setVisible(false)
    characteristic_id_with_state.setVisible(true)

    advance_complete_marker.setVisible(false)

    advance_state_marker.setValue("[+]")
    advance_state_marker.setColor(sColor)
    advance_state_marker.setVisible(true)
end


local function setHeaderComplete(sColor)
    characteristic_id.setVisible(false)
    characteristic_id_with_state.setVisible(true)

    advance_state_marker.setValue("")
    advance_state_marker.setColor(COLOR_MARKER_NEUTRAL)
    advance_state_marker.setVisible(false)

    advance_complete_marker.setColor(sColor)
    advance_complete_marker.setVisible(true)
end


local function buildAdvancementTooltip(
    nodeChar,
    nCareer,
    nPurchased,
    tState
)
    if DB.isReadOnly(nodeChar) then
        return "Character is read-only."
    end

    local bHasCareerRequirement = nCareer > 0
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
        and tState.reason == "insufficient-experience"
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
        return "Ctrl+Left click: Refund transaction advance"
    end

    return "Advance unavailable."
end


function onInit()
    local nodeCharacteristic = getDatabaseNode()

    if not nodeCharacteristic then
        print(
            "WFRP1E | ERROR: Characteristic window has no database node."
        )

        return
    end

    sCharacteristic = DB.getName(nodeCharacteristic)

    if not DataCommonWFRP1E.getCharacteristicDefinition(
        sCharacteristic
    ) then
        print(
            "WFRP1E | ERROR: Unknown characteristic: "
            .. tostring(sCharacteristic)
        )

        return
    end

    sInitialPath = DB.getPath(nodeCharacteristic, "initial")
    sCareerPath = DB.getPath(nodeCharacteristic, "career")
    sPurchasedPath = DB.getPath(nodeCharacteristic, "purchased")

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

    characteristic_id.setValue(sAbbreviation)
    characteristic_id_with_state.setValue(sAbbreviation)

    configureStateHeaderGeometry(
        sAbbreviation
    )

    initializeCompleteMarker()
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

    local nodeCharacteristic = getDatabaseNode()

    if not nodeCharacteristic then
        return
    end

    local nInitial =
        DB.getValue(
            nodeCharacteristic,
            "initial",
            0
        )

    local nCareer =
        DB.getValue(
            nodeCharacteristic,
            "career",
            0
        )

    local nPurchased =
        DB.getValue(
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

    current.setValue(nCurrent or 0)

    refreshAdvancementHeader()
end


function refreshAdvancementHeader()
    if not sCharacteristic then
        return
    end

    local nodeCharacteristic = getDatabaseNode()

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

    bHeaderCanPurchase = false
    bHeaderCanRefund = false

    local nodeChar = getCharacterNode()
    local tState = nil

    if nodeChar then
        local bReadOnly = DB.isReadOnly(nodeChar)

        tState =
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
    end

    if nCareer <= 0 then
        setHeaderWithoutMarker()
    elseif nPurchased >= nCareer then
        setHeaderComplete(
            bHeaderCanRefund
                and COLOR_ADVANCE_COMPLETE
                or COLOR_MARKER_NEUTRAL
        )
    else
        setHeaderPending(
            (bHeaderCanPurchase or bHeaderCanRefund)
                and COLOR_ADVANCE_PENDING
                or COLOR_MARKER_NEUTRAL
        )
    end

    if not nodeChar then
        advance_header_hitbox.setHoverCursor("arrow")
        advance_header_hitbox.setTooltipText("")
        return
    end

    if bHeaderCanPurchase or bHeaderCanRefund then
        advance_header_hitbox.setHoverCursor("hand")
    else
        advance_header_hitbox.setHoverCursor("arrow")
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

    if not parentcontrol
        or not parentcontrol.window
        or not parentcontrol.window.purchaseCharacteristicAdvance
    then
        return false
    end

    parentcontrol.window.purchaseCharacteristicAdvance(
        sCharacteristic
    )

    refreshAdvancementHeader()

    return true
end
