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
// EXCHANGE FUNCTIONS

#Region AccountingSystem

Function GetChangedObjects(Node) Export 

	SetPrivilegedMode(True);

	arrXDTO_Objects = New Array;
	arrRefs = New Array;
	arrRecordSets = New Array;

	Type_Object						= XDTOFactory.Type("http://www.sample-package.org", "Object");
	Type_ObjectRef					= XDTOFactory.Type("http://www.sample-package.org", "ObjectRef");
	Type_ObjectPredefined			= XDTOFactory.Type("http://www.sample-package.org", "ObjectPredefined");
	Type_ObjectPredefinedRef		= XDTOFactory.Type("http://www.sample-package.org", "ObjectPredefinedRef");
	Type_StageOfLimitsForEmployees	= XDTOFactory.Type("http://www.sample-package.org", "StageOfLimitsForEmployees");

	Query = New Query;
	Query.SetParameter("Node", Node);

	//////////////////////////////////////////////////////////////////////////////////////////
	// Catalog.StageOfLimitsForEmployees
	Query.Text =
	"SELECT
	|	StageOfLimitsForEmployeesChanges.Node AS Node,
	|	StageOfLimitsForEmployees.Ref AS Ref,
	|	REFPRESENTATION(StageOfLimitsForEmployees.Ref) AS Presentation,
	|	EmploymentContractDocument.Ref AS EmployeeRef,
	|	REFPRESENTATION(StageOfLimitsForEmployees.EmploymentContract.Employee) AS EmployeePresentation,
	|	TypesOfLimitsForEmployees.CashFlowItem AS CashFlowItemRef,
	|	REFPRESENTATION(TypesOfLimitsForEmployees.CashFlowItem) AS CashFlowItemPresentation,
	|	TypesOfLimitsForEmployees.CashFlowItem.PredefinedDataName AS CashFlowItemPredefinedDataName,
	|	StageOfLimitsForEmployees.DescriptionKey AS DescriptionKey,
	|	StageOfLimitsForEmployees.StartDate AS StartDate,
	|	StageOfLimitsForEmployees.EndDate AS EndDate
	|FROM
	|	Catalog.StageOfLimitsForEmployees.Changes AS StageOfLimitsForEmployeesChanges
	|
	|		LEFT JOIN Catalog.StageOfLimitsForEmployees AS StageOfLimitsForEmployees
	|		ON StageOfLimitsForEmployeesChanges.Ref = StageOfLimitsForEmployees.Ref
	|
	|		LEFT JOIN Document.EmploymentContract AS EmploymentContractDocument
	|		ON (StageOfLimitsForEmployees.EmploymentContract = EmploymentContractDocument.Ref)
	|
	|		LEFT JOIN Catalog.TypesOfLimitsForEmployees AS TypesOfLimitsForEmployees
	|		ON (StageOfLimitsForEmployees.TypeOfLimit = TypesOfLimitsForEmployees.Ref)
	|WHERE
	|	StageOfLimitsForEmployeesChanges.Node = &Node
	|	AND NOT EmploymentContractDocument.Ref IS NULL
	|	AND NOT TypesOfLimitsForEmployees.CashFlowItem IS NULL
	|	AND TypesOfLimitsForEmployees.CashFlowItem <> &CashFlowItem_EmptyRef";

	Query.SetParameter("CashFlowItem_EmptyRef", Catalogs.CashFlowItems.EmptyRef());

	Selection = Query.Execute().Select();
	While Selection.Next() Do

		XDTO_Object = XDTOFactory.Create(Type_StageOfLimitsForEmployees);

		FillPropertyValues(XDTO_Object, Selection, "Presentation, DescriptionKey, StartDate, EndDate");

		XDTO_Object.ID		 = Selection.Ref.UUID();
		XDTO_Object.TypeName = Selection.Ref.Metadata().FullName();

		XDTO_Employee = XDTOFactory.Create(Type_ObjectRef);
		XDTO_Employee.ID					= Selection.EmployeeRef.UUID();
		XDTO_Employee.Presentation			= Selection.EmployeePresentation;

		XDTO_Object.Employee = XDTO_Employee;

		XDTO_CashFlowItem = XDTOFactory.Create(Type_ObjectPredefinedRef);
		XDTO_CashFlowItem.ID					= Selection.CashFlowItemRef.UUID();
		XDTO_CashFlowItem.Presentation			= Selection.CashFlowItemPresentation;
		XDTO_CashFlowItem.PredefinedDataName	= Selection.CashFlowItemPredefinedDataName;

		XDTO_Object.CashFlowItem = XDTO_CashFlowItem;

		arrXDTO_Objects.Add(XDTO_Object);
		arrRefs.Add(Selection.Ref);
	EndDo;

	//////////////////////////////////////////////////////////////////////////////////////////
	// Catalog.CashFlowItems
	Query.Text =
	"SELECT
	|	CashFlowItemsChanges.Node AS Node,
	|	CashFlowItemsChanges.Ref AS Ref,
	|	REFPRESENTATION(CashFlowItemsChanges.Ref) AS Presentation,
	|	CashFlowItemsChanges.Ref.PredefinedDataName AS PredefinedDataName
	|FROM
	|	Catalog.CashFlowItems.Changes AS CashFlowItemsChanges
	|WHERE
	|	CashFlowItemsChanges.Node = &Node";

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		XDTO_Object = XDTOFactory.Create(Type_ObjectPredefined);

		XDTO_Object.ID					= Selection.Ref.UUID();
		XDTO_Object.Presentation		= Selection.Presentation;
		XDTO_Object.PredefinedDataName	= Selection.PredefinedDataName;
		XDTO_Object.TypeName			= Selection.Ref.Metadata().FullName();

		arrXDTO_Objects.Add(XDTO_Object);
		arrRefs.Add(Selection.Ref);
	EndDo;

	//////////////////////////////////////////////////////////////////////////////////////////
	// Catalog._DemoCompanies
	Query.Text =
	"SELECT
	|	_DemoCompaniesChanges.Node AS Node,
	|	_DemoCompaniesChanges.Ref AS Ref,
	|	REFPRESENTATION(_DemoCompaniesChanges.Ref) AS Presentation
	|FROM
	|	Catalog._DemoCompanies.Changes AS _DemoCompaniesChanges
	|WHERE
	|	_DemoCompaniesChanges.Node = &Node";

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		XDTO_Object = XDTOFactory.Create(Type_Object);

		XDTO_Object.ID					= Selection.Ref.UUID();
		XDTO_Object.Presentation		= Selection.Presentation;
		XDTO_Object.TypeName			= Selection.Ref.Metadata().FullName();

		arrXDTO_Objects.Add(XDTO_Object);
		arrRefs.Add(Selection.Ref);
	EndDo;

	//////////////////////////////////////////////////////////////////////////////////////////
	// InformationRegister._DemoCompaniesEmployees
	Query.Text =
	"SELECT
	|	_DemoCompaniesEmployeesChanges.Node AS Node,
	|	EmploymentContract.Ref AS Ref,
	|	REFPRESENTATION(EmploymentContract.Employee) AS Presentation
	|FROM
	|	InformationRegister._DemoCompaniesEmployees.Changes AS _DemoCompaniesEmployeesChanges
	|		INNER JOIN Document.EmploymentContract AS EmploymentContract
	|		ON _DemoCompaniesEmployeesChanges.Recorder = EmploymentContract.Ref
	|WHERE
	|	_DemoCompaniesEmployeesChanges.Node = &Node";

	Selection = Query.Execute().Select();
	While Selection.Next() Do

		XDTO_Object = XDTOFactory.Create(Type_Object);

		XDTO_Object.ID					= Selection.Ref.UUID();
		XDTO_Object.Presentation		= Selection.Presentation;
		XDTO_Object.TypeName			= Selection.Ref.Metadata().FullName();

		arrXDTO_Objects.Add(XDTO_Object);

		strDimensions = New Structure;
		strDimensions.Insert("Recorder", Selection.Ref);
		
		strRecordSet = New Structure;
		strRecordSet.Insert("Type", "InformationRegister");
		strRecordSet.Insert("Name", "_DemoCompaniesEmployees");
		strRecordSet.Insert("Dimensions", strDimensions);

		arrRecordSets.Add(strRecordSet);
	EndDo;

	Return New Structure("Refs, RecordSets, XDTO_Objects", arrRefs, arrRecordSets, arrXDTO_Objects);

