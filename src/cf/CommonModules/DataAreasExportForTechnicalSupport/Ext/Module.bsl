﻿
#Region Internal

// Parameters:
// 	Container - DataProcessorObject.ExportImportDataContainerManager - 
// 	HandlersTable - See ExportImportDataOverridable.OnRegisterDataExportHandlers.HandlersTable
Procedure BeforeExportData(Container, HandlersTable) Export
	
	If Not Container.ForTechnicalSupport() Then
		Return;
	EndIf;
			
	For Each MetadataObject In DataAreasExportForTechnicalSupportCached.MetadataExcludedFromUploadingInTechnicalSupportMode() Do
				
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = MetadataObject;
		NewHandler.Handler = DataAreasExportForTechnicalSupport;
		NewHandler.BeforeUnloadingType = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
					
	EndDo;
			
	MetadataList = DataAreasExportForTechnicalSupportCached.MetadataThatHasLinksToThoseExcludedFromUploadingInTechnicalSupportMode();
	
	For Each ListItem In MetadataList Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Metadata.FindByFullName(ListItem.Key);
		NewHandler.Handler = DataAreasExportForTechnicalSupport;
		NewHandler.BeforeExportObject = True;
		NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
		
	EndDo;
		
EndProcedure

Procedure BeforeUnloadingType(Container, Serializer, MetadataObject, Cancel) Export
	
	Cancel = True;
	
EndProcedure

Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	MetadataObject = Object.Metadata();
	
	ItemDetailsThatHaveLinksToItemsExcludedFromUploading = ItemDetailsThatHaveLinksToItemsExcludedFromUploading(MetadataObject);
	
	If ItemDetailsThatHaveLinksToItemsExcludedFromUploading = Undefined Then
		
		Raise StrTemplate(NStr("en = 'The %2 handler cannot process the %1 metadata object.';"),
			MetadataObject.FullName(),
			"UploadingDataAreasForTechnicalSupport.BeforeExportObject");
		
	EndIf;
	
	If CommonCTL.IsConstant(MetadataObject) Then
		
		BeforeUnloadingConstant(Object);
		
	ElsIf CommonCTL.IsRefData(MetadataObject) Then
		
		BeforeUnloadingReferenceObject(Object, ItemDetailsThatHaveLinksToItemsExcludedFromUploading);
		
	ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
		
		BeforeExportRecordSet(MetadataObject, Object, ItemDetailsThatHaveLinksToItemsExcludedFromUploading);
		
	Else
		
		Raise StrTemplate(NStr("en = 'Unexpected metadata object: %1.';"),
		MetadataObject.FullName);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure BeforeUnloadingConstant(Object)
	
	ClearReferenceToObjectBeingExcludedFromUploading(Object.Value);
	
EndProcedure

Procedure BeforeUnloadingReferenceObject(Object, ItemDetailsThatHaveLinksToItemsExcludedFromUploading)
	
	For Each CurrentAttribute In ItemDetailsThatHaveLinksToItemsExcludedFromUploading Do
		
		AttributeName = CurrentAttribute.AttributeName;

		If CurrentAttribute.TabularSectionName = Undefined Then
						
			ClearReferenceToObjectBeingExcludedFromUploading(Object[AttributeName]);		
			
		Else
			
			TabularSectionName = CurrentAttribute.TabularSectionName;
			
			For Each LineOfATabularSection In Object[TabularSectionName] Do 
				
				ClearReferenceToObjectBeingExcludedFromUploading(LineOfATabularSection[AttributeName]);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure BeforeExportRecordSet(MetadataObject, RecordSet, ItemDetailsThatHaveLinksToItemsExcludedFromUploading)
	
	ArrayOfPossibleDimensions = New Array;
	ArrayOfPossibleDimensions.Add("Recorder");
	
	If CommonCTL.IsAccountingRegister(MetadataObject) Then
		ArrayOfPossibleDimensions.Add("AccountDr");
		ArrayOfPossibleDimensions.Add("AccountCr");		
		ArrayOfPossibleDimensions.Add("Account");
	EndIf;
	
	For Each MetadataObjectDimension In MetadataObject.Dimensions Do
		ArrayOfPossibleDimensions.Add(MetadataObjectName(MetadataObjectDimension));
	EndDo;
	
	For Each CurrentAttribute In ItemDetailsThatHaveLinksToItemsExcludedFromUploading Do
		
		PropertyName = CurrentAttribute.AttributeName;
		SetOfRecordsInBoundary = RecordSet.Count() - 1;
		
		If SetOfRecordsInBoundary < 0 Then
			Break;
		EndIf;
		
		For IndexOfRecord = 0 To SetOfRecordsInBoundary Do
			
			Record = RecordSet[SetOfRecordsInBoundary - IndexOfRecord];
			
			If ClearReferenceToObjectBeingExcludedFromUploading(Record[PropertyName]) 
				And ArrayOfPossibleDimensions.Find(PropertyName) <> Undefined Then
				
				RecordSet.Delete(Record);
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function ClearReferenceToObjectBeingExcludedFromUploading(Ref)
	
	If Not ValueIsFilled(Ref) Or Not Common.IsReference(TypeOf(Ref)) Then
		Return False;
	EndIf;
	
	MetadataExcludedFromUploading = DataAreasExportForTechnicalSupportCached.MetadataExcludedFromUploadingInTechnicalSupportMode();
	RefMetadata = Ref.Metadata();
	
	If MetadataExcludedFromUploading.Find(RefMetadata) = Undefined Then
		Return False;
	EndIf;
	
	Ref = Undefined;	
	
	Return True;
	
EndFunction

Function ItemDetailsThatHaveLinksToItemsExcludedFromUploading(Val ObjectMetadata)
	
	FullMetadataName = ObjectMetadata.FullName();
	
	MetadataList = DataAreasExportForTechnicalSupportCached.MetadataThatHasLinksToThoseExcludedFromUploadingInTechnicalSupportMode();
	
	Return MetadataList.Get(FullMetadataName);
	
EndFunction

// Returns the name of the given metadata object.
// 
// Parameters:
// 	MetadataObject - MetadataObject - Metadata object.
// Returns:
// 	String - metadata object name.
Function MetadataObjectName(MetadataObject)
	
	Return MetadataObject.Name;
	
EndFunction
#EndRegion
