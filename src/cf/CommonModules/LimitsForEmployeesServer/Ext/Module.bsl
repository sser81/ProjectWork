////////////////////////////////////////////////////////////////////////////////
// FORM EVENTS (SERVER). PUBLIC
 
#Region Public

Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export 

	InitializationAttributesForm(Form);
	
	If Form.FormName = "Document.EmploymentContract.Form.DocumentForm" Then

		Object = Form.Object;
	
		FillLimitsForEmployeesTable(Form);
		FillLimitTypeList(Form);

		If Form.LimitTypeList.Count() Then
			Form.Items.LimitTypeList.CurrentRow = Form.LimitTypeList[0].GetID();
		EndIf;

		Form.GenerateLimitPlanStartDate = Object.Period;
	EndIf;

EndProcedure

Procedure BeforeWriteAtServer(Form, Cancel, CurrentObject, WriteParameters) Export 

	LimitsForEmployees = Form.LimitsForEmployeesTable.Unload();
	LimitsForEmployees.Columns.Add("NotApplicable", New TypeDescription("Boolean"));

	// помимо графиков периодических лимитов в табличную часть необходимо добавить строчки основного списка лимитов
	For Each LimitTypeListRow In Form.LimitTypeList Do

		If Not ValueIsFilled(LimitTypeListRow.Limit) And LimitTypeListRow.ResourceType <> 2 Then
			Continue;
		EndIf;

		LimitsForEmployeesRow = LimitsForEmployees.Add();
		LimitsForEmployeesRow.TypeOfLimit	= LimitTypeListRow.Ref;
		LimitsForEmployeesRow.Limit			= LimitTypeListRow.Limit;

		If LimitTypeListRow.ResourceType = 2 Then //CheckLimitControl
			LimitsForEmployeesRow.NotApplicable	= Not LimitTypeListRow.LimitCheck;
		EndIf;
	EndDo;

	CurrentObject.LimitsForEmployees.Load(LimitsForEmployees);

EndProcedure

#EndRegion // Public

////////////////////////////////////////////////////////////////////////////////

