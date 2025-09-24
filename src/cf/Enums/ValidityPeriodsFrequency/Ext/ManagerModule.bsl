﻿#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns enumeration value by name of the service API property value.
//
// Parameters:
//  EnumValueName - String - Property name value.
// 
// Returns:
//   EnumRef.ValidityPeriodsFrequency - an enumeration value.
//
Function ValueByName(EnumValueName) Export
    
    If EnumValueName = "day" Then
        Return Day;
    ElsIf EnumValueName = "week" Then
        Return Week;
    ElsIf EnumValueName = "decade" Then
        Return TenDays;
    ElsIf EnumValueName = "month" Then
        Return Month;
    ElsIf EnumValueName = "semester" Then
        Return Quarter;
    ElsIf EnumValueName = "half_year" Then
        Return HalfYear;
    ElsIf EnumValueName = "year" Then
        Return Year;
    Else
        Return EmptyRef();
    EndIf; 
    
EndFunction

// Adds the specified number of validity periods to the date.
//
// Parameters:
//  SourceDate1 - Date - Initial date.
//  Periodicity - EnumRef.ValidityPeriodsFrequency - Period frequency.
//  Count - Number - Number of periods to be added.
// 
// Returns:
//  Date - Resulting date. 
//
Function AddToDate(Val SourceDate1, Val Periodicity, Val Count) Export 
	
	Date = SourceDate1;
	
	PeriodStartOfDay = BegOfDay(SourceDate1);
	
	NumberOfSecondsInDay = 86400;
	NumberOfDaysInWeek = 7;
	NumberOfDaysPerDecade = 10;
	NumberOfMonthsInQuarter = 3;
	NumberOfMonthsInHalfYear = 6;
	NumberOfMonthsInYear = 12;
	
	PeriodData = New Structure("Periodicity, Count", Periodicity, Count);
	
	If PeriodData.Periodicity = Day
			Or PeriodData.Periodicity = TenDays
			Or PeriodData.Periodicity = Week Then
			
		NumberOfDaysInSeconds = PeriodData.Count * NumberOfSecondsInDay;
		
		If PeriodData.Periodicity = TenDays Then
			NumberOfDaysInSeconds = NumberOfDaysInSeconds * NumberOfDaysPerDecade;
		ElsIf PeriodData.Periodicity = Week Then
			NumberOfDaysInSeconds = NumberOfDaysInSeconds * NumberOfDaysInWeek;
		EndIf;
		
		Date = PeriodStartOfDay + NumberOfDaysInSeconds;
		
	Else
		NumberOfMonths = PeriodData.Count;
		
		If PeriodData.Periodicity = Quarter Then
			NumberOfMonths = NumberOfMonths * NumberOfMonthsInQuarter;
		ElsIf PeriodData.Periodicity = HalfYear Then
			NumberOfMonths = NumberOfMonths * NumberOfMonthsInHalfYear;
		ElsIf PeriodData.Periodicity = Year Then
			NumberOfMonths = NumberOfMonths * NumberOfMonthsInYear;
		EndIf;
		
		Date = AddMonth(PeriodStartOfDay, NumberOfMonths);
		
	EndIf;
	
	Return Date - 1;
	
EndFunction

#EndRegion

#EndIf