EndFunction

Function GetBalanceOfLimitsForEmployee(UUID_Employee, UUID_CashFlowItem, OnDate = Undefined) Export

	SetPrivilegedMode(True);

	Employee		= Catalogs._DemoIndividuals.EmptyRef();
	Entity			= Catalogs._DemoCompanies.EmptyRef();
	CashFlowItem	= Catalogs.CashFlowItems.EmptyRef(); 

	If ValueIsFilled(UUID_Employee) Then
		EmploymentContract = Documents.EmploymentContract.GetRef(New UUID(UUID_Employee)); 

		If ValueIsFilled(EmploymentContract) Then
			Employee = EmploymentContract.Employee;
			Entity = EmploymentContract.Entity;
		EndIf;
	EndIf;

	If ValueIsFilled(UUID_CashFlowItem) Then
		CashFlowItem = Catalogs.CashFlowItems.GetRef(New UUID(UUID_CashFlowItem)); 
	EndIf; 

	Query = New Query;
	Query.Text =
	"SELECT
	|	EmployeeLimitPlaningSliceLast.Entity AS Entity,
	|	EmployeeLimitPlaningSliceLast.Employee AS Employee,
	|	TypesOfLimitsForEmployees.CashFlowItem AS CashFlowItem,
	|	TypesOfLimitsForEmployees.OneTime AS OneTime,
	|	CASE
	|		WHEN TypesOfLimitsForEmployees.CountLimitControl
	|			THEN ""count""
	|		ELSE ""amount""
	|	END AS Resource,
	|	EmployeeLimitPlaningSliceLast.Stage AS Stage,
	|	EmployeeLimitPlaningSliceLast.Limit AS Limit,
	|	0 AS Expense
	|INTO TemporaryTableData
	|FROM
	|	InformationRegister.EmployeeLimitPlaning.SliceLast(
	|			&DateSlice,
	|			(Entity = &Entity
	|				OR &Entity = &Entity_EmptyRef)
	|				AND (Employee = &Employee
	|					OR &Employee = &Employee_EmptyRef)) AS EmployeeLimitPlaningSliceLast
	|		LEFT JOIN Catalog.TypesOfLimitsForEmployees AS TypesOfLimitsForEmployees
	|		ON EmployeeLimitPlaningSliceLast.TypeOfLimit = TypesOfLimitsForEmployees.Ref
	|WHERE
	|	CASE
	|			WHEN NOT TypesOfLimitsForEmployees.OneTime
	|				THEN EmployeeLimitPlaningSliceLast.Stage <> &StageOfLimitsForEmployees_EmptyRef
	|			ELSE TRUE
	|		END
	|	AND (TypesOfLimitsForEmployees.CashFlowItem = &CashFlowItem
	|			OR &CashFlowItem = &CashFlowItem_EmptyRef)
	|	AND NOT TypesOfLimitsForEmployees.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	TurnoverByEmployeeLimitsTurnovers.Entity,
	|	TurnoverByEmployeeLimitsTurnovers.Employee,
	|	TypesOfLimitsForEmployees.CashFlowItem,
	|	TypesOfLimitsForEmployees.OneTime,
	|	CASE
	|		WHEN TypesOfLimitsForEmployees.CountLimitControl
	|			THEN ""count""
	|		ELSE ""amount""
	|	END,
	|	TurnoverByEmployeeLimitsTurnovers.Stage,
	|	0,
	|	TurnoverByEmployeeLimitsTurnovers.LimitTurnover
	|FROM
	|	AccumulationRegister.TurnoverByEmployeeLimits.Turnovers(
	|			,
	|			&DateSlice,
	|			,
	|			(Entity = &Entity
	|				OR &Entity = &Entity_EmptyRef)
	|				AND (Employee = &Employee
	|					OR &Employee = &Employee_EmptyRef)) AS TurnoverByEmployeeLimitsTurnovers
	|		LEFT JOIN Catalog.TypesOfLimitsForEmployees AS TypesOfLimitsForEmployees
	|		ON TurnoverByEmployeeLimitsTurnovers.TypeOfLimit = TypesOfLimitsForEmployees.Ref
	|WHERE
	|	CASE
	|			WHEN NOT TypesOfLimitsForEmployees.OneTime
	|				THEN TurnoverByEmployeeLimitsTurnovers.Stage <> &StageOfLimitsForEmployees_EmptyRef
	|			ELSE TRUE
	|		END
	|	AND (TypesOfLimitsForEmployees.CashFlowItem = &CashFlowItem
	|			OR &CashFlowItem = &CashFlowItem_EmptyRef)
	|	AND NOT TypesOfLimitsForEmployees.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableData.Entity AS Entity,
	|	TemporaryTableData.Employee AS Employee,
	|	CAST(EmployeesSliceFirst.EmploymentContract AS Document.EmploymentContract).Period AS ContractStartDate,
	|	TemporaryTableData.CashFlowItem AS CashFlowItem,
	|	TemporaryTableData.OneTime AS OneTime,
	|	TemporaryTableData.Resource AS Resource,
	|	TemporaryTableData.Stage AS Stage,
	|	SUM(TemporaryTableData.Limit) AS Limit,
	|	SUM(TemporaryTableData.Expense) AS Expense
	|FROM
	|	TemporaryTableData AS TemporaryTableData
	|		LEFT JOIN InformationRegister._DemoCompaniesEmployees.SliceFirst(, ) AS EmployeesSliceFirst
	|		ON TemporaryTableData.Entity = EmployeesSliceFirst.Organization
	|			AND TemporaryTableData.Employee = EmployeesSliceFirst.Individual
	|		LEFT JOIN Catalog.StageOfLimitsForEmployees AS StageOfLimitsForEmployees
	|		ON TemporaryTableData.Stage = StageOfLimitsForEmployees.Ref
	|
	|GROUP BY
	|	TemporaryTableData.Entity,
	|	TemporaryTableData.Employee,
	|	TemporaryTableData.CashFlowItem,
	|	TemporaryTableData.OneTime,
	|	TemporaryTableData.Resource,
	|	TemporaryTableData.Stage,
	|	CAST(EmployeesSliceFirst.EmploymentContract AS Document.EmploymentContract).Period,
	|	StageOfLimitsForEmployees.StartDate,
	|	StageOfLimitsForEmployees.EndDate
	|
	|ORDER BY
	|	StageOfLimitsForEmployees.StartDate,
	|	StageOfLimitsForEmployees.EndDate
	|TOTALS
	|	SUM(Limit),
	|	SUM(Expense)
	|BY
	|	Entity,
	|	Employee,
	|	ContractStartDate,
	|	CashFlowItem,
	|	OneTime,
	|	Resource";

	If ValueIsFilled(OnDate) Then
		Query.SetParameter("DateSlice", OnDate);
	Else
		Query.SetParameter("DateSlice", CurrentDate());
	EndIf;

	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Entity", Entity);
	Query.SetParameter("CashFlowItem", CashFlowItem);

	Query.SetParameter("Employee_EmptyRef", Catalogs._DemoIndividuals.EmptyRef());
	Query.SetParameter("Entity_EmptyRef", Catalogs._DemoCompanies.EmptyRef());
	Query.SetParameter("CashFlowItem_EmptyRef", Catalogs.CashFlowItems.EmptyRef());
	Query.SetParameter("StageOfLimitsForEmployees_EmptyRef", Catalogs.StageOfLimitsForEmployees.EmptyRef());

	Object = XDTOFactory.Type("http://www.sample-package.org", "Object");

	XDTO_List = XDTOFactory.Create(XDTOFactory.Type("http://www.sample-package.org", "LimitsForEmployeesList")); 

	SelectionEntity = Query.Execute().Select(QueryResultIteration.ByGroups, "Entity");
	While SelectionEntity.Next() Do

		SelectionEmployee = SelectionEntity.Select(QueryResultIteration.ByGroups, "Employee");
		While SelectionEmployee.Next() Do

			SelectionContractStartDate = SelectionEmployee.Select(QueryResultIteration.ByGroups, "ContractStartDate");
			While SelectionContractStartDate.Next() Do

				SelectionCashFlowItem = SelectionContractStartDate.Select(QueryResultIteration.ByGroups, "CashFlowItem");
				While SelectionCashFlowItem.Next() Do

					SelectionOneTime = SelectionCashFlowItem.Select(QueryResultIteration.ByGroups, "OneTime");
					While SelectionOneTime.Next() Do

						SelectionResource = SelectionOneTime.Select(QueryResultIteration.ByGroups, "Resource");
						While SelectionResource.Next() Do

							XDTO_Row = XDTOFactory.Create(XDTOFactory.Type("http://www.sample-package.org", "LimitsForEmployeesRow"));

							XDTO_Employee = XDTOFactory.Create(Object);
							XDTO_Employee.ID = SelectionEmployee.Employee.UUID();
							XDTO_Employee.Presentation = String(SelectionEmployee.Employee);

							XDTO_CashFlowItem = XDTOFactory.Create(Object);
							XDTO_CashFlowItem.ID = SelectionCashFlowItem.CashFlowItem.UUID();
							XDTO_CashFlowItem.Presentation = String(SelectionCashFlowItem.CashFlowItem);

							XDTO_Row.Employee 			= XDTO_Employee;
							XDTO_Row.CashFlowItem 		= XDTO_CashFlowItem;
							XDTO_Row.ContractStartDate 	= SelectionContractStartDate.ContractStartDate;

							XDTO_BalanceList = XDTOFactory.Create(XDTOFactory.Type("http://www.sample-package.org", "BalanceOfLimitsForEmployeesList")); 

							If SelectionOneTime.OneTime Then
								FillPropertyValues(XDTO_Row, SelectionResource, "Limit, Expense");
							Else
								Selection = SelectionResource.Select();
								While Selection.Next() Do

									XDTO_BalanceRow = XDTOFactory.Create(XDTOFactory.Type("http://www.sample-package.org", "BalanceOfLimitsForEmployeesRow"));
									FillPropertyValues(XDTO_BalanceRow, Selection, "Limit, Expense");

									XDTO_Stage = XDTOFactory.Create(Object);
									XDTO_Stage.ID = Selection.Stage.UUID();
									XDTO_Stage.Presentation = String(Selection.Stage);

									XDTO_BalanceRow.Stage = XDTO_Stage;

									XDTO_BalanceList.Row.Add(XDTO_BalanceRow);
								EndDo;

								XDTO_Row.Limit = 0;
								XDTO_Row.Expense = 0;
							EndIf;

							XDTO_Row.OneTime	= SelectionOneTime.OneTime;
							XDTO_Row.Resource	= SelectionResource.Resource;
							XDTO_Row.Balances	= XDTO_BalanceList;

							XDTO_List.Row.Add(XDTO_Row);
						EndDo;
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;

	Return XDTO_List;

