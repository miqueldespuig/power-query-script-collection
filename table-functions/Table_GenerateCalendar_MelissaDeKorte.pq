let
    fnDateTable = ( StartDate as date, EndDate as date, optional FYStartMonthNum as number, optional Holidays as list, optional WDStartNum as number, optional AddRelativeNetWorkdays as logical ) as table =>
    let
        FYStartMonth = List.Select({1..12}, each _ = FYStartMonthNum){0}? ?? 1,
        WDStart = List.Select({0..1}, each _ = WDStartNum){0}? ?? 0,
        CurrentDate = Date.From(DateTimeZone.FixedUtcNow()),
        DayCount = Duration.Days(Duration.From(EndDate - StartDate)) + 1,
        weekStart = Day.Monday,
        HolidaysProvided = Holidays <> null,

        Source = List.Dates(StartDate, DayCount, Duration.From(1)),
        AddToday = if List.Contains(Source, CurrentDate) then Source else List.Combine({Source, {CurrentDate}}),
        ToTable = Table.FromColumns({AddToday}, type table [Date = date]),

        /*  === Year Columns === */
        AddYearRecord = Table.AddColumn(ToTable, "YearRecord", each [
            Year = Date.Year([Date]),
            CurrYearOffset = Date.Year([Date]) - Date.Year(CurrentDate),
            YearCompleted = Date.EndOfYear([Date]) < Date.EndOfYear(CurrentDate)
        ], type [Year=Int64.Type, CurrYearOffset=Int64.Type, YearCompleted=logical]),
        ExpandedYear = Table.ExpandRecordColumn(AddYearRecord, "YearRecord", {"Year", "CurrYearOffset", "YearCompleted"}),

        /*  === Quarter Columns === */
        AddQuarterRecord = Table.AddColumn(ExpandedYear, "QuarterRecord", each [
            Quarter Number = Date.QuarterOfYear([Date]),
            Quarter = "Q" & Number.ToText(#"Quarter Number"),
            Start of Quarter = Date.StartOfQuarter([Date]),
            End of Quarter = Date.EndOfQuarter([Date]),
            #"Quarter & Year" = "Q" & Number.ToText(#"Quarter Number") & Date.ToText([Date], [Format = " yyyy"]),
            QuarternYear = [Year] * 10 + #"Quarter Number",
            CurrQuarterOffset = ((4 * Date.Year([Date])) + #"Quarter Number") - ((4 * Date.Year(CurrentDate)) + Date.QuarterOfYear(CurrentDate)),
            QuarterCompleted = #"End of Quarter" < Date.EndOfQuarter(CurrentDate)
        ], type [Quarter Number=Int64.Type, Quarter=text, Start of Quarter=date, End of Quarter=date, #"Quarter & Year"=text, QuarternYear=Int64.Type, CurrQuarterOffset=Int64.Type, QuarterCompleted=logical]),
        ExpandedQuarter = Table.ExpandRecordColumn(AddQuarterRecord, "QuarterRecord", 
            {"Quarter Number", "Quarter", "Start of Quarter", "End of Quarter", "Quarter & Year", "QuarternYear", "CurrQuarterOffset", "QuarterCompleted"}),

        /*  === Month Columns === */
        AddMonthRecord = Table.AddColumn(ExpandedQuarter, "MonthRecord", each [
            Month = Date.Month([Date]),
            Start of Month = Date.StartOfMonth([Date]),
            End of Month = Date.EndOfMonth([Date]),
            #"Month & Year" = Text.Proper(Date.ToText([Date], [Format = "MMM yyyy"])),
            MonthnYear = [Year] * 100 + Month,
            CurrMonthOffset = ((12 * Date.Year([Date])) + Month) - ((12 * Date.Year(CurrentDate)) + Date.Month(CurrentDate)),
            MonthCompleted = #"End of Month" < Date.EndOfMonth(CurrentDate),
            Month Name = Text.Proper(Date.ToText([Date], "MMMM")),
            Month Short = Text.Proper(Date.ToText([Date], "MMM")),
            Month Initial = Text.Start(Text.Proper(Date.ToText([Date], "MMMM")), 1) & Text.Repeat(Character.FromNumber(8203), Month),
            Day of Month = Date.Day([Date])
        ], type [Month=Int64.Type, Start of Month=date, End of Month=date, #"Month & Year"=text, MonthnYear=Int64.Type, CurrMonthOffset=Int64.Type, MonthCompleted=logical, Month Name=text, Month Short=text, Month Initial=text, Day of Month=Int64.Type]),
        ExpandedMonth = Table.ExpandRecordColumn(AddMonthRecord, "MonthRecord", 
            {"Month", "Start of Month", "End of Month", "Month & Year", "MonthnYear", "CurrMonthOffset", "MonthCompleted", "Month Name", "Month Short", "Month Initial", "Day of Month"}),

        /*  === Week Columns === */
        AddWeekRecord = Table.AddColumn(ExpandedMonth, "WeekRecord", each [
            WeekNumCalc = Number.RoundDown((Date.DayOfYear([Date]) - (Date.DayOfWeek([Date], weekStart) + 1) + 10) / 7),
            Week Number = if WeekNumCalc = 0 
                then Number.RoundDown((Date.DayOfYear(#date(Date.Year([Date]) - 1, 12, 31)) - (Date.DayOfWeek(#date(Date.Year([Date]) - 1, 12, 31), weekStart) + 1) + 10) / 7)
                else if (WeekNumCalc = 53 and (Date.DayOfWeek(#date(Date.Year([Date]), 12, 31), weekStart) + 1 < 4)) then 1 else WeekNumCalc,
            Start of Week = Date.StartOfWeek([Date], weekStart),
            End of Week = Date.EndOfWeek([Date], weekStart),
            #"Week & Year" = "W" & Text.PadStart(Text.From(#"Week Number"), 2, "0") & " " & Text.From(Date.Year(Date.AddDays(#"Start of Week", 3))),
            WeeknYear = Date.Year(Date.AddDays(#"Start of Week", 3)) * 100 + #"Week Number",
            CurrWeekOffset = (Number.From(#"Start of Week") - Number.From(Date.StartOfWeek(CurrentDate, weekStart))) / 7,
            WeekCompleted = #"End of Week" < Date.EndOfWeek(CurrentDate, weekStart)
        ], type [Week Number=Int64.Type, Start of Week=date, End of Week=date, #"Week & Year"=text, WeeknYear=Int64.Type, CurrWeekOffset=Int64.Type, WeekCompleted=logical]),
        ExpandedWeek = Table.ExpandRecordColumn(AddWeekRecord, "WeekRecord", 
            {"Week Number", "Start of Week", "End of Week", "Week & Year", "WeeknYear", "CurrWeekOffset", "WeekCompleted"}),

        /* === Day Columns === */
        AddDayRecord = Table.AddColumn(ExpandedWeek, "DayRecord", each [
            Day of Week Number = Date.DayOfWeek([Date], weekStart) + WDStart,
            Day of Week Name = Text.Proper(Date.ToText([Date], "dddd")),
            Day of Week Initial = Text.Proper(Text.Start(#"Day of Week Name", 1)) & Text.Repeat(Character.FromNumber(8203), Date.DayOfWeek([Date], weekStart) + WDStart),
            Day of Year = Date.DayOfYear([Date]),
            DateInt = [Year] * 10000 + [Month] * 100 + [Day of Month],
            CurrDayOffset = Number.From([Date]) - Number.From(CurrentDate),
            IsAfterToday = not ([Date] <= CurrentDate),
            IsWeekDay = if Date.DayOfWeek([Date], weekStart) > 4 then false else true,
            IsHoliday = if not HolidaysProvided then "Unknown" else List.Contains(Holidays, [Date]),
            IsBusinessDay = if (if Date.DayOfWeek([Date], weekStart) > 4 then false else true) and (if HolidaysProvided then not List.Contains(Holidays, [Date]) else true) then true else false,
            Day Type = if HolidaysProvided and List.Contains(Holidays, [Date]) then "Holiday" 
                else if (if Date.DayOfWeek([Date], weekStart) > 4 then false else true) = false then "Weekend" 
                else if (if Date.DayOfWeek([Date], weekStart) > 4 then false else true) = true then "Weekday" else null
        ], type [Day of Week Number=Int64.Type, Day of Week Name=text, Day of Week Initial=text, Day of Year=Int64.Type, DateInt=Int64.Type, CurrDayOffset=Int64.Type, IsAfterToday=logical, IsWeekDay=logical, IsHoliday= (if HolidaysProvided then Logical.Type else Text.Type), IsBusinessDay=logical, Day Type=text]),
        ExpandedDay = Table.ExpandRecordColumn(AddDayRecord, "DayRecord", 
            {"Day of Week Number", "Day of Week Name", "Day of Week Initial", "Day of Year", "DateInt", "CurrDayOffset", "IsAfterToday", "IsWeekDay", "IsHoliday", "IsBusinessDay", "Day Type"}),

        /* === ISO Columns === */
        InsertISOYear = Table.AddColumn(ExpandedDay, "ISO Year", each Date.Year(Date.AddDays(Date.StartOfWeek([Date], weekStart), 3)), Int64.Type),
        InsertISOqNum = Table.AddColumn(InsertISOYear, "ISO Quarter Number", each if [Week Number] > 39 then 4 else if [Week Number] > 26 then 3 else if [Week Number] > 13 then 2 else 1, Int64.Type),
        InsertISOqtr = Table.AddColumn(InsertISOqNum, "ISO Quarter", each "Q" & Number.ToText([ISO Quarter Number]), type text),
        InsertISOQuarter = Table.AddColumn(InsertISOqtr, "ISO Quarter & Year", each "Q" & Number.ToText([ISO Quarter Number]) & " " & Number.ToText([ISO Year]), type text),
        InsertISOqNy = Table.AddColumn(InsertISOQuarter, "ISO QuarternYear", each [ISO Year] * 10 + [ISO Quarter Number], Int64.Type),

        /* === Fiscal Columns === */
        AddFYnr = Table.AddColumn(InsertISOqNy, "FY number", each (if [Month] >= FYStartMonth and FYStartMonth >1 then [Year] +1 else [Year]), Int64.Type),
        AddFY = Table.AddColumn(AddFYnr, "Fiscal Year", each "FY" & Text.From([FY number]), type text),
        AddFQ = Table.AddColumn(AddFY, "Fiscal Quarter", each "FQ" & Text.From( Number.RoundUp( Date.Month( Date.AddMonths( [Date], - (FYStartMonth -1) )) / 3 )) & " " & Text.From([FY number]), type text),
        AddFQnYr = Table.AddColumn(AddFQ, "FQuarternYear", each [FY number] * 10 + Number.RoundUp( Date.Month( Date.AddMonths( [Date], - (FYStartMonth -1) )) / 3 ), type number),
        AddFM = Table.AddColumn(AddFQnYr, "Fiscal Period Number", each if [Month] >= FYStartMonth and FYStartMonth >1 then [Month] - (FYStartMonth-1) else if [Month] >= FYStartMonth and FYStartMonth =1 then [Month] else [Month] + (12-FYStartMonth+1), type number),
        AddFP = Table.AddColumn(AddFM, "Fiscal Period", each "FP" & Text.PadStart( Text.From([Fiscal Period Number]), 2, "0") & " " & Text.From([FY number]), type text),
        AddFMnYr = Table.AddColumn(AddFP , "FPeriodnYear", each [FY number] * 100 + [Fiscal Period Number], type number),
        FYCalendarStart = #date( Date.Year(StartDate)-1, FYStartMonth, 1 ),
        InsertFFD = Table.AddColumn(AddFMnYr, "FiscalFirstDay", each if [Month] >= FYStartMonth then #date([Year], FYStartMonth, 1) else #date([Year]-1, FYStartMonth, 1), type date),
        InsertFiscalWeekNumber = Table.AddColumn(InsertFFD, "Fiscal Week Number", each let
            FiscalWeekStart = Date.StartOfWeek([FiscalFirstDay], weekStart),
            CurrentWeekStart = Date.StartOfWeek([Date], weekStart),
            WeekDiff = Duration.Days(CurrentWeekStart - FiscalWeekStart) / 7
            in Number.RoundDown(WeekDiff) + 1, Int64.Type
        ),
        FWlogic = List.Contains( {null}, FYStartMonthNum),
        UpdateFYWeek = if FWlogic then Table.ReplaceValue(InsertFiscalWeekNumber, each [Fiscal Week Number], each if FYStartMonth =1 then [Week Number] else [Fiscal Week Number], Replacer.ReplaceValue, {"Fiscal Week Number"}) else InsertFiscalWeekNumber,
        AddFYW = Table.AddColumn( UpdateFYWeek, "Fiscal Week", each if FWlogic then "F" & [#"Week & Year"] else "FW" & Text.PadStart( Text.From([Fiscal Week Number]), 2, "0") & " " & Text.From([FY number]), type text),
        InsertFWeeknYear = Table.AddColumn(AddFYW, "FWeeknYear", each if FWlogic then [WeeknYear] else [FY number] * 100 + [Fiscal Week Number],  Int64.Type),

        /*  === Get Current Date Values === */
        CurrentDateRecord = Table.SelectRows(InsertFWeeknYear, each ([Date] = CurrentDate)),
        CurrentISOyear = CurrentDateRecord{0}[ISO Year],
        CurrentISOqtr = CurrentDateRecord{0}[ISO Quarter Number],
        CurrentYear = CurrentDateRecord{0}[Year],
        CurrentMonth = CurrentDateRecord{0}[Month],
        CurrentFiscalFirstDay = CurrentDateRecord{0}[FiscalFirstDay],
        PrevFiscalFirstDay = Date.AddYears(CurrentFiscalFirstDay, -1),
        CurrentFY = CurrentDateRecord{0}[Fiscal Year],
        CurrentFQ = CurrentDateRecord{0}[FQuarternYear],
        CurrentFP = CurrentDateRecord{0}[FPeriodnYear],
        CurrentFW = CurrentDateRecord{0}[FWeeknYear],

        /*  === Others & Clean up === */
        InsertISOYrOffset = Table.AddColumn(InsertFWeeknYear, "ISO CurrYearOffset", each [ISO Year] - CurrentISOyear, Int64.Type),
        InsertISOQtrOffset = Table.AddColumn(InsertISOYrOffset, "ISO CurrQuarterOffset", each ((4 * [ISO Year]) + [ISO Quarter Number]) - ((4 * CurrentISOyear) + CurrentISOqtr), Int64.Type),
        InsertFYoffset = Table.AddColumn(InsertISOQtrOffset, "Fiscal CurrYearOffset", each try (if [Month] >= FYStartMonth then [Year] + 1 else [Year]) - (if CurrentMonth >= FYStartMonth then CurrentYear + 1 else CurrentYear) otherwise null, Int64.Type),
        InsertCurrentFY = Table.AddColumn(InsertFYoffset, "IsCurrentFY", each if [Fiscal Year] = CurrentFY then true else false, type logical),
        InsertCurrentFQ = Table.RemoveColumns( Table.AddColumn(InsertCurrentFY, "IsCurrentFQ", each if [FQuarternYear] = CurrentFQ then true else false, type logical), {"FY number"} ),
        InsertCurrentFP = Table.AddColumn(InsertCurrentFQ, "IsCurrentFP", each if [FPeriodnYear] = CurrentFP then true else false, type logical),
        InsertCurrentFW = Table.AddColumn(InsertCurrentFP, "IsCurrentFW", each if [FWeeknYear] = CurrentFW then true else false, type logical),
        InsertPYTD = Table.AddColumn(InsertCurrentFW, "IsPYTD", each if CurrentYear-1 = [Year] and [Day of Year] <= CurrentDateRecord{0}[Day of Year] then true else false, type logical),
        InsertPFYTD = Table.AddColumn(InsertPYTD, "IsPFYTD", each if [Fiscal CurrYearOffset] = -1 then Duration.Days([Date] - PrevFiscalFirstDay) + 1 <= Duration.Days(CurrentDate - CurrentFiscalFirstDay) + 1 else false, type logical),
        InsertNetWorkdays = if AddRelativeNetWorkdays = true then Table.AddColumn(InsertPFYTD, "Relative Networkdays", each fxNETWORKDAYS( StartDate, [Date], Holidays ), Int64.Type) else InsertPFYTD,
        fxNETWORKDAYS = (StartDate, EndDate, optional Holidays as list) =>
        let
            ListOfDates = List.Dates( StartDate, Number.From(EndDate-StartDate)+1, Duration.From(1) ),
            DeleteHolidays = if Holidays = null then ListOfDates else List.Difference( ListOfDates, List.Transform(Holidays, Date.From )),
            DeleteWeekends = List.Select( DeleteHolidays, each Date.DayOfWeek( _, weekStart) < 5 ),
            CountDays = List.Count( DeleteWeekends)
        in
            CountDays,
        RemoveToday = Table.RemoveColumns(if not List.Contains(Source, CurrentDate) then Table.SelectRows(InsertNetWorkdays, each ([Date] <> CurrentDate)) else InsertNetWorkdays, {"Day of Year", "FiscalFirstDay"}),
        ChType = Table.TransformColumnTypes(RemoveToday, {{"Year", Int64.Type}, {"Quarter Number", Int64.Type}, {"Month", Int64.Type}, {"Day of Month", Int64.Type}, {"DateInt", Int64.Type}, {"Day of Week Number", Int64.Type}, {"ISO CurrYearOffset", Int64.Type}, {"ISO QuarternYear", Int64.Type}, {"ISO CurrQuarterOffset", Int64.Type}, {"Week Number", Int64.Type}, {"WeeknYear", Int64.Type}, {"MonthnYear", Int64.Type}, {"QuarternYear", Int64.Type}, {"FQuarternYear", Int64.Type}, {"Fiscal Period Number", Int64.Type}, {"FPeriodnYear", Int64.Type}, {"CurrWeekOffset", Int64.Type}, {"CurrMonthOffset", Int64.Type}, {"CurrQuarterOffset", Int64.Type}, {"CurrYearOffset", Int64.Type}, {"Fiscal CurrYearOffset", Int64.Type}, {"Fiscal Week Number", Int64.Type}}),
        ReorderCols = Table.ReorderColumns(ChType, {"Date", "Year", "CurrYearOffset", "YearCompleted", "Quarter Number", "Quarter", "Start of Quarter", "End of Quarter", "Quarter & Year", "QuarternYear", "CurrQuarterOffset", "QuarterCompleted", "Month", "Start of Month", "End of Month", "Month & Year", "MonthnYear", "CurrMonthOffset", "MonthCompleted", "Month Name", "Month Short", "Month Initial", "Day of Month", "Week Number", "Start of Week", "End of Week", "Week & Year", "WeeknYear", "CurrWeekOffset", "WeekCompleted", "Day of Week Number", "Day of Week Name", "Day of Week Initial", "DateInt", "CurrDayOffset", "IsAfterToday", "IsWeekDay", "IsHoliday", "IsBusinessDay", "Day Type", "ISO Year", "ISO CurrYearOffset", "ISO Quarter Number", "ISO Quarter", "ISO Quarter & Year", "ISO QuarternYear", "ISO CurrQuarterOffset", "Fiscal Year", "Fiscal CurrYearOffset", "Fiscal Quarter", "FQuarternYear", "Fiscal Period Number", "Fiscal Period", "FPeriodnYear", "Fiscal Week Number", "Fiscal Week", "FWeeknYear", "IsCurrentFY", "IsCurrentFQ", "IsCurrentFP", "IsCurrentFW", "IsPYTD", "IsPFYTD"}),
        ListCols = if FWlogic then Table.RemoveColumns(ReorderCols, {"ISO Quarter Number", "Fiscal Year", "Fiscal Quarter", "FQuarternYear", "Fiscal Period Number", "Fiscal Period", "FPeriodnYear", "Fiscal Week Number", "Fiscal Week", "FWeeknYear", "Fiscal CurrYearOffset", "IsCurrentFY", "IsCurrentFQ", "IsCurrentFP", "IsCurrentFW", "IsPFYTD"}) else Table.RemoveColumns(ReorderCols, {"Fiscal Period Number", "Fiscal Week Number", "ISO Quarter Number"})
    in
        ListCols
in
    Value.ReplaceType(fnDateTable, Value.ReplaceMetadata(Value.Type(fnDateTable), [
        Documentation.Name = " fxCalendar", 
        Documentation.Description = " Date table function to create an ISO-8601 calendar", 
        Documentation.LongDescription = " Date table function to create an ISO-8601 calendar", 
        Documentation.Category = " Table", 
        Documentation.Version = " 2.04: Optimized Version",
        Documentation.Source = " local", 
        Documentation.Author = " Melissa de Korte", 
        Documentation.Examples = { [Description = " See: https://forum.enterprisedna.co/t/extended-date-table-power-query-m-function/6390", 
            Code = " Optional paramters: #(lf)(FYStartMonthNum) Month number the fiscal year starts, Januari if omitted #(lf)(Holidays) Select a query (column) that contains a list of holiday dates #(lf)(WDStartNum) Switch default weekday numbering from 0-6 to 1-7 by entering a 1 #(lf)(AddRelativeNetWorkdays) if true adds a Relative Networkdays column to the date table #(lf)
                #(lf)Important notes: #(lf)[Fiscal Week] starts on a Monday and can contain less than 7 days in a First- and/or Last Week of a FY #(lf)[IsWeekDay] does not take holiday dates into account #(lf)[IsBusinessDay] does take optional holiday dates into account  #(lf)[IsPYTD] and [IsPFYTD] compare Previous [Day of Year] with the Current [Day of Year] number, so dates don't align in leap years #(lf)> No Fiscal columns will be added if (FYStartMonthNum) is omitted!", 
            Result = " " ] }
    ]))
