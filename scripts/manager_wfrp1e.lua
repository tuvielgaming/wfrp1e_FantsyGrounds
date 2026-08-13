function onInit()
    print("WFRP1E | Initialization successful.")

    print(
        "WFRP1E | Characteristic registry loaded: "
        .. DataCommonWFRP1E.getCharacteristicCount()
    )


    -- Experience tests

    print(
        "WFRP1E | Characteristic advance XP cost: "
        .. CharacteristicManagerWFRP1E
            .getAdvanceExperienceCost()
    )

    print(
        "WFRP1E | XP available 350/100: "
        .. ExperienceManagerWFRP1E.calculateAvailable(
            350,
            100
        )
    )

    print(
        "WFRP1E | Can spend 100 from 350/100: "
        .. tostring(
            ExperienceManagerWFRP1E.canSpend(
                350,
                100,
                100
            )
        )
    )

    print(
        "WFRP1E | Can spend 300 from 350/100: "
        .. tostring(
            ExperienceManagerWFRP1E.canSpend(
                350,
                100,
                300
            )
        )
    )

    print(
        "WFRP1E | Invalid XP ledger 100/200: "
        .. tostring(
            ExperienceManagerWFRP1E.isValidLedger(
                100,
                200
            )
        )
    )


    -- Characteristic tests

    print(
        "WFRP1E | WS 32 + 1 advance: "
        .. CharacteristicManagerWFRP1E.calculateCurrent(
            "ws",
            32,
            1
        )
    )

    print(
        "WFRP1E | S 3 + 1 advance: "
        .. CharacteristicManagerWFRP1E.calculateCurrent(
            "s",
            3,
            1
        )
    )

    print(
        "WFRP1E | Purchase available 1/2: "
        .. tostring(
            CharacteristicManagerWFRP1E.canPurchaseAdvance(
                "ws",
                1,
                2
            )
        )
    )

    print(
        "WFRP1E | Previous advances 3/current career 1: "
        .. tostring(
            CharacteristicManagerWFRP1E.canPurchaseAdvance(
                "ws",
                3,
                1
            )
        )
    )


    -- Career Advance Scheme test

    local tTestAdvanceScheme =
        CareerManagerWFRP1E.createAdvanceScheme({
            ws = {
                steps = 2
            },
            s = {
                steps = 1
            },
            w = {
                steps = 2
            },
            i = {
                steps = 1
            }
        })

    if not tTestAdvanceScheme then
        print(
            "WFRP1E | ERROR: Unable to create test Advance Scheme."
        )

        return
    end

    print(
        "WFRP1E | Career WS amount: +"
        .. CareerManagerWFRP1E
            .calculateAdvanceSchemeAmount(
                tTestAdvanceScheme,
                "ws"
            )
    )

    print(
        "WFRP1E | Career S amount: +"
        .. CareerManagerWFRP1E
            .calculateAdvanceSchemeAmount(
                tTestAdvanceScheme,
                "s"
            )
    )
end