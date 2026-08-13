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

    Checkpoint #9F deliberately uses a bitmap for the completion mark.
    The inherited sheet text font does not reliably provide a Unicode
    check glyph, so the bitmap avoids missing-glyph square rendering.
]]

local sCharacteristic = nil

local sInitialPath = nil
local sCareerPath = nil
local sPurchasedPath = nil
local sExperienceTotalAwardedPath = nil
local sExperienceSpentPath = nil

local bHeaderCanPurchase = false
local bHeaderCanRefund = false

local wCompleteMarker = nil

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


local function configureStateHeaderGeometry()
    -- Preserve the validated 38 px characteristic column.
    -- Give the characteristic abbreviation 24 px and the smaller
    -- action marker 14 px. This is especially important for Dex/Int/Fel.
    characteristic_id_with_state.setStaticBounds(0, 0, 24, 20)
    advance_state_marker.setStaticBounds(24, 0, 14, 20)

    if Interface.isFont("sheettextsmall") then
        advance_state_marker.setFont("sheettextsmall")
    end
end


local function createCompleteMarkerWidget()
    wCompleteMarker =
        advance_state_marker.addBitmapWidget(
            "wfrp1e_char_advancement_complete_icon"
        )

    if not wCompleteMarker then
        print(
            "WFRP1E | ERROR: Could not create advancement completion marker widget."
        )

        return
    end

    wCompleteMarker.setSize(10, 10)
    wCompleteMarker.setPosition("center", 0, 0)
    wCompleteMarker.setEnabled(false)
    wCompleteMarker.setVisible(false)
end


local function setHeaderWithoutMarker()
    characteristic_id.setVisible(true)
    characteristic_id_with_state.setVisible(false)

    advance_state_marker.setValue("")
    advance_state_marker.setColor(COLOR_MARKER_NEUTRAL)
    advance_state_marker.setVisible(false)

    if wCompleteMarker then
        wCompleteMarker.setVisible(false)
    end
end


local function setHeaderPending(sColor)
    characteristic_id.setVisible(false)
    characteristic_id_with_state.setVisible(true)

    if wCompleteMarker then
        wCompleteMarker.setVisible(false)
    end

    advance_state_marker.setValue("[+]")
    advance_state_marker.setColor(sColor)
    advance_state_marker.setVisible(true)
end


local function setHeaderComplete(sColor)
    characteristic_id.setVisible(false)
    characteristic_id_with_state.setVisible(true)

    advance_state_marker.setValue("")
    advance_state_marker.setColor(COLOR_MARKER_NEUTRAL)
    advance_state_marker.setVisible(true)

    if wCompleteMarker then
        wCompleteMarker.setColor(sColor)
        wCompleteMarker.setVisible(true)
    end
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

    local nodeChar = getCharacterNode()

    if nodeChar then
        local nodeExperience = DB.getChild(nodeChar, "experience")

        if nodeExperience then
            sExperienceTotalAwardedPath =
                DB.getPath(nodeExperience, "totalAwarded")

            sExperienceSpentPath =
                DB.getPath(nodeExperience, "spent")

            DB.addHandler(
                sExperienceTotalAwardedPath,
                "onUpdate",
                onAdvancementAvailabilityUpdated
            )

            DB.addHandler(
                sExperienceSpentPath,
                "onUpdate",
                onAdvancementAvailabilityUpdated
            )
        end
    end

    local sAbbreviation =
        Interface.getString(
            "wfrp1e_char_abbrev_"
            .. sCharacteristic
        )

    characteristic_id.setValue(sAbbreviation)
    characteristic_id_with_state.setValue(sAbbreviation)

    configureStateHeaderGeometry()
    createCompleteMarkerWidget()
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

    if sExperienceTotalAwardedPath then
        DB.removeHandler(
            sExperienceTotalAwardedPath,
            "onUpdate",
            onAdvancementAvailabilityUpdated
        )
    end

    if sExperienceSpentPath then
        DB.removeHandler(
            sExperienceSpentPath,
            "onUpdate",
            onAdvancementAvailabilityUpdated
        )
    end
end


function onCharacteristicSourceUpdated()
    updateDerivedValues()
end


function onAdvancementAvailabilityUpdated()
    refreshAdvancementHeader()
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