Procedure InitializationAttributesForm(Form)

	If Form.FormName = "Document.EmploymentContract.Form.DocumentForm" Then

		#Region Attributes	
		///////////////////////////////////////////////////////////////////////////////////
		//Attributes
		AddAttributes = New Array;
		AddAttributes.Add(New FormAttribute("TypeOfLimitCurrent", New TypeDescription("CatalogRef.TypesOfLimitsForEmployees")));
		AddAttributes.Add(New FormAttribute("GenerateLimitPlanStartDate",
											New TypeDescription("Date", New DateQualifiers(DateFractions.Date)),,
											NStr("ru = 'Дата начала'; en = 'Start date'")));
		// LimitTypeList
		AddAttributes.Add(New FormAttribute("LimitTypeList", New TypeDescription("ValueTable"),, NStr("ru = 'Виды лимитов'; en = 'Limit types'"), True));

		AddAttributes.Add(New FormAttribute("Ref", New TypeDescription("CatalogRef.TypesOfLimitsForEmployees"), "LimitTypeList"));
		AddAttributes.Add(New FormAttribute("Periodic", New TypeDescription("Boolean"), "LimitTypeList"));
		AddAttributes.Add(New FormAttribute("CountStage", New TypeDescription("Number"), "LimitTypeList"));
		AddAttributes.Add(New FormAttribute("Description",
											New TypeDescription("String"),
											"LimitTypeList",
											NStr("ru = 'Вид лимита'; en = 'Type of limit'")));

		AddAttributes.Add(New FormAttribute("Limit", 
											New TypeDescription("Number", New NumberQualifiers(15,2)),
											"LimitTypeList"));

		AddAttributes.Add(New FormAttribute("LimitCheck", 
											New TypeDescription("Boolean"),
											"LimitTypeList"));

		AddAttributes.Add(New FormAttribute("ResourceType", 
											New TypeDescription("Number"),
											"LimitTypeList",
											NStr("ru = 'Тип значения лимита'; en = 'Type of limit value'")));

		// LimitsForEmployeesTable
		AddAttributes.Add(New FormAttribute("LimitsForEmployeesTable", New TypeDescription("ValueTable"),, NStr("ru = 'Лимиты'; en = 'Limits'"), True));

		AddAttributes.Add(New FormAttribute("TypeOfLimit", 
											New TypeDescription("CatalogRef.TypesOfLimitsForEmployees"),
											"LimitsForEmployeesTable",
											NStr("ru = 'Вид лимита'; en = 'Type of limit'")));

		AddAttributes.Add(New FormAttribute("LimitDate",
											New TypeDescription("Date",,, New DateQualifiers(DateFractions.Date)),
											"LimitsForEmployeesTable",
											NStr("ru = 'Начало периода'; en = 'Start date'")));

		AddAttributes.Add(New FormAttribute("LimitDateEnd",
											New TypeDescription("Date",,, New DateQualifiers(DateFractions.Date)),
											"LimitsForEmployeesTable",
											NStr("ru = 'Окончание периода'; en = 'End date'")));

		AddAttributes.Add(New FormAttribute("Stage", 
											New TypeDescription("CatalogRef.StageOfLimitsForEmployees"),
											"LimitsForEmployeesTable",
											NStr("ru = 'Этап'; en = 'Stage'")));

		AddAttributes.Add(New FormAttribute("StageDescription", 
											New TypeDescription("String"),
											"LimitsForEmployeesTable",
											NStr("ru = 'Этап'; en = 'Stage'")));

		AddAttributes.Add(New FormAttribute("StageDescriptionModify", 
											New TypeDescription("Boolean"),
											"LimitsForEmployeesTable"));

		AddAttributes.Add(New FormAttribute("Limit", 
											New TypeDescription("Number", New NumberQualifiers(15,2)),
											"LimitsForEmployeesTable",
											NStr("ru = 'Лимит'; en = 'Limit'")));

		Form.ChangeAttributes(AddAttributes);

		#EndRegion // Attributes

		#Region Commands	
		///////////////////////////////////////////////////////////////////////////////////
		//Commands
		GenerateLimitPlanComand = Form.Commands.Add("GenerateLimitPlan");
		GenerateLimitPlanComand.Title = NStr("ru = 'Сформировать'; en = 'Generate'");
		GenerateLimitPlanComand.Action = "LimitsForEmployeesAction";

		#EndRegion //Commands

		#Region Items	
		///////////////////////////////////////////////////////////////////////////////////
		//Items
		Items = Form.Items;

		If Items.Find("Pages") <> Undefined Then

			GroupPage = Items.Add("PageEmployeeLimits", Type("FormGroup"), Items.Pages);
			GroupPage.Type = FormGroupType.Page;
			GroupPage.Title = NStr("ru = 'Лимиты'; en = 'Limits'");

			GroupEmployeeLimits = Items.Add("GroupEmployeeLimits", Type("FormGroup"), GroupPage);
			GroupEmployeeLimits.Type = FormGroupType.UsualGroup;
			GroupEmployeeLimits.Group = ChildFormItemsGroup.AlwaysHorizontal;
			GroupEmployeeLimits.ShowTitle = False;

			// LimitTypeList
			LimitTypeList = Items.Add("LimitTypeList", Type("FormTable"), GroupEmployeeLimits);
			LimitTypeList.DataPath = "LimitTypeList";
			LimitTypeList.ChangeRowSet = False;
			LimitTypeList.CommandBarLocation = FormItemCommandBarLabelLocation.None;
			LimitTypeList.ViewStatusLocation = ViewStatusLocation.None;
			LimitTypeList.AutoMaxWidth = False;
			LimitTypeList.MaxWidth = 50;
			LimitTypeList.MultipleChoice = False;

			LimitTypeListOnTime = Items.Add("LimitTypeListOnTime", Type("FormField"), LimitTypeList);
			LimitTypeListOnTime.Type = FormFieldType.CheckBoxField;
			LimitTypeListOnTime.DataPath = "LimitTypeList.Periodic";
			LimitTypeListOnTime.HeaderPicture = PictureLib.Calendar;
			LimitTypeListOnTime.ReadOnly = True;
			LimitTypeListOnTime.TitleLocation = FormItemTitleLocation.None;

			LimitTypeListDescription = Items.Add("LimitTypeListDescription", Type("FormField"), LimitTypeList);
			LimitTypeListDescription.Type = FormFieldType.InputField;
			LimitTypeListDescription.DataPath = "LimitTypeList.Description";
			LimitTypeListDescription.ReadOnly = True;
			LimitTypeListDescription.Width = 30;

			LimitTypeListLimitGroup = Items.Add("LimitTypeListLimitGroup", Type("FormGroup"), LimitTypeList);
			LimitTypeListLimitGroup.Type = FormGroupType.ColumnGroup;
			LimitTypeListLimitGroup.Title = NStr("ru = 'Лимит'; en = 'Limit'");
			LimitTypeListLimitGroup.ShowInHeader = True;

			LimitTypeListLimit = Items.Add("LimitTypeListLimit", Type("FormField"), LimitTypeListLimitGroup);
			LimitTypeListLimit.Type = FormFieldType.InputField;
			LimitTypeListLimit.DataPath = "LimitTypeList.Limit";
			LimitTypeListLimit.Width = 10;
			LimitTypeListLimit.EditMode = ColumnEditMode.EnterOnInput;
			LimitTypeListLimit.ShowInHeader = False;

			LimitTypeListLimitCheck = Items.Add("LimitTypeListLimitCheck", Type("FormField"), LimitTypeListLimitGroup);
			LimitTypeListLimitCheck.Type = FormFieldType.CheckBoxField;
			LimitTypeListLimitCheck.DataPath = "LimitTypeList.LimitCheck";
			LimitTypeListLimitCheck.EditMode = ColumnEditMode.EnterOnInput;
			LimitTypeListLimitCheck.ShowInHeader = False;

			LimitTypeList.SetAction("OnActivateRow", "LimitTypeListOnActivateRow");

			// LimitsForEmployeesTable - Pages
			GroupEmployeeLimitsPages = Items.Add("GroupEmployeeLimitsPages", Type("FormGroup"), GroupEmployeeLimits);
			GroupEmployeeLimitsPages.Type = FormGroupType.Pages;
			GroupEmployeeLimitsPages.PagesRepresentation = FormPagesRepresentation.None;

			GroupEmployeeLimitsPageTable = Items.Add("GroupEmployeeLimitsPageTable", Type("FormGroup"), GroupEmployeeLimitsPages);
			GroupEmployeeLimitsPageTable.Type = FormGroupType.Page;
			GroupEmployeeLimitsPageTable.Group = ChildFormItemsGroup.Vertical;

			GroupEmployeeLimitsPageInformation = Items.Add("GroupEmployeeLimitsPageInformation", Type("FormGroup"), GroupEmployeeLimitsPages);
			GroupEmployeeLimitsPageInformation.Type = FormGroupType.Page;
			GroupEmployeeLimitsPageInformation.Group = ChildFormItemsGroup.AlwaysHorizontal;

			// LimitsForEmployeesTable - Commands
			GroupEmployeeLimitsTableCommands = Items.Add("GroupEmployeeLimitsTableCommands", Type("FormGroup"), GroupEmployeeLimitsPageTable);
			GroupEmployeeLimitsTableCommands.Type = FormGroupType.UsualGroup;
			GroupEmployeeLimitsTableCommands.ShowTitle = False;
			GroupEmployeeLimitsTableCommands.Group = ChildFormItemsGroup.AlwaysHorizontal;

			GenerateLimitPlanStartDate = Items.Add("GenerateLimitPlanStartDate", Type("FormField"), GroupEmployeeLimitsTableCommands);
			GenerateLimitPlanStartDate.Type = FormFieldType.InputField;
			GenerateLimitPlanStartDate.DataPath = "GenerateLimitPlanStartDate";
			GenerateLimitPlanStartDate.HorizontalStretch = False;

			CommandLimitsForEmployeesGenerateLimitPlan = Items.Add("CommandLimitsForEmployeesGenerateLimitPlan", Type("FormButton"), GroupEmployeeLimitsTableCommands);
			CommandLimitsForEmployeesGenerateLimitPlan.Type = FormButtonType.UsualButton;
			CommandLimitsForEmployeesGenerateLimitPlan.CommandName = "GenerateLimitPlan";

			// LimitsForEmployeesTable - Table
			LimitsForEmployeesTable = Items.Add("LimitsForEmployeesTable", Type("FormTable"), GroupEmployeeLimitsPageTable);
			LimitsForEmployeesTable.DataPath = "LimitsForEmployeesTable";
			LimitsForEmployeesTable.ViewStatusLocation = ViewStatusLocation.None;
			LimitsForEmployeesTable.SearchStringLocation = SearchStringLocation.None;
			LimitsForEmployeesTable.AutoInsertNewRow = False;

			LimitsForEmployeesTableStageGroup = Items.Add("LimitsForEmployeesTableStageGroup", Type("FormGroup"), LimitsForEmployeesTable);
			LimitsForEmployeesTableStageGroup.Type = FormGroupType.ColumnGroup;
			LimitsForEmployeesTableStageGroup.Group = ColumnsGroup.Horizontal;
			LimitsForEmployeesTableStageGroup.Title = NStr("ru = 'Период (этап)'; en = 'Period (stage)'");
			LimitsForEmployeesTableStageGroup.ShowInHeader = True;

			LimitsForEmployeesTableLimitDate = Items.Add("LimitsForEmployeesTableLimitDate", Type("FormField"), LimitsForEmployeesTableStageGroup);
			LimitsForEmployeesTableLimitDate.Type = FormFieldType.InputField;
			LimitsForEmployeesTableLimitDate.DataPath = "LimitsForEmployeesTable.LimitDate";
			LimitsForEmployeesTableLimitDate.Title = NStr("ru = 'дата'; en = 'date'");
			LimitsForEmployeesTableLimitDate.Width = 10;
			LimitsForEmployeesTableLimitDate.HorizontalStretch = False;
			LimitsForEmployeesTableLimitDate.ShowInHeader = False;
			LimitsForEmployeesTableLimitDate.EditMode = ColumnEditMode.EnterOnInput;

			LimitsForEmployeesTableStageDescriptionGroup = Items.Add("LimitsForEmployeesTableStageDescriptionGroup", Type("FormGroup"), LimitsForEmployeesTableStageGroup);
			LimitsForEmployeesTableStageDescriptionGroup.Type = FormGroupType.ColumnGroup;
			LimitsForEmployeesTableStageDescriptionGroup.Group = ColumnsGroup.Horizontal;

			LimitsForEmployeesTableStageDescription = Items.Add("LimitsForEmployeesTableStageDescription", Type("FormField"), LimitsForEmployeesTableStageDescriptionGroup);
			LimitsForEmployeesTableStageDescription.Type = FormFieldType.InputField;
			LimitsForEmployeesTableStageDescription.DataPath = "LimitsForEmployeesTable.StageDescription";
			LimitsForEmployeesTableStageDescription.Title = NStr("ru = 'наименование'; en = 'description'");
			LimitsForEmployeesTableStageDescription.ShowInHeader = False;
			LimitsForEmployeesTableStageDescription.EditMode = ColumnEditMode.EnterOnInput;
			LimitsForEmployeesTableStageDescription.ClearButton = True;

			LimitsForEmployeesTableLimit = Items.Add("LimitsForEmployeesTableLimit", Type("FormField"), LimitsForEmployeesTable);
			LimitsForEmployeesTableLimit.Type = FormFieldType.InputField;
			LimitsForEmployeesTableLimit.DataPath = "LimitsForEmployeesTable.Limit";
			LimitsForEmployeesTableLimit.EditMode = ColumnEditMode.EnterOnInput;

			// action
			LimitsForEmployeesTable.SetAction("OnStartEdit", "LimitsForEmployeesTableOnStartEdit");
			LimitsForEmployeesTable.SetAction("OnEditEnd", "LimitsForEmployeesTableOnEditEnd");
			LimitsForEmployeesTable.SetAction("BeforeDeleteRow", "LimitsForEmployeesTableBeforeDeleteRow");
			LimitsForEmployeesTable.SetAction("AfterDeleteRow", "LimitsForEmployeesTableAfterDeleteRow");
			LimitsForEmployeesTableLimitDate.SetAction("OnChange", "ItemOnChange");
			LimitsForEmployeesTableStageDescription.SetAction("Clearing", "LimitsForEmployeesTableClearing");
			LimitsForEmployeesTableStageDescription.SetAction("OnChange", "ItemOnChange");

			// Information group from type of limit
			LimitsForEmployeesInformationPicture = Items.Add("LimitsForEmployeesInformationPicture", Type("FormDecoration"), GroupEmployeeLimitsPageInformation);
			LimitsForEmployeesInformationPicture.Type = FormDecorationType.Picture;
			LimitsForEmployeesInformationPicture.Picture = PictureLib.Information32;

			LimitsForEmployeesInformationText = Items.Add("LimitsForEmployeesInformationText", Type("FormDecoration"), GroupEmployeeLimitsPageInformation);
			LimitsForEmployeesInformationText.Type = FormDecorationType.Label;
			LimitsForEmployeesInformationText.Title = NStr("en = 'The current type of limit is a one-time limit. Plan of limit isn''t need.';
															|ru = 'Текущий вид лимита является единоразовым и ввод графика не предусмотрен.'");
			LimitsForEmployeesInformationText.TextColor = New Color(25, 85, 174);
			LimitsForEmployeesInformationText.Font = New Font(LimitsForEmployeesInformationText.Font,,, True);
		EndIf;

		#EndRegion //Items

	EndIf;

EndProcedure

Function GetAttributesEmploymentContractForEmployee(Employee, Entity, Attributes = "") Export

	Return Common.ObjectAttributesValues(GetEmploymentContractForEmployee(Employee, Entity), Attributes);

EndFunction

Function GetAttributesTypeOfLimit(TypeOfLimit, StrAttributes) Export 

	Return Common.ObjectAttributesValues(TypeOfLimit, StrAttributes);

EndFunction

Function GetEmploymentContractForEmployee(Employee, Entity) Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	EmployeesSliceFirst.EmploymentContract AS EmploymentContract
	|FROM
	|	InformationRegister._DemoCompaniesEmployees.SliceFirst(
	|			,
	|			Individual = &Employee
	|				AND Organization = &Entity) AS EmployeesSliceFirst";

	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Entity", Entity);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		EmploymentContract = Selection.EmploymentContract;
	Else 
		EmploymentContract = Documents.EmploymentContract.EmptyRef();
	EndIf;

	Return EmploymentContract;

EndFunction

Procedure FillEndContractDateInForm(Form) Export 

	Object = Form.Object;

	If Object.ChangedEndContractData Then
		EndContractDate = Object.EndContractDate
	Else
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	HistoryOfEmploymentContract.EndContractDate AS EndContractDate
		|FROM
		|	InformationRegister.HistoryOfEmploymentContract.SliceLast(
		|			&OnDate,
		|			Employee = &Employee
		|				AND Entity = &Entity) AS HistoryOfEmploymentContract";

		Query.SetParameter("OnDate", Object.Period);
		Query.SetParameter("Employee", Object.Employee);
		Query.SetParameter("Entity", Object.Entity);

		Selection = Query.Execute().Select();
		If Selection.Next() Then
			EndContractDate = Selection.EndContractDate;
		Else 
			AttributesEmploymentContract = GetAttributesEmploymentContractForEmployee(Object.Employee, Object.Entity, "EndContractDate");
			EndContractDate = AttributesEmploymentContract.EndContractDate;
		EndIf;
	EndIf;

	Form.EndContractDate = EndContractDate;

EndProcedure

#Region Contract
	
Procedure SetConditionalAppearanceLimitsForEmployees(Form) Export 

	Items 					= Form.Items;
	ConditionalAppearance 	= Form.ConditionalAppearance;

	AppearanceItemsTemplate = ConditionalAppearanceServer.AppearanceItemsTemplate();

	///////////////////////////////////////////////////////////////////////////////////
	// LimitTypeList
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	// ## Appearance
	AppearanceItems = New Structure(AppearanceItemsTemplate);
	AppearanceItems.Font = New Font(Items.LimitTypeList.Font,,, True);

	ConditionalAppearanceServer.SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems); 	

	// ## Items	
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.LimitTypeList);

	// ## Filter
	LimitTypeListGroup1 = CommonClientServer.CreateFilterItemGroup(ConditionalAppearanceItem.Filter.Items, "LimitTypeListGroup1", DataCompositionFilterItemsGroupType.OrGroup);
	CommonClientServer.SetFilterItem(LimitTypeListGroup1, "LimitTypeList.CountStage",, DataCompositionComparisonType.Filled); 
	CommonClientServer.SetFilterItem(LimitTypeListGroup1, "LimitTypeList.Limit",, DataCompositionComparisonType.Filled); 
	CommonClientServer.SetFilterItem(LimitTypeListGroup1, "LimitTypeList.LimitCheck", True); 

	///////////////////////////////////////////////////////////////////////////////////
	// Format limit - Count
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	// ## Appearance
	AppearanceItems = New Structure(AppearanceItemsTemplate);
	AppearanceItems.Format = "NFD=0";

	ConditionalAppearanceServer.SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems); 	

	// ## Items	
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.LimitTypeListLimit);
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.LimitsForEmployeesTableLimit);

	// ## Filter
	CommonClientServer.SetFilterItem(ConditionalAppearanceItem.Filter, "LimitTypeList.ResourceType", 1); 

	///////////////////////////////////////////////////////////////////////////////////
	// Format limit	- Amount
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	// ## Appearance
	AppearanceItems = New Structure(AppearanceItemsTemplate);
	AppearanceItems.Format = "ND=15; NFD=2";

	ConditionalAppearanceServer.SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems); 	

	// ## Items	
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.LimitTypeListLimit);
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.LimitsForEmployeesTableLimit);

	// ## Filter
	CommonClientServer.SetFilterItem(ConditionalAppearanceItem.Filter, "LimitTypeList.ResourceType", 0);

	///////////////////////////////////////////////////////////////////////////////////
	// Visible - Limit
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	// ## Appearance
	AppearanceItems = New Structure(AppearanceItemsTemplate);
	AppearanceItems.Visible = False;

	ConditionalAppearanceServer.SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems); 	

	// ## Items	
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.LimitTypeListLimit);

	// ## Filter
	lstResourceType = New ValueList;
	lstResourceType.Add(0);
	lstResourceType.Add(1);
	CommonClientServer.SetFilterItem(ConditionalAppearanceItem.Filter, "LimitTypeList.ResourceType", lstResourceType, DataCompositionComparisonType.NotInList);

	///////////////////////////////////////////////////////////////////////////////////
	// Visible - LimitCheck
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	// ## Appearance
	AppearanceItems = New Structure(AppearanceItemsTemplate);
	AppearanceItems.Visible = False;

	ConditionalAppearanceServer.SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems); 	

	// ## Items	
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.LimitTypeListLimitCheck);

	// ## Filter
	lstResourceType = New ValueList;
	lstResourceType.Add(2);
	CommonClientServer.SetFilterItem(ConditionalAppearanceItem.Filter, "LimitTypeList.ResourceType", lstResourceType, DataCompositionComparisonType.NotInList);

	///////////////////////////////////////////////////////////////////////////////////
	// StageDescription
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	// ## Appearance
	AppearanceItems = New Structure(AppearanceItemsTemplate);
	AppearanceItems.TextColor = WebColors.Sienna;

	ConditionalAppearanceServer.SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems); 	

	// ## Items	
	ConditionalAppearanceServer.AddFormItem(ConditionalAppearanceItem, Items.LimitsForEmployeesTableStageDescription);

	// ## Filter
	CommonClientServer.SetFilterItem(ConditionalAppearanceItem.Filter, "LimitsForEmployeesTable.StageDescriptionModify", True);

