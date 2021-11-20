/* 
fxGreg2Jul, takes a date in gregorian format and converts it into JD Edwards Julian integer format
*/
let
    g2j =
        (gregdate as date) as number =>
            let
                juliandate =
                    Number.From(
                        Text.From(Date.Year(gregdate))
                        & Text.PadStart(
                            Text.From(Date.DayOfYear(gregdate)),
                            3,
                            "0"
                        )
                    )
                    - 1900000
            in
                juliandate,
    //DOCUMENTATION
    g2jType =
        type function (gregdate as
            (
                type date
                meta
                [
                    Documentation.FieldCaption = "Gregorian Date",
                    Documentation.LongDescripcion = "The value in type date of a gregorian date"
                ]
            )) as date
        meta
        [
            Documentation.Name = "Gregorian Date To Julian Date",
            Documentation.LongDescription = "Given gregorian calendar date converts it to a JD Edwards julian date format"
        ]
in
    Value.ReplaceType(g2j, g2jType)