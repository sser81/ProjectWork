////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing) Export

	If FillingData = Undefined Then // Create a new item.
		_DemoStandardSubsystems.OnEnterNewItemFillCompany(ThisObject, "Entity");
	EndIf;

EndProcedure // Filling()

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If ValueIsFilled(TypeOfLimits) Then
		TypeOfLimitOneTime = Common.ObjectAttributeValue(TypeOfLimits, "OneTime");
	Else
		TypeOfLimitOneTime = True;
	EndIf;

	If Not TypeOfLimitOneTime Then
		Ind = CheckedAttributes.Find("StageOfLimit");
		If Ind = Undefined Then
			CheckedAttributes.Add("StageOfLimit");
		EndIf;
	EndIf;

EndProcedure // FillCheckProcessing() 

Procedure Posting(Cancel, PostingMode)

	// Initialization of additional properties for document posting.
	DocumentPosting.InitializeAdditionalPropertiesForPosting(Ref, AdditionalProperties);

	// Initialization of document data.
	LimitsForEmployeesServer.DataInitializationDocument(Ref, AdditionalProperties);

	// Prepare recordsets.
	DocumentPosting.PrepareRecordSetsForRecording(ThisObject);

	// Reflect in accounting sections.
	LimitsForEmployeesServer.ReflectRecordsByEmployeeLimits(AdditionalProperties, RegisterRecords, Cancel);

	// Write recordsets.
	DocumentPosting.WriteRecordSets(ThisObject);

	AdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager.Close();

EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)

	Prefix = "A";

EndProcedure

#EndRegion
