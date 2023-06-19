(src_table as table) =>
let
    #"Table Schema" = Table.Schema(src_table),
    #"Filtered Rows" =
        Table.SelectRows(
            #"Table Schema",
            each ([Kind] = "text")
        ),
    #"Removed Other Columns" =
        Table.SelectColumns(
            #"Filtered Rows",
            {"Name"}
        ),
    #"Add Column Function Pairs" =
        Table.AddColumn(
            #"Removed Other Columns",
            "Transformation Pair",
            each
                {
                    [Name],
                    Text.Trim
                }
        ),
    #"Keep Column Function Pairs" =
        Table.SelectColumns(
            #"Add Column Function Pairs",
            {"Transformation Pair"}
        ),
    #"Transformation List" =
        Table.Column(
            #"Keep Column Function Pairs",
            "Transformation Pair"
        ),
    #"Text Columns Trimmed" = Table.TransformColumns(src_table, #"Transformation List")
in
    #"Text Columns Trimmed"