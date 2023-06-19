( HierarchyTable as table, NodeKey as text, NodeName as text, ParentKey as text ) as table =>
    let
        // DEBUGGING            
        // HierarchyTable = tbl_hierarchy3col,                                      
        // ParentKey = "ParentKey",                           
        // NodeKey = "NodeKey",                       
        // NodeName = "NodeName",

        // STATIC VARIABLES                   
        SUPERIOR_KEY = "Predecessor",
        SUBORDINATE_KEY = "Successor",

        // LIST OF NODES TO ITERATE                           
        NodeList = Table.Column ( HierarchyTable, NodeKey ),

        // EXPLORE NODE FUNCTION DEFINITION                                   
        initial = ( NodePosition ) =>
            () =>
                #table (
                    { SUPERIOR_KEY, SUBORDINATE_KEY, "Levels Removed" },
                    { { NodeList{NodePosition}, NodeList{NodePosition}, 0 } }
                ),
        condition = ( _ ) => not Table.IsEmpty ( _ ),
        next = ( _ ) =>
            let
                LevelsRemovedNext = List.Max ( Table.Column ( _, "Levels Removed" ) ) + 1,
                SelectColumns = Table.SelectColumns ( _, { SUPERIOR_KEY, SUBORDINATE_KEY } ),
                SelfJoinBOM = Table.NestedJoin (
                    SelectColumns,
                    { SUBORDINATE_KEY },
                    HierarchyTable,
                    { ParentKey },
                    "SUCCESSORS",
                    JoinKind.Inner
                ),
                RemoveSubordinate = Table.RemoveColumns ( SelfJoinBOM, { SUBORDINATE_KEY } ),
                AddLevelsRemoved = Table.AddColumn (
                    RemoveSubordinate,
                    "Levels Removed",
                    each LevelsRemovedNext
                ),
                ExpandSubordinates = Table.ExpandTableColumn (
                    AddLevelsRemoved,
                    "SUCCESSORS",
                    { NodeKey },
                    { SUBORDINATE_KEY }
                )
            in
                ExpandSubordinates,

        ExploreNode = ( NodePosition ) =>
            Table.Combine ( List.Generate ( initial ( NodePosition ), condition, next ) ),

        // GENERATE THE BRIDGE TABLE                            
        BridgeTable = List.Accumulate (
            NodeList,
            #table ( {}, {} ),
            ( State, Current ) =>
                let
                    NodePosition = List.PositionOf ( NodeList, Current ),
                    Explore      = ExploreNode ( NodePosition ),
                    NewState     = Table.Combine ( { State, Explore } )
                in
                    NewState
        ),

        // IN CASE OF MULTI PARENT HIERARCHIES MORE LINES THAN NEEDED ARE GENERATED                                                                           
        MultiParentHandling = Table.Distinct ( BridgeTable )
    in
        MultiParentHandling