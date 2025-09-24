﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ProcessFormParameters() Then
		Cancel = True;
		Return;
	EndIf;
	
	TitleTemplate1 =  NStr("en = 'Responses to question %1 of survey %2, %3.';");
	Title = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, FullCode, SurveyDescription, Format(SurveyDate,"DLF=D"));
	
	GenerateReport();
	
EndProcedure

&AtClient
Procedure ReportVariantOnChange(Item)
	
	GenerateReport();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateReport()
	
	ReportTable.Clear();
	DCS = Reports.PollStatistics.GetTemplate("SimpleQuestions");
	Settings = DCS.SettingVariants[ReportVariant].Settings;
	
	DCS.Parameters.QuestionnaireTemplateQuestion.Value = QuestionnaireTemplateQuestion;
	DCS.Parameters.Survey.Value               = Survey;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DCS,Settings);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ReportTable);
	OutputProcessor.Output(DataCompositionProcessor);
	
	ReportTable.ShowGrid = False;
	ReportTable.ShowHeaders = False;
	
EndProcedure

&AtServer
Function ProcessFormParameters()

	If Parameters.QuestionnaireTemplateQuestion.IsEmpty() Then	
		Return False;
	EndIf;
	QuestionnaireTemplateQuestion = Parameters.QuestionnaireTemplateQuestion; 

	If Parameters.Survey.IsEmpty() Then
		Return False;
	EndIf;
	Survey = Parameters.Survey; 
	
	If IsBlankString(Parameters.FullCode) Then
		Return False;
	EndIf;
	FullCode = Parameters.FullCode;
	
	If IsBlankString(Parameters.SurveyDescription) Then
		Return False;
	EndIf;
	SurveyDescription = Parameters.SurveyDescription;
	
	If Not ValueIsFilled(Parameters.SurveyDate) Then
		Return False;
	EndIf;
	SurveyDate = Parameters.SurveyDate;
	
	If IsBlankString(Parameters.ReportVariant) Then
		Return False;
	EndIf;
	ReportVariant = Parameters.ReportVariant;

	Return True;
	
EndFunction

#EndRegion
