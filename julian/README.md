# JDEdwards julian date conversion functions

JDEdwards is an ERP system that stores date columns in a special Julian Date format: *CYYDDD* where:
* C = Century
* YY = Year Number in the century
* DDD = Day number in the year

If you're importing data into PowerQuery from a DBMS holding JDEdwards you'll be converting to and from this date format quite often. That's why these 2 functions might come in handy:

## fxGreg2Jul

Given a *julian date* (in JDEdwards integer format) it will convert to a standard M date type column.

## fxJul2Greg

Given a *gregorian date* it will convert to *julian date* integer in JDEdwards format.