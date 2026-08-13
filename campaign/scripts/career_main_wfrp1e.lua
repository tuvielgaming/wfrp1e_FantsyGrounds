--[[
    WFRP1E
    Career record controller

    Checkpoint #8B binds all fourteen Career Advance Scheme
    characteristic records to reusable column windows.
]]

local aBoundControls = {}


function onInit()
    local nodeCareer = getDatabaseNode()

    if not nodeCareer then
        print(
            "WFRP1E | ERROR: Career window has no database node."
        )

        return
    end

    if not CareerDBManagerWFRP1E.ensureAdvanceScheme(
        nodeCareer
    ) then
        print(
            "WFRP1E | ERROR: Unable to create Career Advance Scheme."
        )

        return
    end

    local aBindings = {
        {
            control = advance_m,
            id = "m"
        },
        {
            control = advance_ws,
            id = "ws"
        },
        {
            control = advance_bs,
            id = "bs"
        },
        {
            control = advance_s,
            id = "s"
        },
        {
            control = advance_t,
            id = "t"
        },
        {
            control = advance_w,
            id = "w"
        },
        {
            control = advance_i,
            id = "i"
        },
        {
            control = advance_a,
            id = "a"
        },
        {
            control = advance_dex,
            id = "dex"
        },
        {
            control = advance_ld,
            id = "ld"
        },
        {
            control = advance_int,
            id = "int"
        },
        {
            control = advance_cl,
            id = "cl"
        },
        {
            control = advance_wp,
            id = "wp"
        },
        {
            control = advance_fel,
            id = "fel"
        }
    }

    for _, rBinding in ipairs(aBindings) do
        bindAdvance(
            nodeCareer,
            rBinding.control,
            rBinding.id
        )
    end

    update()
end


function bindAdvance(
    nodeCareer,
    control,
    sCharacteristic
)
    local nodeCharacteristic =
        CareerDBManagerWFRP1E
            .getAdvanceSchemeCharacteristicNode(
                nodeCareer,
                sCharacteristic,
                true
            )

    if not nodeCharacteristic then
        print(
            "WFRP1E | ERROR: Unable to bind Career Advance Scheme: "
            .. tostring(sCharacteristic)
        )

        return
    end

    control.setValue(
        "wfrp1e_career_advance",
        DB.getPath(nodeCharacteristic)
    )

    table.insert(
        aBoundControls,
        control
    )
end


function update()
    local bReadOnly =
        WindowManager.getWindowReadOnlyState(
            self
        )

    for _, control in ipairs(aBoundControls) do
        if (
            control.subwindow
            and control.subwindow.onLockModeChanged
        ) then
            control.subwindow.onLockModeChanged(
                bReadOnly
            )
        end
    end
end