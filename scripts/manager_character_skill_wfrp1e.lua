--[[
    WFRP1E
    Character Skill manager

    Owns operations which copy a Skill record onto a Character as one
    acquired Skill instance.

    Persistent Character data:

        skills.<id>.name
        skills.<id>.rulesId
        skills.<id>.specialisation
        skills.<id>.description
        skills.<id>.link

    Each acquisition receives its own unique child node. Duplicate rulesId
    values are deliberate because repeated acquisition is rules-significant
    for some WFRP 1e Skills.

    The owned Skill is a snapshot. Editing or deleting the source Skill later
    must not rewrite the Character's acquired instance. The source link is
    stored separately for normal Fantasy Grounds record navigation.
]]

function ensureSkills(nodeChar)
    if not nodeChar then
        return nil
    end

    return DB.createChild(
        nodeChar,
        "skills"
    )
end


local function copyDescription(
    nodeSkill,
    nodeOwnedSkill
)
    local nodeSourceDescription =
        DB.getChild(
            nodeSkill,
            "description"
        )

    local nodeOwnedDescription =
        DB.createChild(
            nodeOwnedSkill,
            "description",
            "formattedtext"
        )

    if not nodeOwnedDescription then
        return false
    end

    if not nodeSourceDescription then
        return true
    end

    return DB.copyNode(
        nodeSourceDescription,
        nodeOwnedDescription
    ) ~= nil
end


function acquireSkill(
    nodeChar,
    nodeSkill,
    sSkillClass,
    sSkillRecord
)
    if not nodeChar or not nodeSkill then
        return nil
    end

    if DB.isReadOnly(nodeChar) then
        return nil
    end

    -- Read the complete source snapshot before modifying Character data.

    local sName =
        DB.getValue(
            nodeSkill,
            "name",
            ""
        )

    local sRulesId =
        DB.getValue(
            nodeSkill,
            "rulesId",
            ""
        )

    local sSpecialisation =
        DB.getValue(
            nodeSkill,
            "specialisation",
            ""
        )

    local nodeSkills =
        ensureSkills(
            nodeChar
        )

    if not nodeSkills then
        return nil
    end

    -- Omitting the child name asks Fantasy Grounds to generate a unique
    -- database id. This intentionally permits repeated acquisitions.

    local nodeOwnedSkill =
        DB.createChild(
            nodeSkills
        )

    if not nodeOwnedSkill then
        return nil
    end

    DB.setValue(
        nodeOwnedSkill,
        "name",
        "string",
        tostring(sName or "")
    )

    DB.setValue(
        nodeOwnedSkill,
        "rulesId",
        "string",
        tostring(sRulesId or "")
    )

    DB.setValue(
        nodeOwnedSkill,
        "specialisation",
        "string",
        tostring(sSpecialisation or "")
    )

    if not copyDescription(
        nodeSkill,
        nodeOwnedSkill
    ) then
        DB.deleteNode(
            nodeOwnedSkill
        )

        return nil
    end

    sSkillClass =
        tostring(
            sSkillClass or "skill"
        )

    sSkillRecord =
        tostring(
            sSkillRecord or ""
        )

    if sSkillRecord == "" then
        sSkillRecord =
            DB.getPath(
                nodeSkill
            )
    end

    DB.setValue(
        nodeOwnedSkill,
        "link",
        "windowreference",
        sSkillClass,
        sSkillRecord
    )

    return nodeOwnedSkill
end
