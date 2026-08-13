--[[
    WFRP1E
    Record type registration

    Registers WFRP1E-specific campaign record types with CoreRPG.

    Career records use:

        career
        reference.careers

    Skill records use:

        skill
        reference.skills

    Campaign paths contain editable campaign records.
    Reference paths are reserved for module/reference records later.
]]

function onInit()
    registerCareerRecordType()
    registerSkillRecordType()
end


function registerCareerRecordType()
    RecordDataManager.setRecordTypeData(
        "career",
        {
            aDataMap = {
                "career",
                "reference.careers"
            },

            sSidebarCategory = "create"
        }
    )

    -- Normally this script initializes before CoreRPG builds the
    -- record registry/sidebar. The following also makes registration
    -- safe if initialization order changes later.
    if RecordDataManager.isInitialized() then
        RecordDataManager.initRecordType(
            "career"
        )

        if DesktopManager.isInitialized() then
            DesktopManager.rebuildSidebar()
        end
    end
end


function registerSkillRecordType()
    RecordDataManager.setRecordTypeData(
        "skill",
        {
            aDataMap = {
                "skill",
                "reference.skills"
            },

            sSidebarCategory = "create"
        }
    )

    -- Keep Skill registration safe under the same late-init case as
    -- Career registration above.
    if RecordDataManager.isInitialized() then
        RecordDataManager.initRecordType(
            "skill"
        )

        if DesktopManager.isInitialized() then
            DesktopManager.rebuildSidebar()
        end
    end
end
