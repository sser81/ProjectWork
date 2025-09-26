////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS
 
#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	LimitsForEmployeesServer.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	If NOT ValueIsFilled(Object.Date) Then
		Object.Date = CurrentSessionDate();
	EndIf;

	SetConditionalAppearance();

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	LimitsForEmployeesServer.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

#EndRegion // EventHandlers

////////////////////////////////////////////////////////////////////////////////
// ITEM EVENT HANDLERS
 
#Region ItemEventHandlers

#Region Header

&AtClient
Procedure EmployeeOnChange(Item)

	ItemOnChange(Item);

EndProcedure

&AtClient
Procedure EntityOnChange(Item)

	ItemOnChange(Item);

EndProcedure

&AtClient
Procedure PeriodOnChange(Item)

	ItemOnChange(Item);

EndProcedure

&AtClient
Procedure EndContractDateOnChange(Item)

	ItemOnChange(Item);

EndProcedure

#EndRegion // Header

#Region TableLimitsForEmployees

&AtClient
Procedure LimitTypeListOnActivateRow(Item)

	LimitsForEmployeesClient.OnChangingCurrentLimitType(ThisObject);

EndProcedure

&AtClient
Procedure LimitsForEmployeesTableOnStartEdit(Item, NewRow, Clone)

	LimitsForEmployeesClient.LimitsForEmployeesTableOnStartEdit(ThisObject, Item, NewRow, Clone);

EndProcedure

&AtClient
Procedure LimitsForEmployeesTableOnEditEnd(Item, NewRow, CancelEdit)

	LimitsForEmployeesClient.LimitsForEmployeesTableOnEditEnd(ThisObject, Item, NewRow, CancelEdit);

EndProcedure

&AtClient
Procedure LimitsForEmployeesTableBeforeDeleteRow(Item, Cancel)

	LimitsForEmployeesClient.LimitsForEmployeesTableBeforeDeleteRow(ThisObject, Item, Cancel);

EndProcedure

&AtClient
Procedure LimitsForEmployeesTableAfterDeleteRow(Item)

	LimitsForEmployeesClient.LimitsForEmployeesTableAfterDeleteRow(ThisObject, Item);

EndProcedure

&AtClient
Procedure LimitsForEmployeesTableClearing(Item, StandardProcessing)

	LimitsForEmployeesClient.LimitsForEmployeesTableClearing(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure ItemOnChange(Item)

	LimitsForEmployeesClient.ItemOnChange(ThisObject, Item);

EndProcedure

#EndRegion // TableLimitsForEmployees

#EndRegion // ItemEventHandlers

////////////////////////////////////////////////////////////////////////////////
// COMMAND HANDLERS 

#Region CommandHandlers 

&AtClient
Procedure LimitsForEmployeesAction(Command)

	LimitsForEmployeesClient.LimitsForEmployeesAction(ThisObject, Command.Name);

EndProcedure

#EndRegion // CommandHandlers

////////////////////////////////////////////////////////////////////////////////
// PRIVATE

#Region Private

#Region ManageFormInterface

&AtServer
Procedure SetConditionalAppearance()

	LimitsForEmployeesServer.SetConditionalAppearanceLimitsForEmployees(ThisObject);

EndProcedure

&AtClient
Procedure ExecuteServerProc(ProcName, arrParameters) Export 

	ExecuteServerProcAtServer(ProcName, arrParameters);

EndProcedure

&AtServer
Procedure ExecuteServerProcAtServer(ProcName, arrParameters)

	Try
		StrParameters = StrConcat(arrParameters, ","); 
		Execute(ProcName + "(" + StrParameters + ")");
	Except
	EndTry;

EndProcedure

#EndRegion // ManageFormInterface

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion // Private
