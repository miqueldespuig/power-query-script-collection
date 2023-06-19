let
    Function = (YearFrom as number, YearTo as number, optional Locale as text) =>
    let
        // Hard-coded variables for debugging.
        // YearFrom = 2019, // Which year will be the first of the calendar generation
        // YearTo = 2022, // Which year will be the last year for the calculation
        // Locale = "ca-CA", // Which language will be used for the name generation. If we wan't to overwrite the Locale from the file.

        // Generates first date
        StartDate = #date(YearFrom,1,1),
        // Generates last date
        EndDate = #date(YearTo,12,31),
        // Calculate duration in days between EndDate and StartDate
        DayCount = Duration.Days(Duration.From(EndDate-StartDate))+1,
        // Date list generation
        DateList = List.Dates(StartDate,DayCount,#duration(1,0,0,0)),
        
        // Convert the date list to a proper table with column name Date and proper types
        SourceTable = Table.FromList(DateList, Splitter.SplitByNothing(), type table [ Date = date ]),
        
        // Add day sequence, number of day since 30/12/1899. Useful for moving annual total custom. MANAGE LEAP YEARS PENDING. WHOLE NUMBER (HIDDEN)
        InsertDaySequence = Table.AddColumn(SourceTable,"day_seq", each Date.Year([Date])*10000 + Date.Month([Date])*100 + Date.Day([Date]), Int64.Type),
        
        // Add year number, 2022, WHOLE NUMBER (HIDDEN)
        InsertYearNumber = Table.AddColumn(InsertDaySequence, "year_number", each Date.Year([Date]), Int64.Type),
        // Add year column, "2022", TEXT
        InsertYear = Table.AddColumn(InsertYearNumber, "Year", each Number.ToText([year_number]), type text),
        // Add end of year date. Used for line charts continuous axis, DATE
        InsertEndOfYear = Table.AddColumn(InsertYear, "End Of Year", each Date.EndOfYear([Date]), type date),

        // Add quarter of year number. 1,2,3,4.  WHOLE NUMBER (HIDDEN)
        InsertQuarterNumber = Table.AddColumn(InsertEndOfYear, "quarter_number", each Date.QuarterOfYear([Date]), Int64.Type),
        // Add quarter sequence. Number of quarters completed since year_number = 0. 8076, WHOLE NUMBER (HIDDEN)
        InsertQuarterSequence = Table.AddColumn(InsertQuarterNumber, "quarter_seq", each [year_number] * 4 + [quarter_number] -1 , Int64.Type),
        // Add quarter name. "Q1". TEXT
        InsertQuarter = Table.AddColumn(InsertQuarterSequence, "Quarter", each "Q" & Number.ToText([quarter_number]), type text),
        // Add end of quarter date. 31/03/2019. DATE
        InsertEndOfQuarter = Table.AddColumn(InsertQuarter, "End of Quarter", each Date.EndOfQuarter([Date]), type date),
        // Add Year-Quarter text, for independent hierarchies. "2022-Q1". TEXT
        InsertYearQuarter = Table.AddColumn(InsertEndOfQuarter, "Year & Quarter", each Number.ToText([year_number]) & "-" & [Quarter], type text),

        // Add month of year number. 1..12. WHOLE NUMBER (HIDDEN)
        InsertMonthNumber = Table.AddColumn(InsertYearQuarter, "month_number", each Date.Month([Date]), Int64.Type),
        // Add month sequence. Useful for custom time intelligence. Number of months completed since year_number = 0.
        InsertMonthSequence = Table.AddColumn(InsertMonthNumber, "month_seq", each [year_number] * 12 + [month_number] - 1, Int64.Type),
        // Add month name. Using Locale variable in case it's especified. "gener". TEXT
        InsertMonth = Table.AddColumn(InsertMonthSequence, "Month", each Date.MonthName([Date], Locale), type text),
        // Add month short name, for convenience in some visualizations. "gen". TEXT
        InsertMonthShort = Table.AddColumn(InsertMonth, "Month Short", each Text.Lower(Text.Start([Month],3)), type text),
        // Add end of month date. Useful for continuous axis at a month granularity. 31/01/2022. DATE
        InsertEndOfMonth = Table.AddColumn(InsertMonthShort, "End Of Month", each Date.EndOfMonth([Date]), type date),
        // Add Year-Month text, for independent hieararchies. "2022-gen". TEXT
        InsertYearMonth = Table.AddColumn(InsertEndOfMonth, "Year & Month", each Number.ToText([year_number]) & "-" & [Month Short], type text),
        // Add day of year number. 243. WHOLE NUMBER (HIDDEN)
        InsertDayOfYear = Table.AddColumn(InsertYearMonth, "Day of Year", each Date.DayOfYear([Date]), Int64.Type),
        // Add day of month number. 27. WHOLE NUMBER (HIDDEN)
        InsertDayOfMonth = Table.AddColumn(InsertDayOfYear, "Day of Month", each Date.Day([Date]), Int64.Type)
    in
        InsertDayOfMonth,
    // Documentation
    FunctionType = type function (YearFrom as number, YearTo as number, optional Locale as text) as table
    meta [
            Documentation.Author = "Miquel Despuig",
            Documentation.Version = "1.0.0", //MajorVersion|MinorVersion|Revision
            Documentation.Name = "fxCalendar",
            Documentation.LongDescription = "Generates a calendar table from a origin year and end year.",
            Documentation.Description ="Generate a dim Calendar table"
    ]
in Value.ReplaceType(Function,FunctionType)