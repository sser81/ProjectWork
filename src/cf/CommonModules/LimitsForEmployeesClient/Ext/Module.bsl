
Procedure LimitsForEmployeesTableOnStartEdit(Form, Item, NewRow, Clone) Export 

	CurrentData = Form.Items.LimitsForEmployeesTable.CurrentData;

	If NewRow Then
		CurrentData.TypeOfLimit = Form.TypeOfLimitCurrent;

		If Clone Then

			CurrentData.Stage = PredefinedValue("Catalog.StageOfLimitsForEmployees.EmptyRef");

			If Form.ItsContractChange Then
				CurrentData.OnlyChange = False;
			EndIf;
		EndIf;
	EndIf;

EndProcedure

Procedure LimitsForEmployeesTableOnEditEnd(Form, Item, NewRow, CancelEdit) Export

	If CancelEdit Then
		Return;
	EndIf;

	UpdateCountAtLimitTypeList(Form);

EndProcedure

Procedure LimitsForEmployeesTableBeforeDeleteRow(Form, Item, Cancel) Export 

	CurrentData = Form.Items.LimitsForEmployeesTable.CurrentData;

	If Form.ItsContractChange Then
		If CurrentData.OnlyChange Then
			Cancel = True;	
		EndIf;
	EndIf;

EndProcedure

Procedure LimitsForEmployeesTableAfterDeleteRow(Form, Item) Export 

	UpdateCountAtLimitTypeList(Form);
	CalculationDatesInLimitsForEmployeesTable(Form);

EndProcedure

Procedure LimitsForEmployeesTableClearing(Form, Item, StandardProcessing) Export 

	StandardProcessing = False;

	CurrentData = Form.Items.LimitsForEmployeesTable.CurrentData;

	StructureDates = New Structure("LimitDate, LimitDateEnd", CurrentData.LimitDate, CurrentData.LimitDateEnd);
	CurrentData.StageDescription = LimitsForEmployeesServer.GetStageDescription(StructureDates);
	CurrentData.StageDescriptionModify = False;

EndProcedure

Procedure ItemOnChange(Form, Item) Export 

	If Upper(Item.Name) = Upper("Period") Then
		Form.GenerateLimitPlanStartDate = Form.Object.Period;
	EndIf;

	If Upper(Item.Name) = Upper("EndContractDate") Then
		If Form.ItsContractChange Then
			FillEndContractDate(Form);
		EndIf;

		CalculationDatesInLimitsForEmployeesTable(Form);
	EndIf;

	If Upper(Item.Name) = Upper("ChangedEndContractData") Then
		FillEndContractDate(Form);

		CalculationDatesInLimitsForEmployeesTable(Form);
	EndIf;

	If Upper(Item.Name) = Upper("EmploymentContractType") Then
		CalculationDatesInLimitsForEmployeesTable(Form);
	EndIf;

	If Upper(Item.Name) = Upper("Employee") Then
		FillLimitsForEmployeesTable(Form);
	EndIf;

	If Upper(Item.Name) = Upper("Entity") Then
		FillLimitsForEmployeesTable(Form);
	EndIf;

	If Upper(Item.Name) = Upper("LimitsForEmployeesTableLimitDate") Then
		CalculationDatesInLimitsForEmployeesTable(Form);
	EndIf;

	If Upper(Item.Name) = Upper("LimitsForEmployeesTableStageDescription") Then
		CurrentData = Form.Items.LimitsForEmployeesTable.CurrentData;
		CurrentData.StageDescription = TrimAll(CurrentData.StageDescription);

		StructureDates = New Structure("StageDescription, LimitDate, LimitDateEnd", CurrentData.StageDescription, CurrentData.LimitDate, CurrentData.LimitDateEnd);
		CurrentData.StageDescriptionModify = LimitsForEmployeesServer.GetStageDescriptionModify(StructureDates);
	EndIf;

EndProcedure

