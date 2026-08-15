--[[
    WFRP1E
    Pick Lock runtime context dialog

    The lock rating belongs to one test execution. It is deliberately not
    persisted on the Character or Skill.

    WFRP 1e Pick Lock procedure audited for #10M:
        - Pick Lock Skill is required to attempt the test;
        - base chance = Dexterity - Lock Rating;
        - Lock Rating is 0-100%;
        - repeated acquisitions add the already-verified +10% each after the
          first acquisition;
        - one attempt takes one round / 10 seconds;
        - after three failed attempts by the same character on the same lock,
          further attempts automatically fail.

    The final two procedure facts are reported as a chat reminder. #10M does
    not manufacture a persistent lock identity or failure counter.
]]

local nodeCharacter = nil
local sSelectedSkillRulesId = ""


local function deliverInputError(sText)
    Comm.deliverChatMessage({
        text = "[WFRP1E PICK LOCK] " .. tostring(sText or "Invalid input."),
        mode = "system"
    })
end


function onInit()
    roll_button.setText(
        "ROLL",
        "ROLL",
        "ROLL"
    )
end


function setContext(nodeChar, sRulesId)
    nodeCharacter = nodeChar
    sSelectedSkillRulesId = tostring(sRulesId or "")

    lock_rating.setValue(0)
end


function handleRoll()
    if not nodeCharacter then
        return false
    end

    local nLockRating =
        tonumber(
            lock_rating.getValue()
        )

    if not nLockRating
        or nLockRating < 0
        or nLockRating > 100
    then
        deliverInputError(
            "Lock Rating must be between 0% and 100%."
        )

        return false
    end

    local tResult =
        StandardTestManagerWFRP1E.performSelectedSkillTest(
            nodeCharacter,
            sSelectedSkillRulesId,
            "pickLock",
            {
                lockDifficulty = nLockRating
            }
        )

    if not tResult
        or tResult.launched ~= true
    then
        deliverInputError(
            "Unable to resolve the Pick Lock test from the supplied context."
        )

        return false
    end

    close()
    return true
end