EndProcedure

Procedure FillLimitTypeList(Form) Export 

	Object = Form.Object;

	LimitsForEmployees = Object.LimitsForEmployees.Unload();

	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("LimitsForEmployees", LimitsForEmployees);
	Query.Text = "SELECT * INTO ttLimitsForEmployees FROM &LimitsForEmployees AS LimitsForEmployees";
	Query.Execute();
	
	Query.Text =
	"SELECT
	|	TypesOfLimitsForEmployees.Ref AS Ref,
	|	CASE
	|		WHEN TypesOfLimitsForEmployees.CheckLimitControl
	|			THEN 2
	|		WHEN TypesOfLimitsForEmployees.CountLimitControl
	|			THEN 1
	|		ELSE 0
	|	END AS ResourceType,
	|	CASE
	|		WHEN TypesOfLimitsForEmployees.CheckLimitControl
	|			THEN 0
	|		WHEN NOT ttLimitsForEmployees.TypeOfLimit IS NULL
	|			THEN ttLimitsForEmployees.Limit
	|		WHEN NOT EmployeeLimitPlaningSliceLast.TypeOfLimit IS NULL
	|			THEN EmployeeLimitPlaningSliceLast.Limit
	|		ELSE 0
	|	END AS Limit,
	|	CASE
	|		WHEN NOT TypesOfLimitsForEmployees.CheckLimitControl
	|			THEN FALSE
	|		WHEN NOT ttLimitsForEmployees.TypeOfLimit IS NULL
	|			THEN NOT ttLimitsForEmployees.NotApplicable
	|		WHEN NOT EmployeeLimitPlaningSliceLast.TypeOfLimit IS NULL
	|			THEN NOT EmployeeLimitPlaningSliceLast.NotApplicable
	|		ELSE FALSE
	|	END AS LimitCheck,
	|	NOT TypesOfLimitsForEmployees.OneTime AS Periodic
	|FROM
	|	Catalog.TypesOfLimitsForEmployees AS TypesOfLimitsForEmployees
	|
	|		LEFT JOIN ttLimitsForEmployees AS ttLimitsForEmployees
	|		ON TypesOfLimitsForEmployees.Ref = ttLimitsForEmployees.TypeOfLimit
	|			AND (ttLimitsForEmployees.Stage = &Stage_EmptyRef)
	|
	|		LEFT JOIN InformationRegister.EmployeeLimitPlaning.SliceLast(
	|				&DateObject,
	|				Entity = &Entity
	|					AND Employee = &Employee
	|					AND Stage = &Stage_EmptyRef
	|					AND Recorder <> &ObjectRef) AS EmployeeLimitPlaningSliceLast
	|		ON TypesOfLimitsForEmployees.Ref = EmployeeLimitPlaningSliceLast.TypeOfLimit
	|WHERE
	|	NOT TypesOfLimitsForEmployees.DeletionMark
	|
	|ORDER BY
	|	Ref";

	Query.SetParameter("ObjectRef", Object.Ref);
	Query.SetParameter("DateObject", Object.Period);
	Query.SetParameter("Entity", Object.Entity);
	Query.SetParameter("Employee", Object.Employee);
	Query.SetParameter("Stage_EmptyRef", Catalogs.StageOfLimitsForEmployees.EmptyRef());

	Form.LimitTypeList.Load(Query.Execute().Unload());

	UpdateCountAtLimitTypeList(Form);

	Form.LimitTypeList.Sort("Description");

