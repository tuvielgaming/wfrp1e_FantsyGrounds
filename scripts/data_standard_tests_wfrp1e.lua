--[[
    WFRP1E
    Named Standard Test data foundation

    Mechanics authority:
        WFRP 1e Core Rulebook, Standard Tests / Standardowe Testy.

    This registry is deliberately descriptive, not executable.

    It provides stable language-neutral test identities and the audited base
    contract needed by later Standard Test work:

        characteristic   direct percentage-characteristic base
        formula          formula/situational base requiring later resolution
        skills           potentially relevant Skill rulesIds
        defaultModifier  modifier inherent to the named test definition
        tags             runtime requirements / audit metadata

    The Skill list is candidate metadata only. The Core Rulebook explicitly
    leaves actual Skill applicability to the GM; no Skill is automatically
    applied by this module.

    Procedure-heavy Standard Tests which do not yet fit this small data
    contract are intentionally not registered here. They require dedicated,
    audited execution contracts in later checkpoints.
]]

local tNamedStandardTests = {
    animosity = { characteristic = "cl" },
    bargain = { characteristic = "fel", skills = { "charm", "haggle", "seduction" } },
    bluff = { characteristic = "fel", skills = { "acting", "charm", "clown", "jester", "publicSpeaking", "seduction", "wit" } },
    bribe = { formula = "100 - target.wp", skills = { "bribery" }, tags = { "requires-target" } },
    construct = { characteristic = "dex", skills = { "boatBuilding", "carpentry", "engineer", "mining", "smithing", "stoneworking" } },
    disease = { formula = "t * 10", skills = { "immunityToDisease" } },
    estimate = { characteristic = "int", skills = { "evaluate", "followTrail", "superNumerate" } },
    fear = { characteristic = "cl" },
    frenzy = { characteristic = "cl" },
    gossip = { characteristic = "fel", skills = { "acting", "bribery", "charm", "comedian", "publicSpeaking", "seduction", "storyTelling", "wit" } },
    hatred = { characteristic = "cl" },
    hide = { formula = "i + cl - target.i", skills = { "concealmentRural", "concealmentUrban", "shadowing" }, tags = { "requires-target" } },
    hypnotism = { characteristic = "wp" },
    interrogate = { characteristic = "wp", skills = { "torture" } },
    listen = { formula = "noise", skills = { "acuteHearing", "silentMoveRural", "silentMoveUrban" }, tags = { "requires-noise-level" } },
    loyalty = { characteristic = "ld", skills = { "bribery" } },
    magic = { characteristic = "wp" },
    observe = { characteristic = "i" },
    pickLock = { formula = "dex - lockDifficulty", skills = { "pickLock" }, tags = { "requires-lock-rating" } },
    pickPocket = { characteristic = "dex", skills = { "pickPocket" } },
    poison = { formula = "t * 10", skills = { "immunityToPoison" } },
    problemSolving = { characteristic = "int" },
    reaction = { characteristic = "i" },
    risk = { formula = "50", tags = { "situational-skills" } },
    search = { characteristic = "i" },
    searchRapid = { characteristic = "i", defaultModifier = -10, tags = { "rapid-search" } },
    strength = { formula = "s * 10" },
    stupidity = { characteristic = "int" },
    terror = { characteristic = "cl" },
    understandLanguage = { characteristic = "int", skills = { "linguistics" } }
}

local function copyArray(aSource)
    local aCopy = {}
    for _, v in ipairs(aSource or {}) do
        table.insert(aCopy, v)
    end
    return aCopy
end

local function normalizedId(sValue)
    return tostring(sValue or "")
end

local function definitionContainsSkill(tDefinition, sRulesId)
    for _, sCandidateRulesId in ipairs(tDefinition.skills or {}) do
        if sCandidateRulesId == sRulesId then
            return true
        end
    end
    return false
end

function getNamedStandardTestDefinition(sTestId)
    local sId = normalizedId(sTestId)
    local tSource = tNamedStandardTests[sId]
    if not tSource then
        return nil
    end

    return {
        id = sId,
        characteristic = tSource.characteristic,
        formula = tSource.formula,
        skills = copyArray(tSource.skills),
        defaultModifier = tonumber(tSource.defaultModifier) or 0,
        tags = copyArray(tSource.tags)
    }
end

function getNamedStandardTestIds()
    local aIds = {}
    for sTestId, _ in pairs(tNamedStandardTests) do
        table.insert(aIds, sTestId)
    end
    table.sort(aIds)
    return aIds
end

function isPotentialSkillForTest(sTestId, sRulesId)
    local tDefinition = tNamedStandardTests[normalizedId(sTestId)]
    if not tDefinition then
        return false
    end

    sRulesId = normalizedId(sRulesId)
    if sRulesId == "" then
        return false
    end

    return definitionContainsSkill(tDefinition, sRulesId)
end

function getPotentialStandardTestsForSkill(sRulesId)
    sRulesId = normalizedId(sRulesId)
    if sRulesId == "" then
        return {}
    end

    local aTestIds = {}
    for sTestId, tDefinition in pairs(tNamedStandardTests) do
        if definitionContainsSkill(tDefinition, sRulesId) then
            table.insert(aTestIds, sTestId)
        end
    end
    table.sort(aTestIds)
    return aTestIds
end
