--[[
    WFRP1E
    Character Advancement manager

    Owns Character-level characteristic advancement transactions.

    Persistent advancement changes:

        characteristics.<id>.purchased
        experience.spent

    Derived values remain untouched:

        characteristic current
        available Experience

    ----------------------------------------------------------------
    ADVANCEMENT EDIT TRANSACTION
    ----------------------------------------------------------------

    A transaction begins lazily on the first successful advancement
    purchase.

    The transaction remains active while that top-level Character
    sheet is open.

    CoreRPG Character sheets use soft-close behavior. Closing the
    sheet therefore hides the top-level "charsheet" window rather
    than destroying its embedded "charsheet_main" window.

    For that reason the transaction boundary is NOT owned by
    charsheet_main.onClose().

    Instead this global manager listens for:

        Interface.onWindowClosing
        key: "charsheet"

    and ends the edit transaction when the top-level Character sheet
    receives its close operation.

    The transaction itself is intentionally NOT persisted.
]]

local tEditTransactions = {}


function onInit()
    Interface.addKeyedEventHandler(
        "onWindowClosing",
        "charsheet",
        onCharacterSheetClosing
    )
end


function onClose()
    Interface.removeKeyedEventHandler(
        "onWindowClosing",
        "charsheet",
        onCharacterSheetClosing
    )
end


function onCharacterSheetClosing(wCharacter)
    if not wCharacter then
        return
    end

    local nodeChar =
        wCharacter.getDatabaseNode()

    if not nodeChar then
        return
    end

    local bEnded =
        endEditTransaction(
            nodeChar
        )

    if bEnded then
        print(
            "WFRP1E | Advancement edit transaction ended."
        )
    end
end


local function getCharacterKey(nodeChar)
    if not nodeChar then
        return nil
    end

    return DB.getPath(
        nodeChar
    )
end


local function createFailure(sReason)
    return {
        success = false,
        reason = sReason
    }
end


function getCharacteristicAdvanceState(
    nodeChar,
    sCharacteristic
)
    if not nodeChar then
        return {
            valid = false,
            canPurchase = false,
            reason = "no-character"
        }
    end

    if not DataCommonWFRP1E.getCharacteristicDefinition(
        sCharacteristic
    ) then
        return {
            valid = false,
            canPurchase = false,
            reason = "unknown-characteristic"
        }
    end

    local nodeCharacteristic =
        DB.getChild(
            nodeChar,
            "characteristics."
                .. sCharacteristic
        )

    if not nodeCharacteristic then
        return {
            valid = false,
            canPurchase = false,
            reason = "missing-characteristic"
        }
    end

    local nPurchased =
        DB.getValue(
            nodeCharacteristic,
            "purchased",
            0
        )

    local nCareer =
        DB.getValue(
            nodeCharacteristic,
            "career",
            0
        )

    if not CharacteristicManagerWFRP1E.isValidAdvanceCount(
        nPurchased
    ) then
        return {
            valid = false,
            canPurchase = false,
            reason = "invalid-purchased"
        }
    end

    if not CharacteristicManagerWFRP1E.isValidAdvanceCount(
        nCareer
    ) then
        return {
            valid = false,
            canPurchase = false,
            reason = "invalid-career"
        }
    end

    nPurchased =
        tonumber(
            nPurchased
        )

    nCareer =
        tonumber(
            nCareer
        )

    local tLedger =
        CharacterExperienceManagerWFRP1E.getLedger(
            nodeChar
        )

    if not tLedger then
        return {
            valid = false,
            canPurchase = false,
            reason = "invalid-experience"
        }
    end

    local nCost =
        CharacteristicManagerWFRP1E
            .getAdvanceExperienceCost()

    local nAvailable =
        ExperienceManagerWFRP1E.calculateAvailable(
            tLedger.totalAwarded,
            tLedger.spent
        )

    local bCareerAllows =
        CharacteristicManagerWFRP1E.canPurchaseAdvance(
            sCharacteristic,
            nPurchased,
            nCareer
        )

    if not bCareerAllows then
        return {
            valid = true,
            canPurchase = false,
            reason = "career-limit",

            characteristic = sCharacteristic,

            purchased = nPurchased,
            career = nCareer,

            totalAwarded =
                tLedger.totalAwarded,

            spent =
                tLedger.spent,

            available =
                nAvailable,

            cost =
                nCost
        }
    end

    local bExperienceAllows =
        ExperienceManagerWFRP1E.canSpend(
            tLedger.totalAwarded,
            tLedger.spent,
            nCost
        )

    if not bExperienceAllows then
        return {
            valid = true,
            canPurchase = false,
            reason = "insufficient-experience",

            characteristic = sCharacteristic,

            purchased = nPurchased,
            career = nCareer,

            totalAwarded =
                tLedger.totalAwarded,

            spent =
                tLedger.spent,

            available =
                nAvailable,

            cost =
                nCost
        }
    end

    return {
        valid = true,
        canPurchase = true,
        reason = nil,

        characteristic = sCharacteristic,

        purchased = nPurchased,
        career = nCareer,

        totalAwarded =
            tLedger.totalAwarded,

        spent =
            tLedger.spent,

        available =
            nAvailable,

        cost =
            nCost
    }
