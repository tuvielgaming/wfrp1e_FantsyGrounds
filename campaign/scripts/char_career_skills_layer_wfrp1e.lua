--[[
    WFRP1E
    Character current-Career Skill offer binding layer

    This script layers on top of char_main_wfrp1e.lua.

    The source Career link remains the identity of the current Career.
    When that source changes, this layer creates one Character-owned
    snapshot of the Career's Skill offers and binds the visible list to it.

    Persistent paths:

        career.current.skillsSourceRecord
        career.current.skillsPath
        career.skillSnapshots.<id>.<offer>

    Existing snapshots are retained. Previously acquired Character Skills
    remain under character.skills and are never modified here.
]]

local sCurrentCareerLinkPath = nil


function onInit()
    if super and super.onInit then
        super.onInit()
    end

    local nodeChar = getDatabaseNode()

    if not nodeChar then
        return
    end

    sCurrentCareerLinkPath =
        DB.getPath(
            nodeChar,
            "career.current.link"
        )

    DB.addHandler(
        sCurrentCareerLinkPath,
        "onUpdate",
        onCurrentCareerLinkUpdated
    )

    bindCurrentCareerSkills()
end


function onClose()
    if sCurrentCareerLinkPath then
        DB.removeHandler(
            sCurrentCareerLinkPath,
            "onUpdate",
            onCurrentCareerLinkUpdated
        )
    end

    if super and super.onClose then
        super.onClose()
    end
end


function onCurrentCareerLinkUpdated()
    bindCurrentCareerSkills()
end


local function bindEmptySkillList(nodeChar)
    local nodeEmpty =
        DB.createChild(
            nodeChar,
            "career.current.emptySkillOffers"
        )

    if nodeEmpty then
        current_career_skills_list.setDatabaseNode(
            nodeEmpty
        )
    end
end


function bindCurrentCareerSkills()
    local nodeChar = getDatabaseNode()

    if not nodeChar then
        return
    end

    local _, sCareerRecord =
        DB.getValue(
            nodeChar,
            "career.current.link",
            "",
            ""
        )

    sCareerRecord = tostring(sCareerRecord or "")

    if sCareerRecord == "" then
        bindEmptySkillList(nodeChar)
        return
    end

    local sSnapshotSource =
        DB.getValue(
            nodeChar,
            "career.current.skillsSourceRecord",
            ""
        )

    local sSnapshotPath =
        DB.getValue(
            nodeChar,
            "career.current.skillsPath",
            ""
        )

    if sSnapshotSource == sCareerRecord
        and sSnapshotPath ~= ""
    then
        local nodeExistingSnapshot =
            DB.findNode(
                sSnapshotPath
            )

        if nodeExistingSnapshot then
            current_career_skills_list.setDatabaseNode(
                nodeExistingSnapshot
            )

            return
        end
    end

    local nodeCareer =
        DB.findNode(
            sCareerRecord
        )

    if not nodeCareer then
        bindEmptySkillList(nodeChar)
        return
    end

    local nodeSnapshots =
        DB.createChild(
            nodeChar,
            "career.skillSnapshots"
        )

    if not nodeSnapshots then
        bindEmptySkillList(nodeChar)
        return
    end

    local nodeSnapshot =
        DB.createChild(
            nodeSnapshots
        )

    if not nodeSnapshot then
        bindEmptySkillList(nodeChar)
        return
    end

    for _, nodeSourceOffer
        in ipairs(
            DB.getChildList(
                nodeCareer,
                "skills"
            )
        )
    do
        local nodeOffer =
            DB.createChild(
                nodeSnapshot
            )

        if nodeOffer then
            DB.copyNode(
                nodeSourceOffer,
                nodeOffer
            )

            DB.setValue(
                nodeOffer,
                "purchased",
                "number",
                0
            )
        end
    end

    DB.setValue(
        nodeChar,
        "career.current.skillsSourceRecord",
        "string",
        sCareerRecord
    )

    DB.setValue(
        nodeChar,
        "career.current.skillsPath",
        "string",
        DB.getPath(nodeSnapshot)
    )

    current_career_skills_list.setDatabaseNode(
        nodeSnapshot
    )
end
