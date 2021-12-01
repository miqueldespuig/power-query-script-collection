( HierarchyTable as table, NodeKey as text, NodeName as text, ParentKey as text ) =>
let
    // Column Name Generator. Function used continuously to generate a nice name for NodeKey and NodeName columns. Column name pattern = NodeKey_### or NodeName_### where ### = Level left padded to 0's
    fxNameGenerator =
        ( columnname as text , level as number ) as text =>
            columnname
            & "_"
            & Text.PadStart( Number.ToText(level), 3, "0" ),

    // Variables / Debugging. These lines allow you to hard code variables for debugging or understanding purposes
    //HierarchyTable = Hierarchy3Col,
    //NodeKey = "NodeKey",
    //NodeName = "NodeName",
    //ParentKey = "ParentKey",

    // Hard Coded Variables, used for safe looping and standard start level.
    STARTLEVEL = 1,
    MAXITERATIONS = 998,

    // Search Root Nodes = Find which nodes do not have a ParentKey, which means ParentKey = null (for numbers) or blank (for text)
    RootNodes = Table.SelectRows(
        HierarchyTable,
        each List.Contains ( { null, "" }, Record.Field( _, ParentKey ) )
    ),

    // Seed. Prepare the initial table which will have column names according to the pattern NodeX_### for StartLevel
    Seed = Table.AddColumn(
        Table.TransformColumnNames(
            Table.SelectColumns(
                RootNodes,
                {NodeKey, NodeName}
            ),
            (col) => fxNameGenerator(col,STARTLEVEL)
        ),
        "NodeDepth",
        each STARTLEVEL,
        Int64.Type
    ),

    // List.Generate Design. Each function used in the List.Generate call.

    // initial as function, provide an initial expression from where to iterate. We use the Seed table and Level value to add the NodeDepth column
    fxInitial = ()=> [Nodes = Seed, Level = STARTLEVEL ],

    // condition as function, provide a function that return true if the iterations are meant to continue. 
    fxCondition = each not Table.IsEmpty(_[Nodes]) and _[Level] < MAXITERATIONS,

    // next as function, for each previous execution, pick the result and execute these steps. FindChilds, for each current Node find the nodes that are children of it. Expand & NodeDepth, prepare table for result and next iteration.
    fxNext = each 
        let
            FindChilds = Table.NestedJoin(
                Table.RemoveColumns(_[Nodes], "NodeDepth"), { fxNameGenerator( NodeKey, _[Level] ) },
                HierarchyTable, { ParentKey },
                "CHILD.NODES",
                JoinKind.Inner
            ),
            
            ExpandAndRename = Table.ExpandTableColumn(
                FindChilds,
                "CHILD.NODES", {NodeKey, NodeName},
                {fxNameGenerator(NodeKey,_[Level]+1), fxNameGenerator(NodeName,_[Level]+1)}
            ),

            AddNodeDepth = Table.AddColumn(
                ExpandAndRename,
                "NodeDepth",
                (row) => _[Level] + 1,
                Int64.Type
            ),
            
            NewChilds = [
                Nodes = AddNodeDepth,
                Level = _[Level] + 1
            ]
        in
            NewChilds,
    
    // selector as function. Function to keep only part of the results if needed. In this case the level is already in a column so we don't need it in the results.
    fxSelector = each _[Nodes],

    // Flattened table, all the columns needed on the dimension to work with a flattened hierarchy. We rely on that Table.Combine will automatically add columns to the tables.
    Flat = Table.Combine(
        List.Generate(
            fxInitial,
            fxCondition,
            fxNext,
            fxSelector
        )
    ),

    // Calculate NodeID and Path. For each record (line) of the Flat Table gather all the column IDs of child nodes and combine them as the Path. Also keep the last two items as ID and Name of the node represented in the list.
    #"NodeID and Path Calculation" = Table.AddColumn(
        Flat, "NODE+PATH",
        each
            let 
                #"Delete Node Depth" = Record.RemoveFields (_, "NodeDepth"),
                #"Path List ID,Name" = List.Select(Record.ToList( #"Delete Node Depth" ), each _ <> null ),
                #"Select PathIDs ToText" = List.Transform( List.Select ( #"Path List ID,Name", each Number.Mod ( List.PositionOf ( #"Path List ID,Name", _ ) , 2 ) = 0 ), Text.From ),
                #"Node Path" = Text.Combine ( #"Select PathIDs ToText", " > " ),
                #"Node ID,Name" = List.LastN ( #"Path List ID,Name", 2 ),
                #"Node Record" = Record.FromList( #"Node ID,Name", { "Node_ID", "Node_Name" }),
                #"Node And Path Record" = Record.AddField ( #"Node Record", "Path", #"Node Path")
            in
                #"Node And Path Record"
    ),
    
    // Cleanup step
    #"Expanded NODE+PATH" = Table.ExpandRecordColumn(#"NodeID and Path Calculation", "NODE+PATH", {"Node_ID", "Node_Name", "Path"}),

    // Is Leaf. Leaf is a node with no children. It's the same as find which nodes are not in the parent list
    #"Is Leaf Calculation" = Table.AddColumn(
        #"Expanded NODE+PATH", "IsLeaf",
        each
            let
                ParentKeys = List.Buffer ( List.Distinct ( Table.Column( HierarchyTable, ParentKey ) ) ),
                LeafCheck = not List.Contains( ParentKeys, Record.Field( _, "Node_ID" ) )
            in
            LeafCheck
        , type logical ),
    
    // Gather the names of the NodeKey columns, will be used to back-fill null values
    NodeKeyColumns = List.Buffer( List.Select( Table.ColumnNames (#"Is Leaf Calculation" ), each Text.StartsWith(_, NodeKey) ) ),

    // Gater the names of the NodeName columns, will be used to back-fill null values
    NodeNameColumns = List.Buffer( List.Select( Table.ColumnNames (#"Is Leaf Calculation" ), each Text.StartsWith(_, NodeName) ) ),

    // BackFillRecord as function, pulls a record (line) of the flat table, converts to table in correct order to downfill, the combines the record taking advantage that record combination will replace fields with null value with same name fields with some value.
    fxBackFillRecord =
    ( r as record ) =>
        let
            SelectFields = Record.SelectFields(r, NodeKeyColumns & NodeNameColumns),
            BackFill = Table.FillDown( Record.ToTable( SelectFields ), {"Value"} ),
            NewValues = Record.FromTable ( BackFill ),
            NewRecord = Record.Combine( { r, NewValues } )
        in
            NewRecord,

    // Transform the rows with all information back-filling when necessary
    BackFill = Table.FromRecords(
        Table.TransformRows (
            #"Is Leaf Calculation",
            fxBackFillRecord
        )
    )
in
    BackFillmatmat