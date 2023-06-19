let
    Function = (juldate as any) as date =>
        let
            juldatenumber = Number.From(juldate),
            jdayscount = Number.Mod(1900000 + juldatenumber, 1000) - 1,
            jyear = Number.RoundDown((1900000 + juldatenumber) / 1000),
            gregbasedate = #date(jyear, 1, 1),
            gregdate = Date.AddDays(gregbasedate, jdayscount)
        in
            gregdate,

    FunctionType = type function (
        juldate as (
            type any meta [
                Documentation.FieldCaption = "Julian Date Value",
                Documentation.LongDescripcion = "The value in type text or integer of a julian date"
            ]
        )
    ) as date meta [
        Documentation.Name = "Julian Date To Gregorian Date",
        Documentation.LongDescription = "Given an Oracle JD Edwards Julian date converts it to a Gregorian Calendar format"
    ],
    fxDateConvertToGregorian = Value.ReplaceType(Function, FunctionType)
in
    fxDateConvertToGregorian