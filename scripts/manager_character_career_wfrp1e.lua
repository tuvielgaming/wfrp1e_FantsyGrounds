--[[
    WFRP1E
    Character Career manager

    Owns operations connecting a Character to a Career.

    Assigning a Career:

    - stores the Current Career identity
    - snapshots all fourteen Career Advance Scheme ceilings into
      characteristics.<id>.career

    Assigning a Career MUST NOT alter:

    - Starter Profile values
    - previously purchased advances
    - Current Profile values directly

    Current Profile remains derived from:

        initial + purchased * advanceStep

    A Character may legitimately have:

        purchased > career

    after changing to a Career with a lower Advance Scheme.
]]

function assignCareer(
    nodeChar,
    nodeCareer,
    sCareerClass,
    sCareerRecord
)
    if not nodeChar then
        return false
    end

    if not nodeCareer then
        return false
    end

    local tAdvanceScheme =
        CareerDBManagerWFRP1E.readAdvanceScheme(
            nodeCareer
        )

    if not tAdvanceScheme then
        return false
    end

    -- Validate the complete source before modifying Character data.

    local tCareerSteps = {}

    for _, sCharacteristic
        in ipairs(
            DataCommonWFRP1E.getCharacteristics()
        )
    do
        local nSteps =
            CareerManagerWFRP1E.getAdvanceSchemeSteps(
                tAdvanceScheme,
                sCharacteristic
            )

        if nSteps == nil then
            return false
        end

        tCareerSteps[sCharacteristic] = nSteps
    end


    -- Snapshot all fourteen current Career ceilings.
    --
    -- Zero values are deliberately written as well so values belonging
    -- to the previous Career cannot survive accidentally.

    for _, sCharacteristic
        in ipairs(
            DataCommonWFRP1E.getCharacteristics()
        )
    do
        DB.setValue(
            nodeChar,
            "characteristics."
                .. sCharacteristic
                .. ".career",
            "number",
            tCareerSteps[sCharacteristic]
        )
    end


    -- Preserve human-readable Career identity independently from the
    -- source link. The snapshot above remains valid even if the source
    -- record later becomes unavailable.

    local sCareerName =
        DB.getValue(
            nodeCareer,
            "name",
            ""
        )

    DB.setValue(
        nodeChar,
        "career.current.name",
        "string",
        sCareerName
    )


    -- Preserve a normal Fantasy Grounds record reference to the source
    -- Career when one was supplied.

    sCareerClass =
        tostring(
            sCareerClass or ""
        )

    sCareerRecord =
        tostring(
            sCareerRecord or ""
        )

    if sCareerRecord == "" then
        sCareerRecord =
            DB.getPath(
                nodeCareer
            )
    end

    DB.setValue(
        nodeChar,
        "career.current.link",
        "windowreference",
        sCareerClass,
        sCareerRecord
    )

    return true
end