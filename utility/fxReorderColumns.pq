let
    Function =
        (data as table, columnsToOrderLeft as list, optional columnsToOrderRight as list) as table =>
            let
                CurrentOrder = Table.ColumnNames(data),
                ReorderLeft = columnsToOrderLeft,
                ReorderRight = columnsToOrderRight ?? {},
                OrderedColumnsRemoved =
                    List.RemoveItems(
                        CurrentOrder,
                        ReorderLeft & ReorderRight
                    ),
                NewOrdering =
                    ReorderLeft
                    & OrderedColumnsRemoved
                    & ReorderRight,
                Reordered = Table.ReorderColumns(data, NewOrdering)
            in
                Reordered,
    FunctionType =
        type function (data as table, columnsToOrderLeft as (type {text}), optional columnsToOrderRight as (type {text})) as table
        meta
        [
            Documentation.Author = "Ben Gribaudo",
            Documentation.Version = "1",
            Documentation.Source = "https://bengribaudo.com/blog/2021/10/04/6289/resilient-relative-column-reordering",
            Documentation.Name = "TableRelativeReorderColumns",
            Documentation.LongDescription = "Returns a table from the input <code>table</code>, with the columns in <code>columnsToOrderLeft</code> appearing leftmost in the order given and the columns in <code>columnsToOrderRight</code> appearing rightmost in the order given. Other columns will not be reordered."
        ],
    Ascribed =
        Value.ReplaceType(
            Function,
            FunctionType
        )
in
    Ascribed