EndProcedure

Procedure UpdateCountAtLimitTypeList(Form) Export 

	LimitsForEmployeesTable = Form.LimitsForEmployeesTable.Unload();

	Ind = 0;
	While Ind < LimitsForEmployeesTable.Count() Do
		If ValueIsFilled(LimitsForEmployeesTable[Ind].StageDescription) Then
			Ind = Ind + 1;
		Else
			LimitsForEmployeesTable.Delete(Ind);
		EndIf;
	EndDo;

	LimitsForEmployeesTable.Columns.Add("CountStage", New TypeDescription("Number"));
	LimitsForEmployeesTable.FillValues(1, "CountStage");
	LimitsForEmployeesTable.GroupBy("TypeOfLimit", "CountStage");
	LimitsForEmployeesTable.Indexes.Add("TypeOfLimit");

	For Each LimitTypeListRow In Form.LimitTypeList Do

		LimitsForEmployeesRow = LimitsForEmployeesTable.Find(LimitTypeListRow.Ref, "TypeOfLimit");

		If LimitsForEmployeesRow <> Undefined Then
			LimitTypeListRow.CountStage = LimitsForEmployeesRow.CountStage;
			LimitTypeListRow.Description = StrTemplate("%1 (%2)", String(LimitTypeListRow.Ref), String(LimitTypeListRow.CountStage));
		Else
			LimitTypeListRow.CountStage = 0;
			LimitTypeListRow.Description = String(LimitTypeListRow.Ref);
		EndIf;
	EndDo;

