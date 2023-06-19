(Name as text, optional TextSeparator as text) as text =>
let
    Separator = if TextSeparator is null then "_" else TextSeparator,
    Splitted = Text.Split(Name, Separator),

    fxNameNormalizer = (input as text) as text =>
        if Comparer.Equals(Comparer.OrdinalIgnoreCase, "id", input)
        then Text.Upper(input)
        else Text.Proper(input),
    
    NormalizedNames = List.Transform(Splitted, fxNameNormalizer),
    Result = Text.Combine(NormalizedNames, " ")
in
  Result

// Ben Gribaudo
// https://bengribaudo.com/blog/2018/05/18/4447/automating-column-name-renames
