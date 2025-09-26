
////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS
 
#Region EventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)

	EmploymentContract = GetEmploymentContractForEmployee(CurrentObject);
	EntityBeforeChange = CurrentObject.Entity;

	FillAdditionalColumns();

EndProcedure // OnReadAtServer()

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
	SetChoiceParameters();

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	IsNewRow = False;

EndProcedure

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

EndProcedure // EntityOnChange()

&AtClient
Procedure EmployeeOnChange(Item)

	EmployeeOnChangeAtServer();

EndProcedure

#EndRegion // Header

#Region TableLimitsForEmployees

&AtClient
Procedure LimitsForEmployeesOnActivateRow(Item)

	SetEditFormatLimit();

EndProcedure

&AtClient
Procedure LimitsForEmployeesTypeOfLimitOnChange(Item)

	FillAdditionalColumns(Items.LimitsForEmployees.CurrentRow);

	SetEditFormatLimit();

EndProcedure

#EndRegion // TableLimitsForEmployees

#EndRegion // ItemEventHandlers

////////////////////////////////////////////////////////////////////////////////
// PRIVATE

#Region Private

&AtServer
Procedure FillAdditionalColumns(CurrentRowID = Undefined)

	If CurrentRowID = Undefined Then
		arrLimitForEmployee = Object.LimitsForEmployees;
		mapAttribute = Common.ObjectsAttributesValues(Object.LimitsForEmployees.Unload().UnloadColumn("TypeOfLimit"), "AmountLimitControl, CountLimitControl, OneTime");
	Else
		CurrentRow = Object.LimitsForEmployees.FindByID(CurrentRowID);

		arrLimitForEmployee = New Array;
		arrLimitForEmployee.Add(CurrentRow);

		mapAttribute = New Map;
		mapAttribute.Insert(CurrentRow.TypeOfLimit, Common.ObjectAttributesValues(CurrentRow.TypeOfLimit, "AmountLimitControl, CountLimitControl, OneTime"));
	EndIf;

	For Each CurrentRow In arrLimitForEmployee Do

		CurrentRow.OneTime = mapAttribute[CurrentRow.TypeOfLimit].OneTime;

		If CurrentRow.OneTime Then
			CurrentRow.Stage = Undefined; 
		EndIf;

		If mapAttribute[CurrentRow.TypeOfLimit].CountLimitControl Then
			CurrentRow.ResourceType = 1;
		Else
			CurrentRow.ResourceType = 0;
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure SetEditFormatLimit()

	CurrentData = Items.LimitsForEmployees.CurrentData;

	If CurrentData = Undefined Then
		Return;
	EndIf;

	If CurrentData.ResourceType = 1 Then
		Items.LimitsForEmployeesLimit.EditFormat = "NFD=0";
	Else
		Items.LimitsForEmployeesLimit.EditFormat = "ND=15; NFD=2";
	EndIf;

EndProcedure

&AtServer
Procedure EmployeeOnChangeAtServer()

	NewEmploymentContract = GetEmploymentContractForEmployee();
	If EmploymentContract <> NewEmploymentContract Then
		
		For Each LimitsForEmployeesRow In Object.LimitsForEmployees Do
			LimitsForEmployeesRow.Stage = Undefined;
		EndDo;

		EmploymentContract = NewEmploymentContract;
	EndIf;
		
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
Procedure SetChoiceParameters()

	Query = New Query;
	Query.Text =
	"SELECT
	|	TypesOfLimitsForEmployees.Ref AS Ref
	|FROM
	|	Catalog.TypesOfLimitsForEmployees AS TypesOfLimitsForEmployees
	|WHERE
	|	(TypesOfLimitsForEmployees.CountLimitControl
	|			OR TypesOfLimitsForEmployees.AmountLimitControl)
	|	AND NOT TypesOfLimitsForEmployees.DeletionMark";

	arrTypeOfLimit = Query.Execute().Unload().UnloadColumn("Ref");

	arrChoiceParameters = New Array;
	arrChoiceParameters.Add(New ChoiceParameter("Filter.Ref", arrTypeOfLimit));

	Items.LimitsForEmployeesTypeOfLimit.ChoiceParameters = New FixedArray(arrChoiceParameters);

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	AppearanceItemsTemplate = ConditionalAppearanceServer.AppearanceItemsTemplate();

	///////////////////////////////////////////////////////////////////////////////////
	// Stage - ReadOnly
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	// ## Appearance
	AppearanceItems = New Structure(AppearanceItemsTemplate);
	AppearanceItems.ReadOnly = True;

	ConditionalAppearanceServer.SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems); 	

	// ## Items
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.LimitsForEmployeesStage);

	// ## Filter
	CommonClientServer.SetFilterItem(ConditionalAppearanceItem.Filter, "Object.LimitsForEmployees.OneTime", True); 

	///////////////////////////////////////////////////////////////////////////////////
	// Stage - MarkIncomplete
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	// ## Appearance
	AppearanceItems = New Structure(AppearanceItemsTemplate);
	AppearanceItems.MarkIncomplete = True;

	ConditionalAppearanceServer.SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems); 	

	// ## Items
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.LimitsForEmployeesStage);

	// ## Filter
	CommonClientServer.SetFilterItem(ConditionalAppearanceItem.Filter, "Object.LimitsForEmployees.OneTime", False); 
	CommonClientServer.SetFilterItem(ConditionalAppearanceItem.Filter, "Object.LimitsForEmployees.Stage",, DataCompositionComparisonType.NotFilled); 

	///////////////////////////////////////////////////////////////////////////////////
	// Format limit - Count
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	// ## Appearance
	AppearanceItems = New Structure(AppearanceItemsTemplate);
	AppearanceItems.Format = "NFD=0";

	ConditionalAppearanceServer.SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems); 	

	// ## Items	
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.LimitsForEmployeesLimit);

	// ## Filter
	CommonClientServer.SetFilterItem(ConditionalAppearanceItem.Filter, "Object.LimitsForEmployees.ResourceType", 1); 

	///////////////////////////////////////////////////////////////////////////////////
	// Format limit	- Amount
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	// ## Appearance
	AppearanceItems = New Structure(AppearanceItemsTemplate);
	AppearanceItems.Format = "ND=15; NFD=2";

	ConditionalAppearanceServer.SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems); 	

	// ## Items	
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.LimitsForEmployeesLimit);

	// ## Filter
	CommonClientServer.SetFilterItem(ConditionalAppearanceItem.Filter, "Object.LimitsForEmployees.ResourceType", 0);

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

#EndRegion // Private