end


function getEditTransaction(nodeChar)
    local sKey =
        getCharacterKey(
            nodeChar
        )

    if not sKey then
        return nil
    end

    return tEditTransactions[sKey]
end


function beginEditTransaction(nodeChar)
    if not nodeChar then
        return nil
    end

    local sKey =
        getCharacterKey(
            nodeChar
        )

    if not sKey then
        return nil
    end

    if tEditTransactions[sKey] then
        return tEditTransactions[sKey]
    end

    local tLedger =
        CharacterExperienceManagerWFRP1E.getLedger(
            nodeChar
        )

    if not tLedger then
        return nil
    end

    local tTransaction = {
        baselineSpent =
            tLedger.spent,

        totalPurchasedDelta = 0,

        baselinePurchased = {},
        purchasedDelta = {}
    }

    for _, sCharacteristic
        in ipairs(
            DataCommonWFRP1E.getCharacteristics()
        )
    do
        local nodeCharacteristic =
            DB.getChild(
                nodeChar,
                "characteristics."
                    .. sCharacteristic
            )

        if not nodeCharacteristic then
            return nil
        end

        local nPurchased =
            DB.getValue(
                nodeCharacteristic,
                "purchased",
                0
            )

        if not CharacteristicManagerWFRP1E.isValidAdvanceCount(
            nPurchased
        ) then
            return nil
        end

        nPurchased =
            tonumber(
                nPurchased
            )

        tTransaction.baselinePurchased[
            sCharacteristic
        ] = nPurchased

        tTransaction.purchasedDelta[
            sCharacteristic
        ] = 0
    end

    tEditTransactions[sKey] =
        tTransaction

    return tTransaction
end


function endEditTransaction(nodeChar)
    local sKey =
        getCharacterKey(
            nodeChar
        )

    if not sKey then
        return false
    end

    if not tEditTransactions[sKey] then
        return false
    end

    tEditTransactions[sKey] =
        nil

    return true
end


function getTransactionPurchasedDelta(
    nodeChar,
    sCharacteristic
)
    if not DataCommonWFRP1E.getCharacteristicDefinition(
        sCharacteristic
    ) then
        return 0
    end

    local tTransaction =
        getEditTransaction(
            nodeChar
        )

    if not tTransaction then
        return 0
    end

    return
        tTransaction.purchasedDelta[
            sCharacteristic
        ] or 0
end


function hasRefundableCharacteristicAdvance(
    nodeChar,
    sCharacteristic
)
    return
        getTransactionPurchasedDelta(
            nodeChar,
            sCharacteristic
        ) > 0
end


function validateEditTransaction(
    nodeChar,
    tTransaction
)
    if not nodeChar then
        return false, "no-character"
    end

    if not tTransaction then
        return false, "no-transaction"
    end

    local tLedger =
        CharacterExperienceManagerWFRP1E.getLedger(
            nodeChar
        )

    if not tLedger then
        return false, "invalid-experience"
    end

    local nCost =
        CharacteristicManagerWFRP1E
            .getAdvanceExperienceCost()

    local nExpectedSpent =
        tTransaction.baselineSpent
        + (
            tTransaction.totalPurchasedDelta
            * nCost
        )

    if tLedger.spent ~= nExpectedSpent then
        return false, "transaction-conflict"
    end

    for _, sCharacteristic
        in ipairs(
            DataCommonWFRP1E.getCharacteristics()
        )
    do
        local nBaseline =
            tTransaction.baselinePurchased[
                sCharacteristic
            ]

        local nDelta =
            tTransaction.purchasedDelta[
                sCharacteristic
            ] or 0

        if nBaseline == nil then
            return false, "transaction-conflict"
        end

        local nodeCharacteristic =
            DB.getChild(
                nodeChar,
                "characteristics."
                    .. sCharacteristic
            )

        if not nodeCharacteristic then
            return false, "transaction-conflict"
        end

        local nCurrentPurchased =
            DB.getValue(
                nodeCharacteristic,
                "purchased",
                0
            )

        if not CharacteristicManagerWFRP1E.isValidAdvanceCount(
            nCurrentPurchased
        ) then
            return false, "transaction-conflict"
        end

        nCurrentPurchased =
            tonumber(
                nCurrentPurchased
            )

        if nCurrentPurchased
            ~= nBaseline + nDelta
        then
            return false, "transaction-conflict"
        end
    end

    return true, nil
end


