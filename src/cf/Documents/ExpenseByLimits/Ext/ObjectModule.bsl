////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing) Export

	If FillingData = Undefined Then // Create a new item.
		_DemoStandardSubsystems.OnEnterNewItemFillCompany(ThisObject, "Entity");
	EndIf;

EndProcedure // Filling()

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	arrTypeOfLimit = LimitsForEmployees.UnloadColumn("TypeOfLimit");
	mapTypeOfLimitOneTime = Common.ObjectsAttributeValue(arrTypeOfLimit, "OneTime");
	
	For Each LimitsForEmployeesRow In LimitsForEmployees Do

		If ValueIsFilled(LimitsForEmployeesRow.TypeOfLimit)
			And Not mapTypeOfLimitOneTime[LimitsForEmployeesRow.TypeOfLimit]
			And Not ValueIsFilled(LimitsForEmployeesRow.Stage) Then

			TextTemplate = NStr("ru = 'В строке %1 табличной части ""Лимиты"" не заполнено значение периода (этапа).';
								|en = 'Stage value on row %1 of table ""Lumits"" not filled.'");

			CommonClientServer.MessageToUser(
				StrTemplate(TextTemplate, LimitsForEmployeesRow.LineNumber),,
				StrTemplate("LimitsForEmployees[%1].Stage", LimitsForEmployees.IndexOf(LimitsForEmployeesRow)),
				"Object",
				Cancel);		
		EndIf;
	EndDo;

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
