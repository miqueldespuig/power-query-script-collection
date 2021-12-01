(SourceTable as table, NodeKey as text, NodeName as text, ParentKey as text, ParentName as text) as table =>
    let
        // Variables / Debugging. 
        // SourceTable = #"4ColumnBOM",
        // NodeKey = "NodeKey",
        // NodeName = "NodeName",
        // ParentKey = "ParentKey",
        // ParentName = "ParentName",

        // Finding Root Nodes
        RootNodes =
            Table.RenameColumns(
                Table.Distinct(
                    Table.SelectColumns(
                        Table.NestedJoin(
                            SourceTable,{"ParentKey"},
                            SourceTable,{"NodeKey"},
                            "ROOT.NODES",
                            JoinKind.LeftAnti
                        ),
                        { ParentKey, ParentName }
                    )
                ),
                {
                    { ParentKey, NodeKey },
                    { ParentName, NodeName }
                }
            ),

        Hiearchy =
            Table.Combine(
                {
                    Table.SelectColumns(
                        SourceTable,
                        { "NodeKey", "NodeName", "ParentKey" }
                    ),
                    RootNodes
                }
            )
    in
        Hiearchy