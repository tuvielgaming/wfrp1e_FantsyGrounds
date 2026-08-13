--[[
    WFRP1E
    Record type registration

    Registers WFRP1E-specific campaign record types with CoreRPG.

    Career records use:

        career
        reference.careers

    The campaign path contains editable campaign Careers.
    The reference path is reserved for module/reference Careers later.
]]

function onInit()
    registerCareerRecordType()
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