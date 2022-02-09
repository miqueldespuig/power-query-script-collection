let
    Function =
        (SrcTable as table, TransformTable as table) as table =>
            let
                // DEBUGGING VARIABLES
                // SrcTable = Vendes_Staging,

                // JDE Numeric data_type codes
                JdeNumeric = {
                    "7",
                    "9",
                    "15"
                },
                // JDE Text data_type codes
                JdeText = {
                    "1",
                    "2",
                    "17",
                    "20"
                },
                // JDE Date data_type codes
                JdeDate = {
                    "11",
                    "55"
                },
                // JDE Binary data_type codes
                JdeBinary = {
                    "18"
                },
                // Currency Classes
                JdeCurrencyClasses = {
                    "CURRENCY",
                    "AMT28D8",
                    "DWAMT"
                },
                fxNumericTransform = (factor as number) as function => (_) => _ * factor,
                fxTextTransform =
                    (_ as text) =>
                        let
                            TrimText = Text.Trim(_),
                            Clean = Text.Clean(TrimText)
                        in
                            Clean,
                fxJul2Greg =
                    (julian as number) as date =>
                        let
                            daycount = Number.Mod(1900000 + julian, 1000),
                            year = Number.RoundDown((1900000 + julian) / 1000),
                            greg1 = #date(year, 1, 1),
                            greg = Date.AddDays(greg1, daycount)
                        in
                            greg,
                // Transformation
                Schema = Table.Schema(SrcTable),
                SchemaSpecs =
                    Table.Join(
                        Table.SelectColumns(Schema, "Name"),
                        "Name",
                        TransformTable,
                        "sql_name",
                        JoinKind.Inner
                    ),
                #"Add fxTransform" =
                    Table.AddColumn(
                        SchemaSpecs,
                        "fx_transform",
                        each
                            if
                                List.Contains(
                                    JdeNumeric,
                                    [data_type_code]
                                )
                            then
                                fxNumericTransform([numeric_factor])
                            else if List.Contains(JdeText, [data_type_code]) then
                                fxTextTransform
                            else if
                                List.Contains(JdeDate, [data_type_code])
                                and [class_code]
                                <> "DATEG"
                            then
                                fxJul2Greg
                            else
                                (_) => _,
                        type function
                    ),
                #"Add TypeClaim" =
                    Table.AddColumn(
                        #"Add fxTransform",
                        "type_claim",
                        each
                            if
                                List.Contains(
                                    JdeNumeric,
                                    [data_type_code]
                                )
                                and List.Contains(
                                    JdeCurrencyClasses,
                                    [class_code]
                                )
                            then
                                Currency.Type
                            else if
                                List.Contains(
                                    JdeNumeric,
                                    [data_type_code]
                                )
                                and [numeric_factor]
                                = 1
                            then
                                Int64.Type
                            else if
                                List.Contains(
                                    JdeNumeric,
                                    [data_type_code]
                                )
                            then
                                Decimal.Type
                            else if List.Contains(JdeText, [data_type_code]) then
                                Text.Type
                            else if List.Contains(JdeDate, [data_type_code]) then
                                Date.Type
                            else
                                Any.Type
                    ),
                transform_ops = #"Add TypeClaim",
                #"Transform Table" =
                    Table.TransformColumns(
                        SrcTable,
                        List.Zip(
                            {
                                transform_ops[sql_name],
                                transform_ops[fx_transform],
                                transform_ops[type_claim]
                            }
                        )
                    )
            in
                #"Transform Table",
    FunctionType =
        type function (SrcTable as table, TransformTable as table) as table
        meta
        [
            Documentation.Author = "Miquel Despuig",
            Documentation.Version = "0.0.1", //MajorVersion|MinorVersion|Revision
            Documentation.Name = "fxTransformJDETable",
            Documentation.LongDescription = "Given a JD Edwards Data Dictionary encoded table <code>SrcTable</code> and a specification table <code>TransformTable</code> applies the necessary data transformations to translate to a human readable table."
        ],
    Ascribed =
        Value.ReplaceType(
            Function,
            FunctionType
        )
in
    Ascribed