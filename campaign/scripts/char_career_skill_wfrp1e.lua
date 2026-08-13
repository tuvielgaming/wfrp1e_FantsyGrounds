--[[
    WFRP1E
    Current Career Skill advancement row

    WFRP 1e later-Career Skills cost 100 XP each and are not granted
    automatically.

    The persistent Career-offer flag is:

        purchased = 0 / 1

    The owned Character Skill created by a successful purchase remains
    a normal snapshot under character.skills.<id>.

    Refundability is intentionally in-memory only. The row remembers
    the exact Character advancement transaction object and owned Skill
    created by its successful purchase. Once the top-level Character
    sheet closes, CharacterAdvancementManagerWFRP1E ends that transaction;
    the old row state can therefore no longer be refunded.
]]

local COLOR_MARKER_NEUTRAL = "#FF000000"
local COLOR_ADVANCE_PENDING = "#FFC00000"
local COLOR_ADVANCE_COMPLETE = "#FF008000"

local COMPLETE_ICON =
    "wfrp1e_char_advancement_complete_icon"

local sPurchasedPath = nil
local sExperienceTotalAwardedPath = nil
local sExperienceSpentPath = nil

local bCanPurchase = false
local bCanRefund = false

local tPurchaseTransaction = nil
local sOwnedSkillPath = nil


local function getCharacterNode()
    local nodeOffer = getDatabaseNode()

    if not nodeOffer then
        return nil
    end

    local nodeSkills = DB.getParent(nodeOffer)
    local nodeCurrent = nodeSkills and DB.getParent(nodeSkills) or nil
    local nodeCareer = nodeCurrent and DB.getParent(nodeCurrent) or nil

    if not nodeCareer then
        return nil
    end

    return DB.getParent(nodeCareer)
end


local function getAdvanceCost()
    return
        CharacteristicManagerWFRP1E
            .getAdvanceExperienceCost()
end


local function isCurrentTransactionPurchase(nodeChar)
    if not nodeChar then
        return false
    end

    if not tPurchaseTransaction then
        return false
    end

    if not sOwnedSkillPath then
        return false
    end

    local tCurrent =
        CharacterAdvancementManagerWFRP1E
            .getEditTransaction(
                nodeChar
            )

    if tCurrent ~= tPurchaseTransaction then
        return false
    end

    return DB.findNode(sOwnedSkillPath) ~= nil
end


local function getState()
    local nodeOffer = getDatabaseNode()
    local nodeChar = getCharacterNode()

    if not nodeOffer or not nodeChar then
        return {
            valid = false,
            canPurchase = false,
            canRefund = false,
            reason = "missing-data"
        }
    end

    local nPurchased =
        tonumber(
            DB.getValue(
                nodeOffer,
                "purchased",
                0
            )
        ) or 0

    local tLedger =
        CharacterExperienceManagerWFRP1E.getLedger(
            nodeChar
        )

    if not tLedger then
        return {
            valid = false,
            canPurchase = false,
            canRefund = false,
            reason = "invalid-experience"
        }
    end

    local nCost = getAdvanceCost()

    local nAvailable =
        ExperienceManagerWFRP1E.calculateAvailable(
            tLedger.totalAwarded,
            tLedger.spent
        )

    local bRefundable =
        nPurchased >= 1
        and isCurrentTransactionPurchase(
            nodeChar
        )

    if nPurchased >= 1 then
        return {
            valid = true,
            canPurchase = false,
            canRefund = bRefundable,
            reason = "already-purchased",
            purchased = nPurchased,
            available = nAvailable,
            spent = tLedger.spent,
            cost = nCost
        }
    end

    local bExperienceAllows =
        ExperienceManagerWFRP1E.canSpend(
            tLedger.totalAwarded,
            tLedger.spent,
            nCost
        )

    return {
        valid = true,
        canPurchase = bExperienceAllows,
        canRefund = false,
        reason = bExperienceAllows
            and nil
            or "insufficient-experience",
        purchased = nPurchased,
        available = nAvailable,
        spent = tLedger.spent,
        cost = nCost
    }
end