EndProcedure

Procedure FillLimitsForEmployeesTable(Form) Export 

	Object = Form.Object;

	LimitsForEmployees = Object.LimitsForEmployees.Unload();

	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("LimitsForEmployees", LimitsForEmployees);
	Query.Text = "SELECT * INTO ttLimitsForEmployees FROM &LimitsForEmployees AS LimitsForEmployees";
	Query.Execute();

		Query.Text =
		"SELECT
		|	ttLimitsForEmployees.LimitDate AS LimitDate,
		|	ttLimitsForEmployees.LimitDateEnd AS LimitDateEnd,
		|	ttLimitsForEmployees.TypeOfLimit AS TypeOfLimit,
		|	CASE
		|		WHEN ttLimitsForEmployees.Stage <> &Stage_EmptyRef
		|				AND StageOfLimitsForEmployees.EmploymentContract = &ContractRef
		|			THEN ttLimitsForEmployees.Stage
		|		ELSE &Stage_EmptyRef
		|	END AS Stage,
		|	ttLimitsForEmployees.StageDescription AS StageDescription,
		|	ttLimitsForEmployees.Limit AS Limit
		|FROM
		|	ttLimitsForEmployees AS ttLimitsForEmployees
		|
		|		LEFT JOIN Catalog.StageOfLimitsForEmployees AS StageOfLimitsForEmployees
		|		ON ttLimitsForEmployees.Stage = StageOfLimitsForEmployees.Ref
		|
		|WHERE
		|	ttLimitsForEmployees.Stage <> &Stage_EmptyRef
		|
		|ORDER BY
		|	TypeOfLimit,
		|	LimitDate,
		|	LimitDateEnd";

	Query.SetParameter("ObjectRef", Object.Ref);
	Query.SetParameter("DateObject", Object.Period);
	Query.SetParameter("Entity", Object.Entity);
	Query.SetParameter("Employee", Object.Employee);
	Query.SetParameter("Stage_EmptyRef", Catalogs.StageOfLimitsForEmployees.EmptyRef());
	Query.SetParameter("ContractRef", Object.Ref);

	LimitsForEmployeesTable = Query.Execute().Unload();

	Form.LimitsForEmployeesTable.Load(LimitsForEmployeesTable);

	For Each LimitsForEmployeesTableRow In Form.LimitsForEmployeesTable Do
		LimitsForEmployeesTableRow.StageDescriptionModify = GetStageDescriptionModify(LimitsForEmployeesTableRow);
	EndDo;

