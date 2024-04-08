let
  Function = (ListOfValues as list) =>
    let
      Combined = ListOfValues{0} & " [" & ListOfValues{1} & "]",
      Result =
        if List.Count(ListOfValues) > 2 then
          Error.Record(
            "Too Many Inputs",
            "This Combiner funcion expects only two input columns"
          )
        else
          Combined
    in
      Result,
  FunctionType = type function (ListOfValues as list) as text
    meta [
      Documentation.Author = "Miquel Despuig",
      Documentation.Version = "1",
      Documentation.Source = "",
      Documentation.Name = "Combiner_DescriptionAndCode",
      Documentation.LongDescription
        = "Combiner function that takes a list of two ordered values {""description"",""code""} and combines the two texts in this pattern: ""description [code]"". This combiner function is usually used in Table.CombineColumns function."
    ],
  Ascrybed = Value.ReplaceType(Function, FunctionType)
in
  Ascrybed