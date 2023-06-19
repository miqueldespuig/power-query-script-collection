( HierarchyTable as table, NodeKey as text, NodeName as text, ParentKey as text ) =>
    let

        // CONSTANTS
        STARTLEVEL = 0,
        MAX_ITERATIONS = 999,

        // VARIABLES / DEBUGGING
        // HierarchyTable = tbl_hierarchy_infiniteloop,
        // NodeKey = "NodeKey",
        // ParentKey = "ParentKey",
        // NodeName = "NodeName",
        ComputeLoopNodes = false,

        // FUNCTIONS
        fxNameGenerator = ( name as text ) as function =>
            ( level as number ) as text =>
                name & "_" & Text.PadStart ( Number.ToText ( level ), 3, "0" ),
        GenerateName.NodeKey = fxNameGenerator ( NodeKey ),
        GenerateName.NodeName = fxNameGenerator ( NodeName ),
        Record.TagRecursive = ( r as record ) as logical =>
            let
                NodeKey_Names = List.Select (
                    Record.FieldNames ( r ),
                    each Text.StartsWith ( _, NodeKey )
                ),
                NodeKey_Values = Record.SelectFields ( r, NodeKey_Names ),
                NodeKey_Values_List = Record.ToList ( NodeKey_Values ),
                CurrentPath = List.RemoveLastN ( NodeKey_Values_List ),
                CurrentNode = List.Last ( NodeKey_Values_List ),
                IsLoop = List.Contains ( CurrentPath, CurrentNode )
            in
                IsLoop,

        // initial as function, function that generates the starting point. Usually without parameters.
        initial = () =>
            let
                RootNodes = Table.AddColumn (
                    Table.RenameColumns (
                        Table.SelectColumns (
                            Table.SelectRows (
                                HierarchyTable,
                                each List.Contains ( { null, "" }, Record.Field ( _, ParentKey ) )
                            ),
                            { NodeKey, NodeName }
                        ),
                        {
                            { NodeKey, GenerateName.NodeKey ( STARTLEVEL ) },
                            { NodeName, GenerateName.NodeName ( STARTLEVEL ) }
                        }
                    ),
                    "IsLoop",
                    Record.TagRecursive
                ),
                Level = STARTLEVEL + 1
            in
                [
                    Nodes     = RootNodes,
                    Level     = STARTLEVEL + 1,
                    LoopNodes = #table ( Table.ColumnNames ( RootNodes ), {} )
                ],

        // condition as function
        condition = ( _ ) => not Table.IsEmpty ( [Nodes] ) and [Level] < MAX_ITERATIONS,

        // next as function
        next = ( _ ) =>
            let
                #"SelfJoin" = Table.NestedJoin (
                    Table.RemoveColumns ( [Nodes], "IsLoop", MissingField.Ignore ),
                    GenerateName.NodeKey ( [Level] - 1 ),
                    HierarchyTable,
                    ParentKey,
                    "CHILD.NODES",
                    JoinKind.Inner
                ),
                #"Expand NodeKey,NodeName" = Table.ExpandTableColumn (
                    #"SelfJoin",
                    "CHILD.NODES",
                    { NodeKey, NodeName },
                    { GenerateName.NodeKey ( [Level] ), GenerateName.NodeName ( [Level] ) }
                ),
                #"Tagging Recursive Node" = Table.AddColumn (
                    #"Expand NodeKey,NodeName",
                    "IsLoop",
                    Record.TagRecursive
                ),
                #"Partition By Recursive" = Table.Partition (
                    #"Tagging Recursive Node",
                    "IsLoop",
                    2,
                    Number.From
                ),
                #"Result" = [
                    Nodes     = #"Partition By Recursive"{0},
                    Level     = [Level] + 1,
                    LoopNodes = #"Partition By Recursive"{1}
                ]
            in
                #"Result",

        // selector as function
        selector = (_)=> [Nodes],

        // Execute List.Generate and combine steps
        Flat = Table.Combine ( List.Generate ( initial, condition, next, selector ) ),

        NodeKey_Columns = List.Buffer (
            List.Select (
                Table.ColumnNames ( Flat ),
                each Text.StartsWith ( _, NodeKey ) )
        ),

        NodeName_Columns = List.Buffer (
            List.Select (
                Table.ColumnNames ( Flat ),
                each Text.StartsWith ( _, NodeName ) )
        ),

        Parent_Keys = List.Buffer ( Table.Column ( HierarchyTable, ParentKey ) ),

        Descriptors = Table.AddColumn (
            Flat,
            "Descriptors",
            each
                let
                    NodeKey_Values = Record.FieldValues (
                        Record.SelectFields ( _, NodeKey_Columns )
                    ),
                    CurrentPath_List = List.Select ( ( NodeKey_Values ), ( li ) => li <> null ),
                    Level = List.Count ( CurrentPath_List ),
                    NodeID = List.Last ( CurrentPath_List ),
                    Path = Text.Combine ( List.Transform ( CurrentPath_List, Text.From ), " > " ),
                    IsLeaf = not List.Contains ( Parent_Keys, NodeID )
                in
                    [ Node_Depth = Level, Node_ID = NodeID, Path = Path, IsLeaf = IsLeaf ]
        ),

        ExpandDescriptors = Table.ExpandRecordColumn (
            Descriptors,
            "Descriptors",
            { "Node_Depth", "Node_ID", "Path", "IsLeaf" }
        ),

        Record.BackFill = ( r as record, columns as list ) =>
            let
                SelectFields = Record.SelectFields ( r, columns ),
                BackFill     = Table.FillDown ( Record.ToTable ( SelectFields ), { "Value" } ),
                NewValues    = Record.FromTable ( BackFill ),
                NewRecord    = Record.Combine ( { r, NewValues } )
            in
                NewRecord,
        
        BackFill = Table.FromRecords (
            Table.TransformRows (
                ExpandDescriptors,
                each Record.BackFill ( _, NodeKey_Columns & NodeName_Columns )
            )
        )
    in
        BackFill