EndProcedure

Procedure GenerateLimitPlan(Form) Export 

	Object = Form.Object;

	If ValueIsFilled(Form.GenerateLimitPlanStartDate) Then
		CurrentDate = Form.GenerateLimitPlanStartDate;
	Else
		CurrentDate = Form.Object.Period;
	EndIf;

	If ValueIsFilled(Object.EndContractDate)
		And Object.EmploymentContractType = Enums.EmploymentContractTypes.LimitedTermContract Then

		EndContractDate = Form.Object.EndContractDate;
	Else
		EndContractDate = AddMonth(CurrentDate, 60);
	EndIf;

	LimitTypeListRow = Form.LimitTypeList.FindByID(Form.Items.LimitTypeList.CurrentRow);

	arrLimitsForEmployeesTable = Form.LimitsForEmployeesTable.FindRows(New Structure("TypeOfLimit", Form.TypeOfLimitCurrent));
	CountRow = arrLimitsForEmployeesTable.Count();
	For Ind = 1 To arrLimitsForEmployeesTable.Count() Do
		Form.LimitsForEmployeesTable.Delete(arrLimitsForEmployeesTable[CountRow-Ind]);
	EndDo;

	While CurrentDate < EndContractDate Do

		LimitDate = CurrentDate;
		CurrentDate = AddMonth(CurrentDate, 12);
		LimitDateEnd = Min(CurrentDate - 24*60*60, EndContractDate);

		LimitsForEmployeesTableNewRow = Form.LimitsForEmployeesTable.Add();
		LimitsForEmployeesTableNewRow.TypeOfLimit = Form.TypeOfLimitCurrent;
		LimitsForEmployeesTableNewRow.Limit = LimitTypeListRow.Limit;
		LimitsForEmployeesTableNewRow.LimitDate = LimitDate;
		LimitsForEmployeesTableNewRow.LimitDateEnd = LimitDateEnd;
		LimitsForEmployeesTableNewRow.StageDescription = GetStageDescription(LimitsForEmployeesTableNewRow);		
	EndDo;

	Form.Modified = True;