EndFunction

Procedure LoadExchangeData(ObjectsXDTO) Export

	For Each ObjectXDTO In ObjectsXDTO Do

		IsChange = False;

		DocumentRef = GetRefForObjectXDTO(ObjectXDTO, "Document.ExpenseByLimits");

		If ValueIsFilled(DocumentRef) Then
			NewDocument = DocumentRef.GetObject();
		Else
			NewDocument = Documents.ExpenseByLimits.CreateDocument();
			NewDocument.SetNewObjectRef(Documents.ExpenseByLimits.GetRef(New UUID(ObjectXDTO.ID)));

			IsChange = True;
		EndIf;

		If ValueIsFilled(ObjectXDTO.Дата) Then
			NewDocument.Date = ObjectXDTO.Дата;
		Else
			Continue;
		EndIf;

		EmploymentContract = GetRefForObjectXDTO(ObjectXDTO.Сотрудник, "Document.EmploymentContract");
		If Not ValueIsFilled(EmploymentContract) Then
			Continue;
		EndIf;

		Employee = Common.ObjectAttributeValue(EmploymentContract, "Employee");
		If NewDocument.Employee <> Employee
			And (ValueIsFilled(NewDocument.Employee) Or ValueIsFilled(Employee)) Then

			NewDocument.Employee = Employee;
			IsChange = True;
		EndIf;

		Entity = GetRefForObjectXDTO(ObjectXDTO.Организация, "Catalog._DemoCompanies", True);
		If NewDocument.Entity <> Entity
			And (ValueIsFilled(NewDocument.Entity) Or ValueIsFilled(Entity)) Then

			NewDocument.Entity = Entity;
			IsChange = True;
		EndIf;

		TableLimitsForEmployees = NewDocument.LimitsForEmployees.Unload();
		TableLimitsForEmployees.Columns.Add("Different", New TypeDescription("Number"));
		TableLimitsForEmployees.FillValues(-1, "Different");

		NewRow = TableLimitsForEmployees.Add();
		NewRow.Different = 1;

		CashFlowItem = GetRefForObjectXDTO(ObjectXDTO.СтатьяДвиженияДенежныхСредств, "Catalog.CashFlowItems", True);
		If ValueIsFilled(CashFlowItem) Then

			Query = New Query;
			Query.Text =
			"SELECT TOP 1
			|	TypesOfLimitsForEmployees.Ref AS Ref
			|FROM
			|	Catalog.TypesOfLimitsForEmployees AS TypesOfLimitsForEmployees
			|WHERE
			|	TypesOfLimitsForEmployees.CashFlowItem = &CashFlowItem
			|	AND NOT TypesOfLimitsForEmployees.DeletionMark";

			Query.SetParameter("CashFlowItem", CashFlowItem);

			Selection = Query.Execute().Select();
			If Selection.Next() Then
				NewRow.TypeOfLimit = Selection.Ref;
			EndIf;
		EndIf;

		NewRow.Stage = GetRefForObjectXDTO(ObjectXDTO.Этап, "Catalog.StageOfLimitsForEmployees", True);
		NewRow.Limit = ObjectXDTO.Сумма;

		TableLimitsForEmployees.GroupBy("TypeOfLimit, Stage, Limit", "Different");

		IsChangeInTable = False;
		Index = 0;
		While Index < TableLimitsForEmployees.Count() Do

			RowTable = TableLimitsForEmployees[Index];

			If RowTable.Different < 0 Then
				TableLimitsForEmployees.Delete(RowTable);
				IsChangeInTable = True;

			ElsIf RowTable.Different > 0 Then
				Index = Index + 1;
				IsChangeInTable = True;
			Else
				Index = Index + 1;
			EndIf;
		EndDo;

		If IsChangeInTable Then
			NewDocument.LimitsForEmployees.Load(TableLimitsForEmployees);
			IsChange = True;
		EndIf;

		If IsChange Then
			NewDocument.Write(DocumentWriteMode.Posting, DocumentPostingMode.Regular);
		EndIf;
	EndDo;

