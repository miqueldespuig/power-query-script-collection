let
    getDataflowEntity = 
    (WorkspaceId as text, DataflowId as text, optional EntityName as text) =>
        let
            Source = PowerBI.Dataflows(null),
            Workspace = Source{[workspaceId=WorkspaceId]}[Data],
            Dataflow = Workspace{[dataflowId=DataflowId]}[Data],
            Entity = if EntityName = null then Dataflow else Dataflow{[entity=EntityName]}[Data]
        in
            Entity,
    Documentation = type function (WorkspaceId as text, DataflowId as text, optional EntityName as text) as table
        meta
        [
            Documentation.Author = "Miquel Despuig",
            Documentation.Version = "0.1.0", // MajorVersion|MinorVersion|Revision
            Documentation.Date = "2022-05-03",
            Documentation.Name = "getDataflowEntity",
            Documentation.Description = "Given a <code>WorkspaceId</code> and a <code>DataflowId</code> and an optional <code>EntityName</code> returns either a table with a list of entities in the specified dataflow or a table with the data in the <code>EntityName</code>"
        ],
  Ascribed = Value.ReplaceType(getDataflowEntity, Documentation)
in
  Ascribed