EndProcedure

Procedure ChangeOfLimitsCheck(Form) Export 

	Object = Form.Object;

	If Object.ChangeOfLimits Then
		FillLimitsForEmployeesTable(Form);
		FillLimitTypeList(Form);

		If Form.LimitTypeList.Count() Then
			Form.Items.LimitTypeList.CurrentRow = Form.LimitTypeList[0].GetID();
		EndIf;
	Else
		Object.LimitsForEmployees.Clear();
	EndIf;

	ManagemenetItemOfCommandChangeOfLimitsCheck(Form);

EndProcedure

Procedure ManagemenetItemOfCommandChangeOfLimitsCheck(Form) 

	Items = Form.Items;
	Object = Form.Object;

	Items.GroupEmployeeLimits.Visible = Object.ChangeOfLimits;

	If Object.ChangeOfLimits Then
		Items.CommandLimitsForEmployeesChangeOfLimitsCheck.Title = NStr("ru = 'Отменить изменение лимитов...'; en = 'Cancel change the limits...'");
	Else
		Items.CommandLimitsForEmployeesChangeOfLimitsCheck.Title = NStr("ru = 'Изменить лимиты...'; en = 'Change the limits...'");
	EndIf;

EndProcedure

Function GetStageDescription(Val TableRow) Export 

	Return Format(TableRow.LimitDate, "DF=dd.MM.yyyy") + " - " + Format(TableRow.LimitDateEnd, "DF=dd.MM.yyyy");

EndFunction

Function GetStageDescriptionModify(Val TableRow) Export 

	Return TableRow.StageDescription <> GetStageDescription(TableRow);

EndFunction

#EndRegion //Contract

////////////////////////////////////////////////////////////////////////////////
// OBJECT EVENTS

Procedure BeforeWrite(Object, Cancel, WriteMode, PostingMode) Export 

	If TypeOf(Object) = Type("DocumentObject.EmploymentContract") Then
		ContractRef = Object.Ref;
	Else
		Return;
	EndIf;

	For Each LimitsForEmployeesRow In Object.LimitsForEmployees Do
		If Not ValueIsFilled(LimitsForEmployeesRow.Stage)
			And ValueIsFilled(LimitsForEmployeesRow.StageDescription) Then

			If ValueIsFilled(ContractRef) Then
				StageRef = Catalogs.StageOfLimitsForEmployees.FindByDescriptionKey(
					LimitsForEmployeesRow.StageDescription,
					ContractRef,
					LimitsForEmployeesRow.TypeOfLimit);
			Else
				StageRef = Undefined;
			EndIf;

			If StageRef = Undefined Then
				LimitsForEmployeesRow.Stage = Catalogs.StageOfLimitsForEmployees.GetRef(New UUID);
			Else 
				LimitsForEmployeesRow.Stage = StageRef;
			EndIf;
		EndIf;	
	EndDo;

EndProcedure

Procedure OnWrite(Object, Cancel) Export 

	If TypeOf(Object) = Type("DocumentObject.EmploymentContract") Then
		ContractRef = Object.Ref;
	Else
		Return;
	EndIf;

	For Each LimitsForEmployeesRow In Object.LimitsForEmployees Do
		If ValueIsFilled(LimitsForEmployeesRow.Stage) Then

			Catalogs.StageOfLimitsForEmployees.UpdateStage(
				LimitsForEmployeesRow.StageDescription,
				ContractRef,
				LimitsForEmployeesRow.TypeOfLimit,
				LimitsForEmployeesRow.LimitDate,
				LimitsForEmployeesRow.LimitDateEnd,
				LimitsForEmployeesRow.Stage);
		EndIf;
	EndDo;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// POSTING