EndProcedure

Function GetRefForObjectXDTO(ObjectXDTO, TypeName = "", GetRefForUUID = False)

	ThereIsPropertyType 				= False;
	ThereIsPropertyPredefinedDataName 	= False;

	PropertiesXDTO = ObjectXDTO.Properties();
	For Each PropertyXDTO In PropertiesXDTO Do

		If Upper(PropertyXDTO.Name) = Upper("TypeName") Then
			ThereIsPropertyType = True;
		EndIf;

		If Upper(PropertyXDTO.Name) = Upper("PredefinedDataName") Then
			ThereIsPropertyPredefinedDataName = True;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(TypeName) Then

		If ThereIsPropertyType Then

			TypeNameExt = ObjectXDTO.TypeName;

			If StrFind(Upper(TypeNameExt), Upper("ДО_ЭтапыЛимитовСотрудников")) > 0 Then
				TypeName = "Catalog.StageOfLimitsForEmployees";

			ElsIf StrFind(Upper(TypeNameExt), Upper("ДО_СтатьиДвиженияДенежныхСредств")) > 0 Then
				TypeName = "Catalog.CashFlowItems";

			ElsIf StrFind(Upper(TypeNameExt), Upper("ДО_Организации")) > 0 Then
				TypeName = "Catalog._DemoCompanies";

			ElsIf StrFind(Upper(TypeNameExt), Upper("ДО_Сотрудники")) > 0 Then
				TypeName = "Document.EmploymentContract";

			ElsIf StrFind(Upper(TypeNameExt), Upper("ДО_Документы")) > 0 Then
				TypeName = "Document.ExpenseByLimits";
			EndIf;
		EndIf;
	EndIf;

	If Not ValueIsFilled(TypeName) Then
		Return Undefined;
	EndIf;

	If ThereIsPropertyPredefinedDataName Then
		PredefinedDataName = ObjectXDTO.PredefinedDataName;
	Else
		PredefinedDataName = "";
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	Table.Ref AS Ref,
	|	2 AS Priority
	|FROM
	|	&Table AS Table
	|WHERE
	|	UUID(Table.Ref) = &UUID_Ref";

	If Upper(Left(TypeName, 8)) <> "DOCUMENT" Then
		Query.Text = Query.Text + "
		|
		|UNION
		|
		|SELECT
		|	Table.Ref,
		|	1
		|FROM
		|	&Table AS Table
		|WHERE
		|	Table.Predefined
		|	AND Table.PredefinedDataName = &PredefinedDataName";
	EndIf;

	Query.Text = Query.Text + "
	|
	|ORDER BY
	|	Priority";

	Query.Text = StrReplace(Query.Text, "&Table", TypeName);

	Query.SetParameter("UUID_Ref", New UUID(ObjectXDTO.ID));
	Query.SetParameter("PredefinedDataName", PredefinedDataName);

	Selection = Query.Execute().Select();
	If Selection.Next() Then

		Return Selection.Ref;

	ElsIf GetRefForUUID Then

		ObjectManager = Common.ObjectManagerByFullName(TypeName);
		Return ObjectManager.GetRef(New UUID(ObjectXDTO.ID));
	Else
		Return Undefined
	EndIf;				