local function initializeCompleteMarker()
    if not Interface.isIcon(COMPLETE_ICON) then
        print(
            "WFRP1E | ERROR: Career Skill completion icon resource is unavailable: "
            .. COMPLETE_ICON
        )

        return
    end

    advance_complete_marker.setIcon(
        COMPLETE_ICON
    )

    advance_complete_marker.setDrawMode(
        "fit"
    )

    advance_complete_marker.setEnabled(
        false
    )

    if Interface.isFont("sheettextsmall") then
        advance_state_marker.setFont(
            "sheettextsmall"
        )
    end
end


local function setPending(sColor)
    advance_complete_marker.setVisible(false)

    advance_state_marker.setValue("[+]")
    advance_state_marker.setColor(sColor)
    advance_state_marker.setVisible(true)
end


local function setComplete(sColor)
    advance_state_marker.setValue("")
    advance_state_marker.setColor(COLOR_MARKER_NEUTRAL)
    advance_state_marker.setVisible(false)

    advance_complete_marker.setColor(sColor)
    advance_complete_marker.setVisible(true)
end


local function buildTooltip(tState)
    local nodeChar = getCharacterNode()

    if not nodeChar then
        return "Career Skill unavailable."
    end

    if DB.isReadOnly(nodeChar) then
        return "Character is read-only."
    end

    if tState.purchased and tState.purchased >= 1 then
        if bCanRefund then
            return
                "Career Skill acquired. "
                .. "Ctrl+Left click: Refund transaction Skill (100 XP)"
        end

        return "Career Skill acquired."
    end

    if bCanPurchase then
        return "Left click: Acquire Career Skill (100 XP)."
    end

    if tState.reason == "insufficient-experience" then
        return "100 XP required to acquire this Career Skill."
    end

    return "Career Skill unavailable."
end


function onInit()
    local nodeOffer = getDatabaseNode()
    local nodeChar = getCharacterNode()

    if not nodeOffer or not nodeChar then
        print(
            "WFRP1E | ERROR: Current Career Skill row has no Character data."
        )

        return
    end

    sPurchasedPath =
        DB.getPath(
            nodeOffer,
            "purchased"
        )

    sExperienceTotalAwardedPath =
        DB.getPath(
            nodeChar,
            "experience.totalAwarded"
        )

    sExperienceSpentPath =
        DB.getPath(
            nodeChar,
            "experience.spent"
        )

    DB.addHandler(
        sPurchasedPath,
        "onUpdate",
        onSourceUpdated
    )

    DB.addHandler(
        sExperienceTotalAwardedPath,
        "onUpdate",
        onSourceUpdated
    )

    DB.addHandler(
        sExperienceSpentPath,
        "onUpdate",
        onSourceUpdated
    )

    initializeCompleteMarker()
    refreshAdvancementState()
end


function onClose()
    if sPurchasedPath then
        DB.removeHandler(
            sPurchasedPath,
            "onUpdate",
            onSourceUpdated
        )
    end

    if sExperienceTotalAwardedPath then
        DB.removeHandler(
            sExperienceTotalAwardedPath,
            "onUpdate",
            onSourceUpdated
        )
    end

    if sExperienceSpentPath then
        DB.removeHandler(
            sExperienceSpentPath,
            "onUpdate",
            onSourceUpdated
        )
    end
end


function onSourceUpdated()
    refreshAdvancementState()
end


function refreshAdvancementState()
    local tState = getState()
    local nodeChar = getCharacterNode()

    bCanPurchase = false
    bCanRefund = false

    if nodeChar
        and not DB.isReadOnly(nodeChar)
        and tState.valid
    then
        bCanPurchase = tState.canPurchase
        bCanRefund = tState.canRefund
    end

    if tState.purchased and tState.purchased >= 1 then
        setComplete(
            bCanRefund
                and COLOR_ADVANCE_COMPLETE
                or COLOR_MARKER_NEUTRAL
        )
    else
        setPending(
            bCanPurchase
                and COLOR_ADVANCE_PENDING
                or COLOR_MARKER_NEUTRAL
        )
    end

    if bCanPurchase or bCanRefund then
        advance_hitbox.setHoverCursor("hand")
    else
        advance_hitbox.setHoverCursor("arrow")
    end

    advance_hitbox.setTooltipText(
        buildTooltip(
            tState
        )
    )
end


function isAdvancementActionable()
    if Input.isControlPressed() then
        return bCanRefund
    end

    return bCanPurchase
end


local function clearExperienceFocus()
    if windowlist
        and windowlist.window
        and windowlist.window.clearExperienceFocus
    then
        windowlist.window.clearExperienceFocus()
    end
