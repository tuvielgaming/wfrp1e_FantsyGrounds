--[[
    WFRP1E
    Character main sheet

    Binds:

        characteristic profile
        current Career
        Experience

    Career records may be dropped onto this window.

    Advancement interaction:

        Left click
            buy one characteristic advance

        Ctrl + Left click
            refund one characteristic advance bought during the
            current Character-sheet edit transaction

    Transaction lifetime is owned globally by
    CharacterAdvancementManagerWFRP1E because CoreRPG Character
    sheets use soft-close behavior.

    Experience is shared by every characteristic advancement header.
    The main sheet therefore owns one pair of Experience DB handlers
    and refreshes all 14 characteristic headers whenever the ledger
    changes. This keeps red/black actionability state synchronized.
]]

local sExperienceTotalAwardedPath = nil
local sExperienceSpentPath = nil


local function getCharacteristicControls()
    return {
        characteristic_m,
        characteristic_ws,
        characteristic_bs,
        characteristic_s,
        characteristic_t,
        characteristic_w,
        characteristic_i,
        characteristic_a,
        characteristic_dex,
        characteristic_ld,
        characteristic_int,
        characteristic_cl,
        characteristic_wp,
        characteristic_fel
    }
end


function onInit()
    local nodeChar = getDatabaseNode()

    if not nodeChar then
        print(
            "WFRP1E | ERROR: Character main sheet has no database node."
        )

        return
    end

    local aBindings = {
        {
            control = characteristic_m,
            id = "m"
        },
        {
            control = characteristic_ws,
            id = "ws"
        },
        {
            control = characteristic_bs,
            id = "bs"
        },
        {
            control = characteristic_s,
            id = "s"
        },
        {
            control = characteristic_t,
            id = "t"
        },
        {
            control = characteristic_w,
            id = "w"
        },
        {
            control = characteristic_i,
            id = "i"
        },
        {
            control = characteristic_a,
            id = "a"
        },
        {
            control = characteristic_dex,
            id = "dex"
        },
        {
            control = characteristic_ld,
            id = "ld"
        },
        {
            control = characteristic_int,
            id = "int"
        },
        {
            control = characteristic_cl,
            id = "cl"
        },
        {
            control = characteristic_wp,
            id = "wp"
        },
        {
            control = characteristic_fel,
            id = "fel"
        }
    }

    for _, rBinding in ipairs(aBindings) do
        bindCharacteristic(
            nodeChar,
            rBinding.control,
            rBinding.id
        )
    end

    bindCurrentCareer(
        nodeChar
    )

    bindExperience(
        nodeChar
    )
end


function onClose()
    if sExperienceTotalAwardedPath then
        DB.removeHandler(
            sExperienceTotalAwardedPath,
            "onUpdate",
            onExperienceLedgerUpdated
        )
    end

    if sExperienceSpentPath then
        DB.removeHandler(
            sExperienceSpentPath,
            "onUpdate",
            onExperienceLedgerUpdated
        )
    end
end


function bindCharacteristic(
    nodeChar,
    control,
    sCharacteristic
)
    local nodeCharacteristic =
        DB.createChild(
            nodeChar,
            "characteristics." .. sCharacteristic
        )

    if not nodeCharacteristic then
        print(
            "WFRP1E | ERROR: Unable to create characteristic node: "
            .. tostring(sCharacteristic)
        )

        return
    end

    control.setValue(
        "wfrp1e_characteristic",
        DB.getPath(nodeCharacteristic)
    )
end


function bindCurrentCareer(nodeChar)
    local nodeCurrentCareer =
        DB.createChild(
            nodeChar,
            "career.current"
        )

    if not nodeCurrentCareer then
        print(
            "WFRP1E | ERROR: Unable to create Current Career node."
        )

        return
    end

    current_career.setValue(
        "wfrp1e_current_career",
        DB.getPath(nodeCurrentCareer)
    )
end


function bindExperience(nodeChar)
    local nodeExperience =
        CharacterExperienceManagerWFRP1E.ensureExperience(
            nodeChar
        )

    if not nodeExperience then
        print(
            "WFRP1E | ERROR: Unable to create Character Experience ledger."
        )

        return
    end

    experience.setValue(
        "wfrp1e_experience",
        DB.getPath(nodeExperience)
    )

    sExperienceTotalAwardedPath =
        DB.getPath(
            nodeExperience,
            "totalAwarded"
        )

    sExperienceSpentPath =
        DB.getPath(
            nodeExperience,
            "spent"
        )

    DB.addHandler(
        sExperienceTotalAwardedPath,
        "onUpdate",
        onExperienceLedgerUpdated
    )

    DB.addHandler(
        sExperienceSpentPath,
        "onUpdate",
        onExperienceLedgerUpdated
    )
