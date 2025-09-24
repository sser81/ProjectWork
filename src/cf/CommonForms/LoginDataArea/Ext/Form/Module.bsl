﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2019, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("DataArea", DataArea);
	
	If Not ValueIsFilled(DataArea) Then
		DataArea = 1;
	EndIf;
	
	StandardSubsystemsServer.SetBlankFormOnBlankHomePage();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	RefreshInterface = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SignInToDataArea(Command)
	
	If DataAreaHasBeenEntered() Then
		ExitDataAreaOnServer();
		RefreshInterface = True;
		StandardSubsystemsClient.SetAdvancedApplicationCaption(True);
		
		AttachIdleHandler("EnterDataAreaAfterExiting", 0.1, True);
		SetButtonsAvailability(False);
	Else
		EnterDataAreaAfterExiting();
	EndIf;
	
EndProcedure

&AtClient
Procedure SignOutOfDataArea(Command)
	
	If DataAreaHasBeenEntered() Then
		// Closing forms of the separated desktop.
		RefreshInterface();
		AttachIdleHandler("ContinuingToExitDataAreaAfterHidingDesktopForms", 0.1, True);
		SetButtonsAvailability(False);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateInterfaceIfNecessary()
	
	If RefreshInterface Then
		RefreshInterface = False;
		RefreshInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure EnterDataAreaAfterExiting()
	
	SetButtonsAvailability(True);
	
	If Not SpecifiedDataAreaIsFilled(DataArea) Then
		NotifyDescription = New NotifyDescription("EnterDataAreaAfterExiting2", ThisObject);
		ShowQueryBox(NotifyDescription, NStr("en = 'The selected data area is not used. Do you want to log in?';"),
			QuestionDialogMode.YesNo, , DialogReturnCode.No);
		Return;
	EndIf;
	
	EnterDataAreaAfterExiting2();
	
EndProcedure

&AtClient
Procedure EnterDataAreaAfterExiting2(Response = Undefined, AdditionalParameters = Undefined) Export
	
	If Response = DialogReturnCode.No Then
		UpdateInterfaceIfNecessary();
		Return;
	EndIf;
	
	EnterDataAreaOnServer(DataArea);
	
	RefreshInterface = True;
	
	CompletionProcessing = New NotifyDescription(
		"ContinuingToEnterDataAreaAfterActionsBeforeStartingSystem", ThisObject);
	
	StandardSubsystemsClient.BeforeStart(CompletionProcessing);
	
EndProcedure

&AtClient
Procedure ContinuingToEnterDataAreaAfterActionsBeforeStartingSystem(Result, Context) Export
	
	If Result.Cancel Then
		ExitDataAreaOnServer();
		RefreshInterface = True;
		StandardSubsystemsClient.SetAdvancedApplicationCaption(True);
		UpdateInterfaceIfNecessary();
		Activate();
		SetButtonsAvailability(False);
		AttachIdleHandler("EnableButtonAccessibility", 2, True);
	Else
		CompletionProcessing = New NotifyDescription(
			"ContinuingToEnterDataAreaAfterActionsAtStartOfSystem", ThisObject);
		
		StandardSubsystemsClient.OnStart(CompletionProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinuingToEnterDataAreaAfterActionsAtStartOfSystem(Result, Context) Export
	
	If Result.Cancel Then
		ExitDataAreaOnServer();
		RefreshInterface = True;
		StandardSubsystemsClient.SetAdvancedApplicationCaption(True);
	EndIf;
	
	UpdateInterfaceIfNecessary();
	Activate();
	
	SetButtonsAvailability(False);
	AttachIdleHandler("EnableButtonAccessibility", 2, True);
	Notify("LoggedOnToDataArea");
	
EndProcedure

&AtClient
Procedure ContinuingToExitDataAreaAfterHidingDesktopForms()
	
	SetButtonsAvailability(True);
	
	ExitDataAreaOnServer();
	
	// Displaying forms of the shared desktop.
	RefreshInterface();
	
	StandardSubsystemsClient.SetAdvancedApplicationCaption(True);
	
	Activate();
	
	SetButtonsAvailability(False);
	AttachIdleHandler("EnableButtonAccessibility", 2, True);
	Notify("LoggedOffFromDataArea");
	
EndProcedure

&AtServerNoContext
Function SpecifiedDataAreaIsFilled(Val DataArea)
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.DataAreas");
	LockItem.SetValue("DataAreaAuxiliaryData", DataArea);
	LockItem.Mode = DataLockMode.Shared;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataAreas.Status AS Status
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|WHERE
	|	DataAreas.DataAreaAuxiliaryData = &DataArea";
	Query.SetParameter("DataArea", DataArea);
	
	BeginTransaction();
	Try
		Block.Lock();
		Result = Query.Execute();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Result.IsEmpty() Then
		Return False;
	Else
		Selection = Result.Select();
		Selection.Next();
		Return Selection.Status = Enums.DataAreaStatuses.Used
	EndIf;
	
EndFunction

&AtServerNoContext
Procedure EnterDataAreaOnServer(Val DataArea)
	
	SetPrivilegedMode(True);
	
	SaaSOperations.SignInToDataArea(DataArea);
	
	BeginTransaction();
	
	Try
		
		AreaKey = SaaSOperations.CreateAuxiliaryDataInformationRegisterEntryKey(
			InformationRegisters.DataAreas,
			New Structure(SaaSOperations.AuxiliaryDataSeparator(), DataArea));
		LockDataForEdit(AreaKey);
		
		Block = New DataLock;
		Item = Block.Add("InformationRegister.DataAreas");
		Item.SetValue("DataAreaAuxiliaryData", DataArea);
		Item.Mode = DataLockMode.Shared;
		Block.Lock();
		
		RecordManager = InformationRegisters.DataAreas.CreateRecordManager();
		RecordManager.DataAreaAuxiliaryData = DataArea;
		RecordManager.Read();
		If Not RecordManager.Selected() Then
			RecordManager.DataAreaAuxiliaryData = DataArea;
			RecordManager.Status = Enums.DataAreaStatuses.Used;
			RecordManager.Write();
		EndIf;
		UnlockDataForEdit(AreaKey);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Procedure ExitDataAreaOnServer()
	
	SetPrivilegedMode(True);
	
	// Restoring forms of the separated desktop.
	StandardSubsystemsServerCall.HideDesktopOnStart(False);
	
	StandardSubsystemsServer.SetBlankFormOnBlankHomePage();
	
	SaaSOperations.SignOutOfDataArea();
	
EndProcedure

&AtServerNoContext
Function DataAreaHasBeenEntered()
	
	SetPrivilegedMode(True);
	LoginCompleted = SaaSOperations.SessionSeparatorUsage();
	
	// Preparing to close forms of the separated desktop.
	If LoginCompleted Then
		StandardSubsystemsServerCall.HideDesktopOnStart(True);
	EndIf;
	
	Return LoginCompleted;
	
EndFunction

&AtClient
Procedure EnableButtonAccessibility()
	
	SetButtonsAvailability(True);
	
EndProcedure

&AtClient
Procedure SetButtonsAvailability(Var_Enabled)
	
	Items.SeparatorValue.Enabled = Var_Enabled;
	Items.SignInToDataAreaGroup.Enabled = Var_Enabled;
	
EndProcedure

#EndRegion
