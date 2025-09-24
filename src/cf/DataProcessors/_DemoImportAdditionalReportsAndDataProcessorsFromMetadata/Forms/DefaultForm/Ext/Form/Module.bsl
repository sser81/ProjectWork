﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateAdditionalReportsAndDataProcessors(Command)
	ExecuteCommandInBackground("UpdateAdditionalReportsAndDataProcessors", NStr("en = 'Grouping additional reports and data processors';"));
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ExecuteCommandInBackground(CommandName, AccompanyingText1)
	CommandParameters = AdditionalReportsAndDataProcessorsClient.CommandExecuteParametersInBackground(Parameters.AdditionalDataProcessorRef);
	CommandParameters.AccompanyingText1 = AccompanyingText1 + "...";
	
	Handler = New NotifyDescription("AfterFinishTimeConsumingOperation", ThisObject, AccompanyingText1);
	If ValueIsFilled(Parameters.AdditionalDataProcessorRef) Then // The data processor is attached.
		AdditionalReportsAndDataProcessorsClient.ExecuteCommandInBackground(CommandName, CommandParameters, Handler);
	Else
		ShowUserNotification(CommandParameters.AccompanyingText1, , , PictureLib.TimeConsumingOperation48);
		Operation = ExecuteCommandDirectly(CommandName, CommandParameters);
		ExecuteNotifyProcessing(Handler, Operation);
	EndIf;
EndProcedure

&AtServer
Function ExecuteCommandDirectly(CommandName, CommandParameters)
	Operation = New Structure("Status, ErrorInfo");
	Try
		AdditionalReportsAndDataProcessors.ExecuteCommandFromExternalObjectForm(
			CommandName,
			CommandParameters,
			ThisObject);
		Operation.Status = "Completed2";
	Except
		Operation.ErrorInfo = ErrorInfo();
	EndTry;
	Return Operation;
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AccompanyingText1 - String
//
&AtClient
Procedure AfterFinishTimeConsumingOperation(Result, AccompanyingText1) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ShowUserNotification(NStr("en = 'Successful completion';"),,
			AccompanyingText1, PictureLib.Success32);
	Else
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
	EndIf;
	
EndProcedure

#EndRegion