end


function onExperienceLedgerUpdated()
    refreshAllCharacteristicHeaders()
end


function refreshAllCharacteristicHeaders()
    for _, control in ipairs(getCharacteristicControls()) do
        if control
            and control.subwindow
            and control.subwindow.refreshAdvancementHeader
        then
            control.subwindow.refreshAdvancementHeader()
        end
    end
end


function clearExperienceFocus()
    if not experience then
        return
    end

    if not experience.subwindow then
        return
    end

    if not experience.subwindow.available then
        return
    end

    experience.subwindow.available.setFocus(
        false
    )
end


function purchaseCharacteristicAdvance(
    sCharacteristic
)
    clearExperienceFocus()

    local nodeChar =
        getDatabaseNode()

    if not nodeChar then
        print(
            "WFRP1E | ERROR: Character sheet has no database node."
        )

        return
    end

    if Input.isControlPressed() then
        refundCharacteristicAdvance(
            nodeChar,
            sCharacteristic
        )

        return
    end

    local tResult =
        CharacterAdvancementManagerWFRP1E
            .purchaseCharacteristicAdvance(
                nodeChar,
                sCharacteristic
            )

    if not tResult.success then
        refreshAllCharacteristicHeaders()

        print(
            "WFRP1E | Advance rejected: "
            .. tostring(sCharacteristic)
            .. " | "
            .. tostring(tResult.reason)
        )

        return
    end

    -- Refresh after the manager has completed both persistent writes
    -- and transaction bookkeeping, so marker colors reflect the final
    -- state rather than an intermediate DB event.
    refreshAllCharacteristicHeaders()

    print(
        "WFRP1E | Advance purchased: "
        .. tostring(sCharacteristic)
        .. " | purchased "
        .. tostring(tResult.purchasedBefore)
        .. " -> "
        .. tostring(tResult.purchasedAfter)
        .. " | spent XP "
        .. tostring(tResult.spentBefore)
        .. " -> "
        .. tostring(tResult.spentAfter)
        .. " | transaction advances "
        .. tostring(tResult.transactionPurchased)
    )
end


function refundCharacteristicAdvance(
    nodeChar,
    sCharacteristic
)
    local tResult =
        CharacterAdvancementManagerWFRP1E
            .refundCharacteristicAdvance(
                nodeChar,
                sCharacteristic
            )

    if not tResult.success then
        refreshAllCharacteristicHeaders()

        print(
            "WFRP1E | Advance refund rejected: "
            .. tostring(sCharacteristic)
            .. " | "
            .. tostring(tResult.reason)
        )

        return
    end

    refreshAllCharacteristicHeaders()

    print(
        "WFRP1E | Advance refunded: "
        .. tostring(sCharacteristic)
        .. " | purchased "
        .. tostring(tResult.purchasedBefore)
        .. " -> "
        .. tostring(tResult.purchasedAfter)
        .. " | spent XP "
        .. tostring(tResult.spentBefore)
        .. " -> "
        .. tostring(tResult.spentAfter)
        .. " | transaction advances "
        .. tostring(tResult.transactionPurchased)
    )
end


function onDrop(x, y, draginfo)
    if not draginfo then
        return
    end

    if not draginfo.isType("shortcut") then
        return
    end

    local sClass, sRecord =
        draginfo.getShortcutData()

    if sClass ~= "career" then
        return
    end

    if not sRecord or sRecord == "" then
        return
    end

    local nodeCareer =
        DB.findNode(
            sRecord
        )

    if not nodeCareer then
        print(
            "WFRP1E | ERROR: Unable to resolve dropped Career: "
            .. tostring(sRecord)
        )

        return true
    end

    local nodeChar =
        getDatabaseNode()

    if not nodeChar then
        print(
            "WFRP1E | ERROR: Character sheet has no database node."
        )

        return true
    end

    if DB.isReadOnly(nodeChar) then
        print(
            "WFRP1E | Career assignment rejected: "
            .. "Character is read-only."
        )

        return true
    end

    clearExperienceFocus()

    local bAssigned =
        CharacterCareerManagerWFRP1E.assignCareer(
            nodeChar,
            nodeCareer,
            sClass,
            sRecord
        )

    if not bAssigned then
        print(
            "WFRP1E | ERROR: Career assignment failed."
        )

        return true
    end

    refreshAllCharacteristicHeaders()

    local sCareerName =
        DB.getValue(
            nodeCareer,
            "name",
            ""
        )

    print(
        "WFRP1E | Current Career assigned: "
        .. sCareerName
    )

    return true
end
