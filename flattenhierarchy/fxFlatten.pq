/*
fxFlatten
// VARIABLES
BomTable = Table containing al least 3 columns. NodeKey, ParentKey and NodeName
NodeKey (text) = Name of the column containg NODE or CHILDREN primary keys
ParentKey (text) = Name of the column containing PARENT primary keys
NodeName (text) = Name of the column containing DESCRIPTIONS for the nodes
//  PROCESS
1 FIND PARENT ITEMS
*/
/*
fxFlatten
// VARIABLES
BomTable = Table containing al least 3 columns. NodeKey, ParentKey and NodeName
NodeKey (text) = Name of the column containg NODE or CHILDREN primary keys
ParentKey (text) = Name of the column containing PARENT primary keys
NodeName (text) = Name of the column containing DESCRIPTIONS for the nodes
//  PROCESS
1 FIND PARENT ITEMS
*/
let 
    //VARIABLES

    // Name of the Hierarchy Table in 4 column format
    BomTable = #"BomTable 4 Column",
    // Name of the column containing Node keys or Children Keys
    NodeKey = "NodeKey",
    // Name of the column containing Node Names or Children Names
    NodeName = "NodeName",
    // Name of the column containing Parent keys
    ParentKey = "ParentKey",
    // Name of the column containing Parent names
    ParentName = "ParentName",
    // Maximum number of levels
    MaxLevel = 7,

    // FIND ROOT NODES = Parent Keys not found in Node Keys must be root nodes
    #"Root Nodes" = Table.Distinct(
        Table.SelectColumns(
            Table.NestedJoin(
                BomTable,
                ParentKey,
                BomTable,
                NodeKey,
                "ROOT.NODES",
                JoinKind.LeftAnti
                ),
            {
                ParentKey,
                ParentName
            }
        )
    ),
    #"Filtered Root Nodes" = Table.SelectRows(
        #"Root Nodes",
        each [ParentKey] = 6207
    ),

    // Initial data to start recursion, using a parameter-less function
    InitialStep = ()=>
        [
            NODES = #"Filtered Root Nodes",
            NextPK = ParentKey,
            LEVEL = 0
        ],
    
    // Under which conditions start a new iteration?
    ConditionCheck = (_)=> [LEVEL] < MaxLevel,
    
    GetNextLevel = (_)=>
        let 
            FindChilds = Table.NestedJoin(
                [NODES], [NextPK],
                BomTable, ParentKey,
                "CHILD.NODES",
                JoinKind.LeftOuter
            ),
            ExpandAndRename = Table.ExpandTableColumn(
                FindChilds,
                "CHILD.NODES",
                {NodeKey,NodeName},
                {NodeKey & Text.From([LEVEL]), NodeName & Text.From([LEVEL])}
            ),
            Return = [
                NODES = ExpandAndRename,
                NextPK = NodeKey & Text.From([LEVEL]),
                LEVEL = [LEVEL] + 1
            ]
        in
            Return,
    
    Flatten = List.Generate (
        InitialStep,
        ConditionCheck,
        GetNextLevel
    )
in
    Flatten