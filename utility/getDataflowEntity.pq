let
    Function =
        (WorkspaceId as text, DataflowId as text, EntityName as text) as table =>
            let 
                //DEBUGGING VARIABLES
                //WorkspaceId = WorkspaceId_DataDictionary,
                //DataflowId = DataflowId_DataDictionary,
                //EntityName = "column_rename",

                SrcData = PowerBI.Dataflows(),
                WorkspaceData = SrcData{[workspaceId = WorkspaceId]}[Data],
                DataflowData = WorkspaceData{[dataflowId = DataflowId]}[Data],
                DataflowEntity = DataflowData{[entity = EntityName]}[Data]
            in
                DataflowEntity,
    FunctionType =
        type function (WorkspaceId as text, DataflowId as text, EntityName as text) as table
        meta
        [
            Documentation.Author = "Miquel Despuig",
            Documentation.Version = "0.0.0", // MajorVersion|MinorVersion|Revision
            Documentation.Name = "getDataflowEntity",
            Documentation.LongDescription = "Returns a table with the data in the <code>EntityName</code> from the Workspace <code>WorkspaceId</code> and Dataflow <code>DataflowId</code>"
        ],
    Ascribed =
        Value.ReplaceType(
            Function,
            FunctionType
        )
in
    Ascribed