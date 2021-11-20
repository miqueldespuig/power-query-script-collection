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
(BomTable as table, NodeKey as text, ParentKey as text, NodeName as text) as table =>
    let
        // FIND ROOT NODES  
        Parents = List.Distinct(
            Table.Column(BomTable, ParentKey)
        )

        // SEED

        // LEVELS (Recursive JOIN)
    in
        Parents