EndFunction

#EndRegion // AccountingSystem

#Region DocumentFlow

Функция ДО_ПолучитьИзмененияОбъектов(Узел) Экспорт

	УстановитьПривилегированныйРежим(Истина);

	мОбъектыXDTO = Новый Массив;
	мСсылки = Новый Массив;

	Тип_ObjectRef			= ФабрикаXDTO.Тип("http://www.sample-package.org", "ObjectRef");
	Тип_ObjectPredefinedRef	= ФабрикаXDTO.Тип("http://www.sample-package.org", "ObjectPredefinedRef");
	Тип_ДО_Документ 		= ФабрикаXDTO.Тип("http://www.sample-package.org", "ДО_Документ");

	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("Узел", Узел);

	Запрос.Текст =
	"ВЫБРАТЬ
	|	ДО_ДокументыИзменения.Узел КАК Узел,
	|	ДО_Документы.Ссылка КАК Ссылка,
	|	ПРЕДСТАВЛЕНИЕССЫЛКИ(ДО_Документы.Ссылка) КАК Представление,
	|	ДО_Документы.Организация КАК Организация,
	|	ДО_Документы.Сотрудник КАК Сотрудник,
	|	ДО_Документы.СтатьяДвиженияДенежныхСредств КАК СтатьяДвиженияДенежныхСредств,
	|	ДО_Документы.СтатьяДвиженияДенежныхСредств.PredefinedDataName AS СтатьяДвиженияДенежныхСредствИмяПредопределенного,
	|	ДО_Документы.Этап КАК Этап,
	|	ДО_Документы.Сумма КАК Сумма,
	|	ДО_Документы.Дата КАК Дата
	|ИЗ
	|	Справочник.ДО_Документы.Изменения КАК ДО_ДокументыИзменения
	|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.ДО_Документы КАК ДО_Документы
	|		ПО ДО_ДокументыИзменения.Ссылка = ДО_Документы.Ссылка
	|ГДЕ
	|	ДО_ДокументыИзменения.Узел = &Узел
	|	И ДО_Документы.Согласован";

	Выборка = Запрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл

		ОбъектXDTO = ФабрикаXDTO.Создать(Тип_ДО_Документ);

		ОбъектXDTO.ID			= Выборка.Ссылка.УникальныйИдентификатор();
		ОбъектXDTO.Presentation	= Выборка.Представление;
		ОбъектXDTO.TypeName		= Выборка.Ссылка.Метаданные().ПолноеИмя();

		//Организация
		XDTO_Организация = ФабрикаXDTO.Создать(Тип_ObjectRef);
		XDTO_Организация.ID				= Выборка.Организация.УникальныйИдентификатор();
		XDTO_Организация.Presentation	= Строка(Выборка.Организация);

		ОбъектXDTO.Организация = XDTO_Организация;

		//Сотрудник
		XDTO_Сотрудник = ФабрикаXDTO.Создать(Тип_ObjectRef);
		XDTO_Сотрудник.ID			= Выборка.Сотрудник.УникальныйИдентификатор();
		XDTO_Сотрудник.Presentation	= Строка(Выборка.Сотрудник);

		ОбъектXDTO.Сотрудник = XDTO_Сотрудник;

		//СтатьяДвиженияДенежныхСредств
		XDTO_СтатьяДвиженияДенежныхСредств = ФабрикаXDTO.Создать(Тип_ObjectPredefinedRef);
		XDTO_СтатьяДвиженияДенежныхСредств.ID					= Выборка.СтатьяДвиженияДенежныхСредств.УникальныйИдентификатор();
		XDTO_СтатьяДвиженияДенежныхСредств.Presentation			= Строка(Выборка.СтатьяДвиженияДенежныхСредств);
		XDTO_СтатьяДвиженияДенежныхСредств.PredefinedDataName	= Строка(Выборка.СтатьяДвиженияДенежныхСредствИмяПредопределенного);

		ОбъектXDTO.СтатьяДвиженияДенежныхСредств = XDTO_СтатьяДвиженияДенежныхСредств;

		//Этап
		XDTO_Этап = ФабрикаXDTO.Создать(Тип_ObjectRef);
		XDTO_Этап.ID			= Выборка.Этап.УникальныйИдентификатор();
		XDTO_Этап.Presentation	= Строка(Выборка.Этап);

		ОбъектXDTO.Этап = XDTO_Этап;

		ОбъектXDTO.Сумма = Выборка.Сумма;
		ОбъектXDTO.Дата  = Выборка.Дата;

		мОбъектыXDTO.Добавить(ОбъектXDTO);
		мСсылки.Добавить(Выборка.Ссылка);
	КонецЦикла;

	Возврат Новый Структура("Refs, XDTO_Objects", мСсылки, мОбъектыXDTO);