Procedure OnChangingCurrentLimitType(Form) Export 

	Items = Form.Items;

	TypeOfLimitRow = PredefinedValue("Catalog.TypesOfLimitsForEmployees.EmptyRef");
	If Items.LimitTypeList.CurrentData <> Undefined Then 
		TypeOfLimitRow = Items.LimitTypeList.CurrentData.Ref;
	EndIf;

	If TypeOfLimitRow = Form.TypeOfLimitCurrent Then
		Return;
	EndIf;

	Items.LimitsForEmployeesTable.RowFilter = New FixedStructure("TypeOfLimit", TypeOfLimitRow);

	If ValueIsFilled(TypeOfLimitRow) Then

		ObjectAttributeValues = LimitsForEmployeesServer.GetAttributesTypeOfLimit(TypeOfLimitRow, "CountLimitControl, AmountLimitControl, OneTime");

		If ObjectAttributeValues.OneTime Then
			Items.GroupEmployeeLimitsPages.CurrentPage = Items.GroupEmployeeLimitsPageInformation;
		Else
			Items.GroupEmployeeLimitsPages.CurrentPage = Items.GroupEmployeeLimitsPageTable;

			If ObjectAttributeValues.CountLimitControl Then
				Items.LimitTypeListLimit.EditFormat = "NFD=0";
				Items.LimitsForEmployeesTableLimit.EditFormat = "NFD=0";
			Else
				Items.LimitTypeListLimit.EditFormat = "ND=15; NFD=2";
				Items.LimitsForEmployeesTableLimit.EditFormat = "ND=15; NFD=2";
			EndIf;
		EndIf;

		Items.LimitsForEmployeesTable.ReadOnly = False;
	Else
		Items.GroupEmployeeLimitsPages.CurrentPage = Items.GroupEmployeeLimitsPageInformation;
		Items.LimitsForEmployeesTable.ReadOnly = True;
	EndIf;

	Form.TypeOfLimitCurrent = TypeOfLimitRow;

EndProcedure

Procedure UpdateCountAtLimitTypeList(Form) Export 

	Form.ExecuteServerProc("LimitsForEmployeesServer.UpdateCountAtLimitTypeList", CommonClientServer.ValueInArray("ThisObject"));

EndProcedure

Procedure FillLimitsForEmployeesTable(Form) Export 

	Form.ExecuteServerProc("LimitsForEmployeesServer.FillLimitsForEmployeesTable", CommonClientServer.ValueInArray("ThisObject"));

EndProcedure

Procedure FillEndContractDate(Form) Export 

	Form.ExecuteServerProc("LimitsForEmployeesServer.FillEndContractDateInForm", CommonClientServer.ValueInArray("ThisObject"));

EndProcedure

Procedure LimitsForEmployeesAction(Form, CommandName) Export

	If Upper(CommandName) = Upper("GenerateLimitPlan") Then

		CallbackDescription = New CallbackDescription("GenerateLimitPlan", LimitsForEmployeesClient, New Structure("Form", Form));

		arrLimitsForEmployeesTable = Form.LimitsForEmployeesTable.FindRows(New Structure("TypeOfLimit", Form.TypeOfLimitCurrent));
		If arrLimitsForEmployeesTable.Count() Then
			QuestionText = NStr("ru = 'Таблица графика лимитов будет очищена. Продолжить?'; en = 'Current data in plan of limits will be deleted. Continue?'");
			ShowQueryBox(CallbackDescription, QuestionText, QuestionDialogMode.YesNo,,, NStr("ru = 'Формирование графика'; en = 'Generate plan'"));
		Else
			RunCallback(CallbackDescription, DialogReturnCode.Yes);
		EndIf;
	EndIf;

	If Upper(CommandName) = Upper("ChangeOfLimitsCheck") Then
		Form.Object.ChangeOfLimits = Not Form.Object.ChangeOfLimits;
		Form.ExecuteServerProc("LimitsForEmployeesServer.ChangeOfLimitsCheck", CommonClientServer.ValueInArray("ThisObject"));
		Form.Modified = True;
	EndIf;

EndProcedure

Procedure GenerateLimitPlan(Result, AdditionalParameters) Export

	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;

	AdditionalParameters.Form.ExecuteServerProc("LimitsForEmployeesServer.GenerateLimitPlan", CommonClientServer.ValueInArray("ThisObject"));

	UpdateCountAtLimitTypeList(AdditionalParameters.Form);

EndProcedure