function purchaseCharacteristicAdvance(
    nodeChar,
    sCharacteristic
)
    if not nodeChar then
        return createFailure(
            "no-character"
        )
    end

    if DB.isReadOnly(nodeChar) then
        return createFailure(
            "read-only"
        )
    end

    local tState =
        getCharacteristicAdvanceState(
            nodeChar,
            sCharacteristic
        )

    if not tState.valid then
        return createFailure(
            tState.reason
        )
    end

    if not tState.canPurchase then
        return {
            success = false,
            reason = tState.reason,

            purchased =
                tState.purchased,

            career =
                tState.career,

            available =
                tState.available,

            cost =
                tState.cost
        }
    end

    local tTransaction =
        getEditTransaction(
            nodeChar
        )

    if not tTransaction then
        tTransaction =
            beginEditTransaction(
                nodeChar
            )

        if not tTransaction then
            return createFailure(
                "transaction-start-failed"
            )
        end
    end

    local bTransactionValid,
        sTransactionError =
            validateEditTransaction(
                nodeChar,
                tTransaction
            )

    if not bTransactionValid then
        return createFailure(
            sTransactionError
        )
    end

    local nPurchasedAfter =
        tState.purchased + 1

    local nSpentAfter =
        tState.spent + tState.cost

    tTransaction.purchasedDelta[
        sCharacteristic
    ] =
        tTransaction.purchasedDelta[
            sCharacteristic
        ] + 1

    tTransaction.totalPurchasedDelta =
        tTransaction.totalPurchasedDelta + 1

    DB.setValue(
        nodeChar,
        "characteristics."
            .. sCharacteristic
            .. ".purchased",
        "number",
        nPurchasedAfter
    )

    DB.setValue(
        nodeChar,
        "experience.spent",
        "number",
        nSpentAfter
    )

    return {
        success = true,

        characteristic =
            sCharacteristic,

        cost =
            tState.cost,

        purchasedBefore =
            tState.purchased,

        purchasedAfter =
            nPurchasedAfter,

        spentBefore =
            tState.spent,

        spentAfter =
            nSpentAfter,

        availableBefore =
            tState.available,

        availableAfter =
            tState.available
            - tState.cost,

        transactionPurchased =
            tTransaction.purchasedDelta[
                sCharacteristic
            ]
    }
end


function refundCharacteristicAdvance(
    nodeChar,
    sCharacteristic
)
    if not nodeChar then
        return createFailure(
            "no-character"
        )
    end

    if DB.isReadOnly(nodeChar) then
        return createFailure(
            "read-only"
        )
    end

    if not DataCommonWFRP1E.getCharacteristicDefinition(
        sCharacteristic
    ) then
        return createFailure(
            "unknown-characteristic"
        )
    end

    local tTransaction =
        getEditTransaction(
            nodeChar
        )

    if not tTransaction then
        return createFailure(
            "no-transaction"
        )
    end

    local bTransactionValid,
        sTransactionError =
            validateEditTransaction(
                nodeChar,
                tTransaction
            )

    if not bTransactionValid then
        return createFailure(
            sTransactionError
        )
    end

    local nTransactionPurchased =
        tTransaction.purchasedDelta[
            sCharacteristic
        ] or 0

    if nTransactionPurchased <= 0 then
        return createFailure(
            "no-refundable-advance"
        )
    end

    local nodeCharacteristic =
        DB.getChild(
            nodeChar,
            "characteristics."
                .. sCharacteristic
        )

    if not nodeCharacteristic then
        return createFailure(
            "missing-characteristic"
        )
    end

    local nPurchasedBefore =
        DB.getValue(
            nodeCharacteristic,
            "purchased",
            0
        )

    if not CharacteristicManagerWFRP1E.isValidAdvanceCount(
        nPurchasedBefore
    ) then
        return createFailure(
            "invalid-purchased"
        )
    end

    nPurchasedBefore =
        tonumber(
            nPurchasedBefore
        )

    local tLedger =
        CharacterExperienceManagerWFRP1E.getLedger(
            nodeChar
        )

    if not tLedger then
        return createFailure(
            "invalid-experience"
        )
    end

    local nCost =
        CharacteristicManagerWFRP1E
            .getAdvanceExperienceCost()

    if tLedger.spent < nCost then
        return createFailure(
            "transaction-conflict"
        )
    end

    local nPurchasedAfter =
        nPurchasedBefore - 1

    local nSpentAfter =
        tLedger.spent - nCost

    local nAvailableBefore =
        ExperienceManagerWFRP1E.calculateAvailable(
            tLedger.totalAwarded,
            tLedger.spent
        )

    tTransaction.purchasedDelta[
        sCharacteristic
    ] =
        nTransactionPurchased - 1

    tTransaction.totalPurchasedDelta =
        tTransaction.totalPurchasedDelta - 1

    DB.setValue(
        nodeChar,
        "characteristics."
            .. sCharacteristic
            .. ".purchased",
        "number",
        nPurchasedAfter
    )

    DB.setValue(
        nodeChar,
        "experience.spent",
        "number",
        nSpentAfter
    )

    return {
        success = true,

        characteristic =
            sCharacteristic,

        cost =
            nCost,

        purchasedBefore =
            nPurchasedBefore,

        purchasedAfter =
            nPurchasedAfter,

        spentBefore =
            tLedger.spent,

        spentAfter =
            nSpentAfter,

        availableBefore =
            nAvailableBefore,

        availableAfter =
            nAvailableBefore + nCost,

        transactionPurchased =
            tTransaction.purchasedDelta[
                sCharacteristic
            ]
    }
end