КонецФункции

Процедура ДО_ЗагрузитьДанныеОбмена(ОбъектыXDTO) Экспорт

	For Each ОбъектXDTO In ОбъектыXDTO Do

		TableName = "";
		IsChange = False;

		ObjectRef = ДО_ПолучитьСсылкуПоОбъектуXDTO(ОбъектXDTO, TableName);

		If Not ValueIsFilled(TableName) Then
 			Continue;
		EndIf;

		If ValueIsFilled(ObjectRef) Then
			NewObject = ObjectRef.GetObject();
		Else
			ObjectManager = Common.ObjectManagerByFullName(TableName);

			NewObject = ObjectManager.CreateItem();
			NewObject.SetNewObjectRef(ObjectManager.GetRef(New UUID(ОбъектXDTO.ID)));

			IsChange = True;
		EndIf;

		If NewObject.Description <> ОбъектXDTO.Presentation Then
			NewObject.Description = ОбъектXDTO.Presentation;
			IsChange = True;
		EndIf;

		If TableName = "Справочник.ДО_ЭтапыЛимитовСотрудников" Then

			СтатьяДвиженияДенежныхСредств = ДО_ПолучитьСсылкуПоОбъектуXDTO(ОбъектXDTO.CashFlowItem, "Справочник.ДО_СтатьиДвиженияДенежныхСредств", True);
			If NewObject.СтатьяДвиженияДенежныхСредств <> СтатьяДвиженияДенежныхСредств
				And (ValueIsFilled(NewObject.СтатьяДвиженияДенежныхСредств) Or ValueIsFilled(СтатьяДвиженияДенежныхСредств)) Then

				NewObject.СтатьяДвиженияДенежныхСредств = СтатьяДвиженияДенежныхСредств;
				IsChange = True;
			EndIf;

			Владелец = ДО_ПолучитьСсылкуПоОбъектуXDTO(ОбъектXDTO.Employee, "Справочник.ДО_Сотрудники", True);
			If NewObject.Владелец <> Владелец
				And (ValueIsFilled(NewObject.Владелец) Or ValueIsFilled(Владелец)) Then

				NewObject.Владелец = Владелец;
				IsChange = True;
			EndIf;

			If NewObject.ТекстовыйКлюч <> ОбъектXDTO.DescriptionKey
				And (ValueIsFilled(NewObject.ТекстовыйКлюч) Or ValueIsFilled(ОбъектXDTO.DescriptionKey)) Then

				NewObject.ТекстовыйКлюч = ОбъектXDTO.DescriptionKey;
				IsChange = True;
			EndIf;

			If NewObject.ДатаНачала <> ОбъектXDTO.StartDate
				And (ValueIsFilled(NewObject.ДатаНачала) Or ValueIsFilled(ОбъектXDTO.StartDate)) Then

				NewObject.ДатаНачала = ОбъектXDTO.StartDate;
				IsChange = True;
			EndIf;

			If NewObject.ДатаОкончания <> ОбъектXDTO.EndDate
				And (ValueIsFilled(NewObject.ДатаОкончания) Or ValueIsFilled(ОбъектXDTO.EndDate)) Then

				NewObject.ДатаОкончания = ОбъектXDTO.EndDate;
				IsChange = True;
			EndIf;
		EndIf;

		If IsChange Then
			NewObject.DataExchange.Load = True;
			NewObject.Write();
		EndIf;
	EndDo;