Procedure DataInitializationDocument(DocumentRef, AdditionalProperties) Export

	DocumentName = AdditionalProperties.ForPosting.DocumentMetadata.Name;

	If DocumentName = "EmploymentContract" Then

		Query = New Query;

		Query.Text =
		"SELECT
		|	EmploymentContractLimitsForEmployees.TypeOfLimit AS TypeOfLimit,
		|	EmploymentContractLimitsForEmployees.Limit AS Limit,
		|	EmploymentContractLimitsForEmployees.Stage AS Stage,
		|	EmploymentContractLimitsForEmployees.StageDescription AS StageDescription,
		|	EmploymentContractLimitsForEmployees.LimitDate AS LimitDate,
		|	EmploymentContractLimitsForEmployees.LimitDateEnd AS LimitDateEnd,
		|	EmploymentContractLimitsForEmployees.NotApplicable AS NotApplicable,
		|	EmploymentContract.Ref AS Recorder,
		|	EmploymentContract.Period AS Period,
		|	EmploymentContract.Entity AS Entity,
		|	EmploymentContract.Employee AS Employee,
		|	TRUE AS Active
		|FROM
		|	Document.EmploymentContract.LimitsForEmployees AS EmploymentContractLimitsForEmployees
		|
		|		LEFT JOIN Document.EmploymentContract AS EmploymentContract
		|		ON EmploymentContractLimitsForEmployees.Ref = EmploymentContract.Ref
		|
		|		LEFT JOIN Catalog.TypesOfLimitsForEmployees AS TypesOfLimitsForEmployees
		|		ON EmploymentContractLimitsForEmployees.TypeOfLimit = TypesOfLimitsForEmployees.Ref
		|WHERE
		|	EmploymentContract.Ref = &DocumentRef";

		Query.SetParameter("DocumentRef", DocumentRef);
		Query.SetParameter("DateObject", Common.ObjectAttributeValue(DocumentRef, "Period"));

		QueryResult = Query.Execute().Unload();
		AdditionalProperties.TableForRegisterRecords.Insert("TableEmployeeLimitPlaning", QueryResult); 
	EndIf;

	If DocumentName = "ExpenseByLimits" Then

		Query = New Query;
		Query.TempTablesManager = AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;

		Query.Text =
		"SELECT
		|	DocumentTable.Date AS Period,
		|	DocumentTable.Entity AS Entity,
		|	DocumentTable.Employee AS Employee,
		|	LimitsForEmployeesTable.TypeOfLimit AS TypeOfLimit,
		|	LimitsForEmployeesTable.Stage AS Stage,
		|	SUM(LimitsForEmployeesTable.Limit) AS Limit
		|FROM
		|	Document.ExpenseByLimits.LimitsForEmployees AS LimitsForEmployeesTable
		|		LEFT JOIN Document.ExpenseByLimits AS DocumentTable
		|		ON LimitsForEmployeesTable.Ref = DocumentTable.Ref
		|WHERE
		|	DocumentTable.Ref = &DocumentRef
		|
		|GROUP BY
		|	DocumentTable.Date,
		|	LimitsForEmployeesTable.Stage,
		|	DocumentTable.Entity,
		|	DocumentTable.Employee,
		|	LimitsForEmployeesTable.TypeOfLimit";

		Query.SetParameter("DocumentRef", DocumentRef);

		QueryResult = Query.Execute();

		AdditionalProperties.TableForRegisterRecords.Insert("TableTurnoverByEmployeeLimits", QueryResult.Unload());
	EndIf;
	
	If DocumentName = "Tickets" Then

		Query = New Query;
		Query.TempTablesManager = AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;

		Query.Text =
		"SELECT
		|	Tickets.Ref AS Ref,
		|	Tickets.Date AS Period,
		|	Tickets.Entity AS Entity,
		|	Tickets.Employee AS Employee,
		|	Tickets.TypeOfLimits AS TypeOfLimit,
		|	Tickets.StageOfLimit AS Stage,
		|	Tickets.Count AS Limit
		|FROM
		|	Document.Tickets AS Tickets
		|WHERE
		|	Tickets.Ref = &DocumentRef";

		Query.SetParameter("DocumentRef", DocumentRef);

		QueryResult = Query.Execute();

		AdditionalProperties.TableForRegisterRecords.Insert("TableTurnoverByEmployeeLimits", QueryResult.Unload());
	EndIf;

EndProcedure

Procedure ReflectRecordsByEmployeeLimits(AdditionalProperties, RegisterRecords, Cancel) Export 

	arrRegisterName = New Array;
	arrRegisterName.Add("EmployeeLimitPlaning");
	arrRegisterName.Add("TurnoverByEmployeeLimits");

	For Each RegisterName In arrRegisterName Do

		TableName = StrTemplate("Table%1", RegisterName);

		If AdditionalProperties.TableForRegisterRecords.Property(TableName) Then			
			DocumentPosting.ReflectRegisterRecords(
				RegisterName,
				AdditionalProperties.TableForRegisterRecords,
				RegisterRecords,
				Cancel);
		EndIf;
	EndDo;

EndProcedure
