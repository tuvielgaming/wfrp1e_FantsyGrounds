--[[
    WFRP1E
    Audited Standard Test Skill effects

    Mechanics authority:
        WFRP 1e Core Rulebook Skills and Standard Tests sections.

    This file describes what an explicitly selected owned Skill contributes to
    a named Standard Test. It does NOT decide whether the Skill is relevant in
    the current fictional situation; that decision remains with the GM/player.

    The generic Standard Test manager consumes only the simple fixed and
    repeated-acquisition effects it already understands. Choice-based effects
    remain explicit data and are consumed only by their dedicated audited
    context resolver; they are never silently approximated as a fixed bonus.

    Important WFRP 1e distinction:
        There is no universal "owned Skill = +10%" rule.

        Pick Lock / Pick Pocket use additional acquisitions for +10% each.
        Their first acquisition therefore contributes +0% through this effect;
        other rules determine whether the Skill gates an attempt or removes an
        unskilled penalty.

        Bribery is explicitly +20% to Bribe tests. The Bribe test's separate
        target-Will-Power formula and situational/procedure modifiers are not
        encoded as Skill effects here.

        Hide keeps its selected Skill effects distinct:
        - Shadowing contributes +10%;
        - appropriate Rural/Urban Concealment contributes +20% while stationary
          or +5% while moving cautiously;
        - Silent Move is not a Hide modifier; it belongs to its own procedures.
]]

local tEffects = {
    bribery = {
        bribe = {
            type = "fixed",
            value = 20
        }
    },

    charm = {
        bargain = {
            type = "fixed",
            value = 10
        },
        bluff = {
            type = "fixed",
            value = 10
        },
        gossip = {
            type = "fixed",
            value = 10
        }
    },

    concealmentRural = {
        hide = {
            type = "choice",
            condition = "rural-environment",
            choices = {
                stationary = 20,
                cautiousMovement = 5
            }
        }
    },

    concealmentUrban = {
        hide = {
            type = "choice",
            condition = "urban-environment",
            choices = {
                stationary = 20,
                cautiousMovement = 5
            }
        }
    },

    haggle = {
        bargain = {
            type = "fixed",
            value = 10
        }
    },

    immunityToDisease = {
        disease = {
            type = "fixed",
            value = 10
        }
    },

    immunityToPoison = {
        poison = {
            type = "fixed",
            value = 10
        }
    },

    linguistics = {
        understandLanguage = {
            type = "fixed",
            value = 10
        }
    },

    pickLock = {
        pickLock = {
            type = "repeated-acquisition"
        }
    },

    pickPocket = {
        pickPocket = {
            type = "repeated-acquisition"
        }
    },

    shadowing = {
        hide = {
            type = "fixed",
            value = 10
        }
    },

    superNumerate = {
        estimate = {
            type = "fixed",
            value = 20
        },
        gamble = {
            type = "fixed",
            value = 10
        }
    },

    wit = {
        bluff = {
            type = "fixed",
            value = 10
        },
        gossip = {
            type = "fixed",
            value = 10
        }
    }
}


local function normalizeId(sValue)
    return tostring(
        sValue or ""
    ):match(
        "^%s*(.-)%s*$"
    )
end


function getEffect(
    sRulesId,
    sTestId
)
    local sSkill =
        normalizeId(
            sRulesId
        )

    local sTest =
        normalizeId(
            sTestId
        )

    if sSkill == "" or sTest == "" then
        return nil
    end

    local tSkillEffects =
        tEffects[
            sSkill
        ]

    if not tSkillEffects then
        return nil
    end

    return tSkillEffects[
        sTest
    ]
end
