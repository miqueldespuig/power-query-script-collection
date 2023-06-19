let
    Function = 
    ( Text as text ) =>
        let
            Splitted = Text.Split(Text, " "),
            Chunks = List.RemoveItems(Splitted,""),
            Combined = List.Combine(Chunks, " ")
        in
            Combined,
    FunctionType = 
        type function ( Text as text ) as text
        meta [
            Documentation.Author = "Rick De Groot",
            Documentation.Version = "1",
            Documentation.Source = "https://gorilla.bi/power-query/removing-excess-spaces/",
            Documentation.Name = "Text_RemoveExcessSpaces",
            Documentation.LongDescription = "Remove excess spaces between words."
        ]
in
    Value.ReplaceType(Function, FunctionType)