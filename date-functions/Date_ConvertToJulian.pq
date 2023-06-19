let
    Function = (gregdate as date) as number =>
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
    // DOCUMENTATION
    FunctionType = type function (gregdate as
            (
                type date
                meta
                [
                    Documentation.FieldCaption = "Date",
                    Documentation.LongDescripcion = "The value in type date of a gregorian date"
                ]
            )) as date
        meta
        [
            Documentation.Author = "Miquel Despuig",
            Documentation.Version = "1.0.1", //MajorVersion|MinorVersion|Revision
            Documentation.Name = "fxTransformJDETable",
            Documentation.LongDescription = "Given gregorian calendar date converts it to a JD Edwards julian date format"
        ],
    fxJul2Greg = Value.ReplaceType(Function, FunctionType)
in
    fxJul2Greg
  