КонецПроцедуры

Функция ДО_ПолучитьСсылкуПоОбъектуXDTO(ОбъектXDTO, ИмяТипа = "", ПолучатьСсылкуПоИдентификатору = Ложь)

	ЕстьПолеТипа 					= Ложь;
	ЕстьПолеИмениПредопределенного	= Ложь;

	СвойстваXDTO = ОбъектXDTO.Свойства();
	Для Каждого СвойствоXDTO Из СвойстваXDTO Цикл

		Если ВРег(СвойствоXDTO.Name) = ВРег("TypeName") Тогда
			ЕстьПолеТипа = Истина;
		КонецЕсли;

		Если ВРег(СвойствоXDTO.Name) = ВРег("PredefinedDataName") Тогда
			ЕстьПолеИмениПредопределенного = Истина;
		КонецЕсли;
	КонецЦикла;
	
	Если НЕ ЗначениеЗаполнено(ИмяТипа) Тогда

		Если ЕстьПолеТипа Тогда

			ИмяТипаПолученныхДанных = ОбъектXDTO.TypeName;

			Если СтрНайти(ВРег(ИмяТипаПолученныхДанных), ВРег("StageOfLimitsForEmployees")) > 0 Тогда
				ИмяТипа = "Справочник.ДО_ЭтапыЛимитовСотрудников";

			ИначеЕсли СтрНайти(ВРег(ИмяТипаПолученныхДанных), ВРег("CashFlowItems")) > 0 Тогда
				ИмяТипа = "Справочник.ДО_СтатьиДвиженияДенежныхСредств";

			ИначеЕсли СтрНайти(ВРег(ИмяТипаПолученныхДанных), ВРег("_DemoCompanies")) > 0 Тогда
				ИмяТипа = "Справочник.ДО_Организации";

			ИначеЕсли СтрНайти(ВРег(ИмяТипаПолученныхДанных), ВРег("_DemoIndividuals")) > 0
				ИЛИ СтрНайти(ВРег(ИмяТипаПолученныхДанных), ВРег("EmploymentContract")) > 0 Тогда
				ИмяТипа = "Справочник.ДО_Сотрудники";
			КонецЕсли;
		КонецЕсли;
	КонецЕсли;

	Если НЕ ЗначениеЗаполнено(ИмяТипа) Тогда
		Возврат Неопределено;
	КонецЕсли;

	Если ЕстьПолеИмениПредопределенного Тогда
		ИмяПредопределенного = ОбъектXDTO.PredefinedDataName;
	Иначе
		ИмяПредопределенного = "";
	КонецЕсли;

	Запрос = Новый Запрос;
	Запрос.Текст =
	"SELECT
	|	Table.Ref AS Ref,
	|	1 AS Priority
	|FROM
	|	&Table AS Table
	|WHERE
	|	Table.Predefined
	|	AND Table.PredefinedDataName = &PredefinedDataName
	|
	|UNION
	|
	|SELECT
	|	Table.Ref,
	|	2
	|FROM
	|	&Table AS Table
	|WHERE
	|	NOT Table.Predefined
	|	AND UUID(Table.Ref) = &UUID_Ref
	|
	|ORDER BY
	|	Priority";

	Запрос.Текст = СтрЗаменить(Запрос.Текст, "&Table", ИмяТипа);

	Запрос.УстановитьПараметр("UUID_Ref", Новый УникальныйИдентификатор(ОбъектXDTO.ID));
	Запрос.УстановитьПараметр("PredefinedDataName", ИмяПредопределенного);

	Выборка = Запрос.Выполнить().Выбрать();
	Если Выборка.Следующий() Тогда

		Возврат Выборка.Ref;

	ИначеЕсли ПолучатьСсылкуПоИдентификатору Тогда

		МенеджерОбъекта = Common.ObjectManagerByFullName(ИмяТипа);
		Возврат МенеджерОбъекта.ПолучитьСсылку(Новый УникальныйИдентификатор(ОбъектXDTO.ID));
	Иначе
		Возврат Неопределено
	КонецЕсли;				

КонецФункции

#EndRegion // DocumentFlow

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
