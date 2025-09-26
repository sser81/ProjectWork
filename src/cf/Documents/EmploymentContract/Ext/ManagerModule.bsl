////////////////////////////////////////////////////////////////////////////////
// PUBLIC

#Region Public

Procedure DataInitializationDocument(DocumentRef, AdditionalProperties) Export

	Query = New Query;
	Query.TempTablesManager = AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;

	Query.SetParameter("Ref", DocumentRef);

	Query.Text = DataInitializationDocumentQueryText();
	Query.Execute(); 

	GenerateTableEmployees(AdditionalProperties);    

	//LimitsForEmployees
	LimitsForEmployeesServer.DataInitializationDocument(DocumentRef, AdditionalProperties);

EndProcedure // DataInitializationDocument()

#EndRegion // Public

////////////////////////////////////////////////////////////////////////////////
// PRIVATE    

#Region Private 

#Region PostingProcedures

Function DataInitializationDocumentQueryText()

	QueryText =
	"SELECT
	|	1 AS LineNumber,
	|	EmploymentContract.Entity AS Entity,
	|	EmploymentContract.Employee AS Employee,
	|	EmploymentContract.Department AS Department,
	|	EmploymentContract.Period AS Period,
	|	EmploymentContract.EmployeeCode AS EmployeeCode,
	|	EmploymentContract.Ref AS Ref
	|INTO TableEmployees
	|FROM
	|	Document.EmploymentContract AS EmploymentContract
	|WHERE
	|	EmploymentContract.Ref = &Ref";

	Return QueryText; 

EndFunction

Procedure GenerateTableEmployees(AdditionalProperties)

	Query = New Query;
	Query.TempTablesManager = AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;

	Query.Text =
	"SELECT
	|	TableEmployees.Ref 			AS EmploymentContract,
	|	TableEmployees.Entity 		AS Organization,
	|	TableEmployees.Employee 	AS Individual,
	|	TableEmployees.Department 	AS Department_Company,
	|	1							AS OccupiedRates,
	|	TableEmployees.EmployeeCode AS EmployeeCode,
	|	TableEmployees.Period 		AS Period
	|FROM
	|	TableEmployees AS TableEmployees";

	QueryResult = Query.Execute();

	AdditionalProperties.TableForRegisterRecords.Insert("Table_DemoCompaniesEmployees", QueryResult.Unload());

EndProcedure

#EndRegion // PostingProcedures

#EndRegion // Private