Procedure CalculationDatesInLimitsForEmployeesTable(Form)

	lstLimitDate = New ValueList;
	mpLimitsForEmployeesTableRowToLimitDate = New Map;

	For Each LimitsForEmployeesTableRow In Form.LimitsForEmployeesTable Do
		If LimitsForEmployeesTableRow.TypeOfLimit = Form.TypeOfLimitCurrent Then

			LimitDate = LimitsForEmployeesTableRow.LimitDate;

			If Not ValueIsFilled(LimitDate) Then
				LimitsForEmployeesTableRow.LimitDateEnd = Date(1,1,1);
				Continue;
			EndIf;

			If lstLimitDate.FindByValue(LimitDate) = Undefined Then
				lstLimitDate.Add(LimitDate);
				mpLimitsForEmployeesTableRowToLimitDate.Insert(LimitDate, New Array);
			EndIf;

			mpLimitsForEmployeesTableRowToLimitDate[LimitDate].Add(LimitsForEmployeesTableRow);
		EndIf;
	EndDo;

	lstLimitDate.SortByValue(SortDirection.Desc);

	If Form.FormName = "Document.EmploymentContract.Form.DocumentForm" Then
		NewLimitDateEnd = Form.Object.EndContractDate;
	Else
		NewLimitDateEnd = Form.EndContractDate;
	EndIf;

	For Each ListItem In lstLimitDate Do

		If Not ValueIsFilled(NewLimitDateEnd) Then
			NewLimitDateEnd = AddMonth(ListItem.Value, 12) - 24*60*60;
		EndIf;

		For Each LimitsForEmployeesTableRow In mpLimitsForEmployeesTableRowToLimitDate[ListItem.Value] Do
			LimitsForEmployeesTableRow.LimitDateEnd = NewLimitDateEnd;

			If Not LimitsForEmployeesTableRow.StageDescriptionModify Then
				StructureDates = New Structure("LimitDate, LimitDateEnd", LimitsForEmployeesTableRow.LimitDate, LimitsForEmployeesTableRow.LimitDateEnd);
				LimitsForEmployeesTableRow.StageDescription = LimitsForEmployeesServer.GetStageDescription(StructureDates);
			EndIf;
		EndDo;

		NewLimitDateEnd = LimitsForEmployeesTableRow.LimitDate - 24*60*60;
	EndDo;

EndProcedure

#Region Reports_DetailProcessing

//Procedure ExpensesOfLimits_DetailProcessing(DetailsContext, StandardProcessing) Export 

//	StringLiterals = StringLiteralsClientServer.ReportDetails();

//	ReportName = DetailsContext.Form.ObjectKey;

//	If ReportName <> "Report.ExpensesOfLimits" Then
//		Return;
//	EndIf;

//	DetailsStructure = ReportDetailsServerCall.GetDetailsStructure(DetailsContext.DetailsDataAddress, DetailsContext.DetailValue, True);

//	IsRequiredStandardProcessing =
//		Not (DetailsStructure.Fields.Property("DetailsType"))
//		Or Not (DetailsStructure.Fields.DetailsType = StringLiterals.DetailsByRecorder) 
//		Or Not (DetailsContext.ReportVariant		= "ExpensesOfLimits");
//	
//	If IsRequiredStandardProcessing Then
//		Return;
//	EndIf;

//	StandardProcessing = False;

//	If Not (DetailsStructure.Fields.Property("Value"))
//		Or DetailsContext.ReportVariant = StringLiterals.DetailsByRecorder Then
//		Return;
//	EndIf;

//	EncryptingFilters = New Map;

//	For Each CurField In DetailsStructure.Parents Do
//		EncryptingFilters.Insert(CurField.Key, CurField.Value);
//	EndDo;

//	FilterParameters = New Structure;
//	FilterParameters.Insert("EncryptingFilters",    EncryptingFilters);
//	FilterParameters.Insert("GenerateOnOpen",       True);
//	FilterParameters.Insert("EncryptingMode",       True);
//	FilterParameters.Insert("CustomParameters",     DetailsStructure.Parameters); 
//	FilterParameters.Insert("EncryptingParameters", DetailsStructure.Parameters);
//	FilterParameters.Insert("VariantKey",           StringLiterals.DetailsByRecorder);
//	FilterParameters.Insert("Fields",               DetailsStructure.Fields);

//	OpenForm("Report.ExpensesOfLimits.ObjectForm", FilterParameters, , True);

//EndProcedure

#EndRegion
