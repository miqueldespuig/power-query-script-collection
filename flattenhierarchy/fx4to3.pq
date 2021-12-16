( SourceTable as table, NodeKey as text, ParentKey as text, optional NodeNameColumn as text, optional ParentNameColumn as text ) =>
let
    // VARIABLES, DEBUGGING
    // SourceTable = #"Llista De Materials",
    // NodeKey = "Component ID",
    // NodeName = "Component", // optional
    // ParentKey = "Article ID",
    // ParentName = "Article", // optional

    // MANAGE OPTIONAL PARAMETERS
    ParentName = if ParentNameColumn is null then "" else ParentNameColumn,
    NodeName = if NodeNameColumn is null then "" else NodeNameColumn,

    // FIND ROOT NODES

    // SelfJoin BOM4 Table from ParentKey to ChildKey with JoinKind.LeftAnti. This way we find ParentKeys that are NOT PRESENT in the NodeKey column.
    SelfJoin = Table.NestedJoin(
        SourceTable,
        ParentKey,
        SourceTable,
        NodeKey,
        "NODES.ROOT",
        JoinKind.LeftAnti
    ),

    // Found ParentKeyS are needed ONLY ONCE.
    RemoveDuplicateParents = Table.Distinct(SelfJoin),

    // Founded ParentKeyS MUST be added to the NodeKey column in order to have ALL NODES present in this column
    SelectParentKeys = Table.SelectColumns(
        RemoveDuplicateParents,
        { ParentKey, ParentName },
        MissingField.Ignore
    ),

    // ADD ROOT NODES TO THE NODE KEY LIST

    // Convert ParentKeyS and ParentNameS column names to NodeKey and NodeName column names to combine correctly with the base table
    ParentToNode = Table.RenameColumns(
        SelectParentKeys,
        {
            {ParentKey,NodeKey},
            {ParentName,NodeName}
        },
        MissingField.Ignore
    ),

    // Add the missing ParentKeyS to the NodeKey column. This NodeKeys will have null or blank as their ParentKey. All other columns with info will be null/blank to
    AddMissingParents = Table.Combine(
        {
            ParentToNode,
            SourceTable
        }
    ),

    // CLEANUP COLUMNS AND ORDER FOR RESULTS
    
    // Retrieve All Column Names from the Source Table
    SourceColumns = Table.ColumnNames( SourceTable ),

    // Keep Column Names not directly related with Parent-Child relationships
    SourceAdditionalColumns = List.RemoveItems( SourceColumns, {NodeKey,NodeName,ParentKey,ParentName} ),


    // Select the columns in the preferred order to be returned.
    KeepRelevantColumns = Table.SelectColumns(
        AddMissingParents,
        { NodeKey, NodeName, ParentKey } & SourceAdditionalColumns,
        MissingField.Ignore
    ),

    Return = KeepRelevantColumns

in
    Return