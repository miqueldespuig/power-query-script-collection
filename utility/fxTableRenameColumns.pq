let
    Function =
        (SrcTable as table, RenameTable as table, optional NameColumn as text, optional NewNameColumn as text) as table =>
            let
                Name =
                    if NameColumn is null then
                        "Name"
                    else
                        NameColumn,
                NewName =
                    if NewNameColumn is null then
                        "NewName"
                    else
                        NewNameColumn,
                RenamedColumns =
                    Table.RenameColumns(
                        SrcTable,
                        List.Zip(
                            {
                                Table.Column(RenameTable, Name),
                                Table.Column(RenameTable, NewName)
                            }
                        ),
                        MissingField.Ignore
                    )
            in
                RenamedColumns,
    FunctionType =
        type function (SrcTable as table, RenameTable as table, optional NameColumn as text, optional NewNameColumn as text) as table
        meta
        [
            Documentation.Author = "Miquel Despuig",
            Documentation.Version = "0.0.1",
            Documentation.Name = "fxTableRenameColumns",
            Documentation.LongDescription = "Given a source table <code>SrcTable</code>, and a table <code>RenameTable</code> with at least two columns <bold>Name</bold> and <bold>NewName</bold> returns a table with all the columns found in the original table renamed. <code>RenameTable</code> any number of columns only the two mentioned columns will be used. If <code>RenameTable</code> has more than two columns or different names the opcional parameters <code>NameColumn</code> and <code>NewNameColumn</code> will be used as source rename operations."
        ],
    Ascribed =
        Value.ReplaceType(
            Function,
            FunctionType
        )
in
    Ascribed