////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	RunControl(Cancel);

EndProcedure // FillCheckProcessing() 

Procedure Filling(FillingData, StandardProcessing)

	If FillingData = Undefined Then // Create a new item.
		_DemoStandardSubsystems.OnEnterNewItemFillCompany(ThisObject, "Entity");
	EndIf;

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)

	LimitsForEmployeesServer.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	// Initialization of additional properties for document posting.
	DocumentPosting.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);
		
	// Initialization of document data.
	Documents.EmploymentContract.DataInitializationDocument(Ref, AdditionalProperties);
	
	// Prepare recordsets.
	DocumentPosting.PrepareRecordSetsForRecording(ThisObject);
	
	TableForRegisterRecords = AdditionalProperties.TableForRegisterRecords; 
	
	// Reflect in accounting sections.  
	DocumentPosting.ReflectRegisterRecords("_DemoCompaniesEmployees", TableForRegisterRecords, RegisterRecords, Cancel);
	DocumentPosting.ReflectRegisterRecords("EmployeeLimitPlaning", AdditionalProperties.TableForRegisterRecords, RegisterRecords, Cancel);

	// Write recordsets.
	DocumentPosting.WriteRecordSets(ThisObject);

	AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager.Close();

EndProcedure // Posting()

Procedure OnWrite(Cancel)

	LimitsForEmployeesServer.OnWrite(ThisObject, Cancel);

EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	Prefix = "A";
	
EndProcedure

#EndRegion // EventHandlers

// Performs control of contradictions.
Procedure RunControl(Cancel)

	If Cancel Then
		Return;	
	EndIf;

	EmployeesFromDoc = New ValueTable; 

	EmployeesFromDoc.Columns.Add("Employee",	New TypeDescription("CatalogRef._DemoIndividuals")); 
	EmployeesFromDoc.Columns.Add("Period",		New TypeDescription("Date")); 

	Row = EmployeesFromDoc.Add();
	Row.Employee	= Employee;
	Row.Period		= Period;

	Query = New Query;   

	Query.SetParameter("Ref",				Ref);
	Query.SetParameter("Entity",			Entity);
	Query.SetParameter("EmployeesFromDoc",	EmployeesFromDoc);

	Query.Text = RunControlQueryText();

	ResultsArray = Query.ExecuteBatch();
	
	// Employee is already hired on hiring date.
	If Not ResultsArray[2].IsEmpty() Then

		QueryResultSelection = ResultsArray[2].Select();

		While QueryResultSelection.Next() Do

			MessageText = NStr(
				"en = 'Employee %1 is already working in the company.';
				|ru = 'Cотрудник %1 уже работает в компании.'");

			MessageText = StrTemplate(MessageText, QueryResultSelection.EmployeePresentation);

			Common.MessageToUser(MessageText, ThisObject, "Employee",, Cancel);
		EndDo;
	EndIf;

EndProcedure   

Function RunControlQueryText()
	
	QueryText =
	"SELECT
	|	CAST(EmployeesFromDoc.Employee AS Catalog._DemoIndividuals) AS Employee,
	|	EmployeesFromDoc.Period AS Period
	|INTO EmployeesFromDoc
	|FROM
	|	&EmployeesFromDoc AS EmployeesFromDoc
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmployeesFromDoc.Employee AS Employee,
	|	MAX(Employees.Period) AS Period
	|INTO EmployeeIsWorked
	|FROM
	|	InformationRegister._DemoCompaniesEmployees AS Employees
	|		INNER JOIN EmployeesFromDoc AS EmployeesFromDoc
	|		ON Employees.Individual = EmployeesFromDoc.Employee
	|			AND (Employees.Organization = &Entity)
	|			AND Employees.Period <= EmployeesFromDoc.Period
	|			AND (Employees.Recorder <> &Ref)
	|
	|GROUP BY
	|	EmployeesFromDoc.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmployeeIsWorked.Employee AS Employee,
	|	PRESENTATION(EmployeeIsWorked.Employee) AS EmployeePresentation
	|FROM
	|	EmployeeIsWorked AS EmployeeIsWorked
	|		INNER JOIN InformationRegister._DemoCompaniesEmployees AS Employees
	|		ON EmployeeIsWorked.Employee = Employees.Individual
	|			AND EmployeeIsWorked.Period = Employees.Period
	|			AND (Employees.Organization = &Entity)";

	Return QueryText;

EndFunction	
