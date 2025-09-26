////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)

	If FillingData = Undefined Then // Create a new item.
		_DemoStandardSubsystems.OnEnterNewItemFillCompany(ThisObject, "Entity");
	EndIf;

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)

	LimitsForEmployeesServer.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)

	LimitsForEmployeesServer.OnWrite(ThisObject, Cancel);

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

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	Prefix = "A";
	
EndProcedure

#EndRegion // EventHandlers
