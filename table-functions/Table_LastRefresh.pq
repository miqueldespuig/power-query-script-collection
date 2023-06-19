(
    SummerTimeOffset as number,
    WinterTimeOffset as number
) as datetimezone =>
    let
        // DST Offsets for Summer and Winter
        // SummerTimeOffset = 2,
        // WinterTimeOffset = 1,

        // Get Current UTC Date Time Zone
        UTCDateTimeZone = DateTimeZone.UtcNow(),
        // Get Current UTC Date Alone
        UTCDate = Date.From(UTCDateTimeZone),

        // Summer DST starts on at the last sunday of March
        // Winter DST starts at the last sunday of October

        // Calculate last sunday of March
        StartSummerTime = Date.StartOfWeek(
            #date(Date.Year(UTCDate),3,31),
            Day.Sunday
        ),
        // Calculate last sunday of October
        StartWinterTime = Date.StartOfWeek(
            #date(Date.Year(UTCDate),10,31),
            Day.Sunday
        ),
        // Calculate offset that needs to be applied
        Offset =
            if UTCDate >= StartSummerTime
            and UTCDate < StartWinterTime then
                SummerTimeOffset
            else
                WinterTimeOffset,
        // Switch from UTC datetime to the TimeZone provided
        LastRefresh = DateTimeZone.SwitchZone(
            UTCDateTimeZone,
            Offset
        )
    in
        LastRefresh