end


local function acquireCareerSkill()
    local nodeOffer = getDatabaseNode()
    local nodeChar = getCharacterNode()

    if not nodeOffer or not nodeChar then
        return false
    end

    if DB.isReadOnly(nodeChar) then
        return false
    end

    local tState = getState()

    if not tState.valid or not tState.canPurchase then
        return false
    end

    local tTransaction =
        CharacterAdvancementManagerWFRP1E
            .getEditTransaction(
                nodeChar
            )

    if not tTransaction then
        tTransaction =
            CharacterAdvancementManagerWFRP1E
                .beginEditTransaction(
                    nodeChar
                )
    end

    if not tTransaction then
        return false
    end

    local bTransactionValid =
        CharacterAdvancementManagerWFRP1E
            .validateEditTransaction(
                nodeChar,
                tTransaction
            )

    if not bTransactionValid then
        return false
    end

    local nodeOwnedSkill =
        CharacterSkillManagerWFRP1E.acquireSkill(
            nodeChar,
            nodeOffer,
            "skill",
            DB.getPath(nodeOffer)
        )

    if not nodeOwnedSkill then
        return false
    end

    -- Career offers are snapshots rather than top-level Skill records.
    -- Point the Character row at its own acquired snapshot so navigation
    -- still opens a complete Skill-shaped record.

    DB.setValue(
        nodeOwnedSkill,
        "link",
        "windowreference",
        "skill",
        DB.getPath(nodeOwnedSkill)
    )

    tPurchaseTransaction = tTransaction
    sOwnedSkillPath = DB.getPath(nodeOwnedSkill)

    tTransaction.totalPurchasedDelta =
        (tTransaction.totalPurchasedDelta or 0) + 1

    DB.setValue(
        nodeOffer,
        "purchased",
        "number",
        1
    )

    DB.setValue(
        nodeChar,
        "experience.spent",
        "number",
        tState.spent + tState.cost
    )

    print(
        "WFRP1E | Career Skill acquired: "
        .. DB.getValue(nodeOffer, "name", "")
        .. " | 100 XP"
    )

    return true
end


local function refundCareerSkill()
    local nodeOffer = getDatabaseNode()
    local nodeChar = getCharacterNode()

    if not nodeOffer or not nodeChar then
        return false
    end

    if DB.isReadOnly(nodeChar) then
        return false
    end

    local tTransaction =
        CharacterAdvancementManagerWFRP1E
            .getEditTransaction(
                nodeChar
            )

    if not tTransaction
        or tTransaction ~= tPurchaseTransaction
    then
        return false
    end

    local bTransactionValid =
        CharacterAdvancementManagerWFRP1E
            .validateEditTransaction(
                nodeChar,
                tTransaction
            )

    if not bTransactionValid then
        return false
    end

    local nodeOwnedSkill =
        sOwnedSkillPath
        and DB.findNode(sOwnedSkillPath)
        or nil

    if not nodeOwnedSkill then
        return false
    end

    local tLedger =
        CharacterExperienceManagerWFRP1E.getLedger(
            nodeChar
        )

    local nCost = getAdvanceCost()

    if not tLedger or tLedger.spent < nCost then
        return false
    end

    if (tTransaction.totalPurchasedDelta or 0) <= 0 then
        return false
    end

    tTransaction.totalPurchasedDelta =
        tTransaction.totalPurchasedDelta - 1

    tPurchaseTransaction = nil
    sOwnedSkillPath = nil

    DB.setValue(
        nodeOffer,
        "purchased",
        "number",
        0
    )

    DB.setValue(
        nodeChar,
        "experience.spent",
        "number",
        tLedger.spent - nCost
    )

    DB.deleteNode(
        nodeOwnedSkill
    )

    print(
        "WFRP1E | Career Skill refunded: "
        .. DB.getValue(nodeOffer, "name", "")
        .. " | 100 XP"
    )

    return true
end


function handleAdvancementClick()
    refreshAdvancementState()

    if not isAdvancementActionable() then
        return false
    end

    clearExperienceFocus()

    local bSuccess = false

    if Input.isControlPressed() then
        bSuccess = refundCareerSkill()
    else
        bSuccess = acquireCareerSkill()
    end

    refreshAdvancementState()

    return bSuccess
end
