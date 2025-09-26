////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

#Region EventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)

	EntityBeforeChange = CurrentObject.Entity;
	EmploymentContract = GetEmploymentContractForEmployee(CurrentObject);

	If ValueIsFilled(CurrentObject.TypeOfLimits) Then
		TypeOfLimitOneTime = Common.ObjectAttributeValue(CurrentObject.TypeOfLimits, "OneTime");
	Else	
		TypeOfLimitOneTime = True;
	EndIf;

EndProcedure

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

	If Not ValueIsFilled(Object.TypeOfLimits) Then
		TypeOfLimitOneTime = True;
	EndIf;

	SetVisibility();
	SetConditionalAppearance();
	SetChoiceParameters();

EndProcedure // OnCreateAtServer()

#EndRegion // EventHandlers

////////////////////////////////////////////////////////////////////////////////
// ITEM EVENT HANDLERS  

#Region ItemEventHandlers

#Region Header

&AtClient
Procedure EntityOnChange(Item)

	If EntityBeforeChange <> Object.Entity Then

		Object.Number = "";

		EmployeeOnChangeAtServer();
	EndIf;

	EntityBeforeChange = Object.Entity;

EndProcedure

&AtClient
Procedure TypeOfLimitsOnChange(Item)

	TypeOfLimitsOnChangeAtServer();

EndProcedure

&AtClient
Procedure EmployeeOnChange(Item)

	EmployeeOnChangeAtServer();

EndProcedure

#EndRegion //Header

#EndRegion //ItemEventHandlers

////////////////////////////////////////////////////////////////////////////////
// PRIVATE
 
#Region Private

&AtServer
Procedure TypeOfLimitsOnChangeAtServer()

	If ValueIsFilled(Object.TypeOfLimits) Then
		TypeOfLimitOneTime = Common.ObjectAttributeValue(Object.TypeOfLimits, "OneTime");
	Else	
		TypeOfLimitOneTime = True;
	EndIf;

	SetVisibility();
	SetConditionalAppearance();

EndProcedure

&AtServer
Procedure EmployeeOnChangeAtServer()

	NewEmploymentContract = GetEmploymentContractForEmployee();
	If EmploymentContract <> NewEmploymentContract Then		
		Object.StageOfLimit = Undefined;
		EmploymentContract = NewEmploymentContract;
	EndIf;

	SetVisibility();

EndProcedure

&AtServer
Function GetEmploymentContractForEmployee(CurrentObject = Undefined)

	If CurrentObject = Undefined Then
		CurrentObject =  Object;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	EmployeesSliceFirst.EmploymentContract AS EmploymentContract
	|FROM
	|	InformationRegister._DemoCompaniesEmployees.SliceFirst(
	|			,
	|			Individual = &Employee
	|				AND Organization = &Entity) AS EmployeesSliceFirst";

	Query.SetParameter("Employee", CurrentObject.Employee);
	Query.SetParameter("Entity", CurrentObject.Entity);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		NewEmploymentContract = Selection.EmploymentContract;
	Else 
		NewEmploymentContract = Documents.EmploymentContract.EmptyRef();
	EndIf;

	Return NewEmploymentContract;

EndFunction

&AtServer
Procedure SetVisibility()

	Items.StageOfLimit.Visible = Not TypeOfLimitOneTime;

EndProcedure // SetVisibilityFromUserSettings()

&AtServer
Procedure SetChoiceParameters()

	arrTypeOfLimitPredefined = New Array;
	arrTypeOfLimitPredefined.Add(Catalogs.TypesOfLimitsForEmployees.TicketsHomeLeave);
	arrTypeOfLimitPredefined.Add(Catalogs.TypesOfLimitsForEmployees.TicketsRepatriation);

	Query = New Query;
	Query.Text =
	"SELECT
	|	TypesOfLimitsForEmployees.Ref AS Ref
	|FROM
	|	Catalog.TypesOfLimitsForEmployees AS TypesOfLimitsForEmployees
	|WHERE
	|	TypesOfLimitsForEmployees.Ref IN(&arrTypeOfLimitPredefined)
	|	AND NOT TypesOfLimitsForEmployees.DeletionMark";

	Query.SetParameter("arrTypeOfLimitPredefined", arrTypeOfLimitPredefined);

	arrTypeOfLimit = Query.Execute().Unload().UnloadColumn("Ref");

	arrChoiceParameters = New Array;
	arrChoiceParameters.Add(New ChoiceParameter("Filter.Ref", arrTypeOfLimit));

	Items.TypeOfLimits.ChoiceParameters = New FixedArray(arrChoiceParameters);

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	AppearanceItemsTemplate = ConditionalAppearanceServer.AppearanceItemsTemplate();

	///////////////////////////////////////////////////////////////////////////////////
	// Stage - MarkIncomplete
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	// ## Appearance
	AppearanceItems = New Structure(AppearanceItemsTemplate);
	AppearanceItems.MarkIncomplete = True;

	ConditionalAppearanceServer.SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems); 	

	// ## Items
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.StageOfLimit);

	// ## Filter
	CommonClientServer.SetFilterItem(ConditionalAppearanceItem.Filter, "TypeOfLimitOneTime", False); 
	CommonClientServer.SetFilterItem(ConditionalAppearanceItem.Filter, "Object.StageOfLimit",, DataCompositionComparisonType.NotFilled); 

EndProcedure 

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

#EndRegion //Private

