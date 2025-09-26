////////////////////////////////////////////////////////////////////////////////
// DOCUMENT POSTING (SERVER)
// 
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// PUBLIC

#Region Public

////////////////////////////////////////////////////////////////////////////////
// POSTING CONTROL

// Performs initialization of additional properties for document posting.
//
Procedure InitializeAdditionalPropertiesForPosting(DocumentRef, StructureAdditionalProperties) Export

	// Create properties with keys "TableForRegisterRecords", "ForPosting", "AccountingPolicy" in structure "AdditionalProperties"

	// "TableForRegisterRecords" - structure, that will contain value tables for generating register records.
	StructureAdditionalProperties.Insert("TableForRegisterRecords", New Structure);

	// "ForPosting" - structure, containing properties and document attributes, required for posting.
	StructureAdditionalProperties.Insert("ForPosting", New Structure);

	// Structure, containing key with name "TempTablesManager", whose value stores temporary tables manager.
	// Contains key (temporary table name) and value (flag that there are some records in temporary table) for each temporary table.
	StructureAdditionalProperties.ForPosting.Insert("StructureTemporaryTables", 	New Structure("TempTablesManager", New TempTablesManager));
	StructureAdditionalProperties.ForPosting.Insert("DocumentMetadata", 			DocumentRef.Metadata());

	// "AccountingPolicy" - structure, containing values all parameters of accounting policy at the moment of document time
	// with applied filter by Entity.
	StructureAdditionalProperties.Insert("AccountingPolicy", New Structure);

	// Query, getting document data.
	Query = New Query(
	"SELECT
	|	_Document_.Ref AS Ref,
	|	_Document_.Number AS Number,
	|	_Document_.Date AS Date,
	|   " + ?(StructureAdditionalProperties.ForPosting.DocumentMetadata.Attributes.Find("Entity") <> Undefined, "_Document_.Entity" , "VALUE(Catalog.Entities.EmptyRef)") + " AS Entity,
	|	_Document_.PointInTime AS PointInTime,
	|	_Document_.Presentation AS Presentation
	|FROM
	|	Document." + StructureAdditionalProperties.ForPosting.DocumentMetadata.Name + " AS _Document_
	|WHERE
	|	_Document_.Ref = &DocumentRef");

	Query.SetParameter("DocumentRef", DocumentRef);

	QueryResult = Query.Execute();

	// Generate keys, containig document data.
	For Each Column In QueryResult.Columns Do
		StructureAdditionalProperties.ForPosting.Insert(Column.Name);
	EndDo;

	QueryResultSelection = QueryResult.Select();
	QueryResultSelection.Next();

	// Fill values of the keys, containig document data.
	FillPropertyValues(StructureAdditionalProperties.ForPosting, QueryResultSelection);

	// Determine and assign value of the moment, on which document control should be performed.
	StructureAdditionalProperties.ForPosting.Insert("ControlTime", 						Date('00010101'));
	StructureAdditionalProperties.ForPosting.Insert("ControlPeriod", 					Date("39991231"));
	
EndProcedure // InitializeAdditionalPropertiesForPosting()

// Prepare document recordsets.
//
Procedure PrepareRecordSetsForRecording(StructureObject) Export

	For each RecordSet in StructureObject.RegisterRecords Do

		If TypeOf(RecordSet) = Type("KeyAndValue") Then

			RecordSet = RecordSet.Value;

		EndIf;

		If RecordSet.Count() > 0 Then

			RecordSet.Clear();

		EndIf;

	EndDo;

	RegisterNamesArray = GetNamesArrayOfUsedRegisters(StructureObject.Ref, StructureObject.AdditionalProperties.ForPosting.DocumentMetadata);

	For each RegisterName in RegisterNamesArray Do

		StructureObject.RegisterRecords[RegisterName].Write = True;

	EndDo;

EndProcedure

// Write document recordsets.
//
Procedure WriteRecordSets(StructureObject) Export

	For each RecordSet in StructureObject.RegisterRecords Do

		If TypeOf(RecordSet) = Type("KeyAndValue") Then

			RecordSet = RecordSet.Value;

		EndIf;

		If RecordSet.Write Then

			If NOT RecordSet.AdditionalProperties.Property("ForPosting") Then

				RecordSet.AdditionalProperties.Insert("ForPosting", New Structure);

			EndIf;

			If NOT RecordSet.AdditionalProperties.ForPosting.Property("StructureTemporaryTables") Then

				RecordSet.AdditionalProperties.ForPosting.Insert("StructureTemporaryTables", StructureObject.AdditionalProperties.ForPosting.StructureTemporaryTables);

			EndIf;

			RecordSet.Write();
			RecordSet.Write = False;

		Else

			If Metadata.AccumulationRegisters.Contains(RecordSet.Metadata()) Then

				Try
					AccumulationRegisters[RecordSet.Metadata().Name].CreateEmptyTemporaryTableChange(StructureObject.AdditionalProperties);
				Except
				EndTry;

			EndIf;

		EndIf;

	EndDo;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES GENERATING REGISTER RECORDS

Procedure ReflectRegisterRecords(RegisterName, TablesForRegisterRecords, RegisterRecords, Cancel) Export
	
	//-> FBI-3169 - DPR Dev Transfer Order
	
	If Cancel Then
		Return;
	EndIf;
	
	TableName = StrTemplate("Table%1", RegisterName);
	
	If Not TablesForRegisterRecords.Property(TableName) Then // FBI-3652
		Return;
	EndIf;
	
	TableForRecords = TablesForRegisterRecords[TableName];
	
	If TableForRecords.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecords[RegisterName].Write = True;
	RegisterRecords[RegisterName].Load(TableForRecords);
	
	//<- FBI-3169
	
EndProcedure

Procedure ReflectEmployees(AdditionalProperties, RegisterRecords, Cancel) Export

	TableEmployees = AdditionalProperties.TableForRegisterRecords.TableEmployees;

	If Cancel
	 OR TableEmployees.Count() = 0 Then
		Return;
	EndIf;

	RegisterRecordsEmployees 		= RegisterRecords._DemoCompaniesEmployees;
	RegisterRecordsEmployees.Write 	= True;
	RegisterRecordsEmployees.Load(TableEmployees);

EndProcedure

#EndRegion // Public

////////////////////////////////////////////////////////////////////////////////
// PRIVATE

#Region Private

// Generate array of register names, which have document records.
//
Function GetNamesArrayOfUsedRegisters(Recorder, DocumentMetadata)

	RegistersArray 	= New Array;
	QueryText 		= "";
	TablesCounter 	= 0;
	CycleCounter 	= 0;
	TotalRegisters	= DocumentMetadata.RegisterRecords.Count();

	For each Record in DocumentMetadata.RegisterRecords Do

		If TablesCounter > 0 Then

			QueryText = QueryText + "
			|UNION ALL
			|";

		EndIf;

		TablesCounter = TablesCounter + 1;
		CycleCounter = CycleCounter + 1;

		QueryText = QueryText +
		"SELECT TOP 1
		|""" + Record.Name + """ AS RegisterName
		|
		|FROM " + Record.FullName() + "
		|
		|WHERE Recorder = &Recorder
		|";

		If TablesCounter = 256 OR CycleCounter = TotalRegisters Then

			Query = New Query(QueryText);
			Query.SetParameter("Recorder", Recorder);

			QueryText  		= "";
			TablesCounter 	= 0;

			If RegistersArray.Count() = 0 Then

				RegistersArray = Query.Execute().Unload().UnloadColumn("RegisterName");

			Else

				Selection = Query.Execute().Select();

				While Selection.Next() Do

					RegistersArray.Add(Selection.RegisterName);

				EndDo;

			EndIf;

		EndIf;

	EndDo;

	Return RegistersArray;

EndFunction // GetNamesArrayOfUsedRegisters()

#EndRegion // Private