﻿#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal

Function RegisterRequest(Query, RequestType_, AdditionalParameters = Undefined) Export
	
	Result = Undefined;
	
	If RequestType_ = Metadata.HTTPServices.DataTransfer.URLTemplates.StorageAndID.Methods.POST.FullName()
		Or RequestType_ = Metadata.HTTPServices.DataTransfer.URLTemplates.VolumeAndPathToFile.Methods.POST.FullName() Then
		Result = DataTransferInternal.TempFileName(, AdditionalParameters);
	EndIf;
	
	If TypeOf(Result) = Type("Structure") Then
		TempFileName = Result.TempFileName;
		S3Address = Result.S3Address;
		FileID = Result.FileID;
	Else
		TempFileName = Result;
		S3Address = Undefined;
		FileID = Undefined;
	EndIf;
	
	RequestStructure = New Structure;
	
	RequestStructure.Insert("HTTPMethod", Query.HTTPMethod);
	RequestStructure.Insert("BaseURL", Query.BaseURL);
	RequestStructure.Insert("Headers", HeadersWithoutAuthorization(Query.Headers));
	RequestStructure.Insert("RelativeURL", Query.RelativeURL);
	RequestStructure.Insert("URLParameters", Query.URLParameters);
	RequestStructure.Insert("QueryOptions", Query.QueryOptions);
	RequestStructure.Insert("QueryID", String(New UUID));
	RequestStructure.Insert("RequestType_", RequestType_);
	RequestStructure.Insert("TempFileName", TempFileName);
	RequestStructure.Insert("AdditionalParameters", AdditionalParameters);
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, RequestStructure);
	
	JSONRequest = JSONWriter.Close();
	
	DataHashing = New DataHashing(HashFunction.SHA256);
	DataHashing.Append(JSONRequest);
	Id = Lower(StrReplace(String(DataHashing.HashSum), " ", ""));
	
	RecordManager = CreateRecordManager();
	
	RecordManager.Id = Id;
	RecordManager.Date = CurrentUniversalDate();
	RecordManager.Query = New ValueStorage(JSONRequest);
	
	SetPrivilegedMode(True);
	RecordManager.Write(False);
	SetPrivilegedMode(False);
	
	Return New Structure("Id, S3Address, FileID", Id, S3Address, FileID);
	
EndFunction


// Returns request date by the request ID.
// 
// Parameters:
// 	Id - String - Request ID.
// 	
// Returns:
// 	Structure, Undefined - Initial request.:
//   * HTTPMethod - String - HTTP method. 
//   * BaseURL - String - Base part of the URL request. 
//   * Headers - FixedMap - HTTP request headers. 
//   * RelativeURL - String - Relative part of the URL address. 
//   * URLParameters - FixedMap - Parts of URL address that were parametrized in the template.
//   * QueryOptions - FixedMap - Request parameters.
//   * QueryID - String - query UUID.
//   * RequestType_ - String - Request type. 
//   * TempFileName - String - a temporary file name.
//   * AdditionalParameters - Arbitrary - Additional parameters.
//
Function RequestByID(Id) Export
	
	Query = Undefined;
	
	RecordManager = CreateRecordManager();
	RecordManager.Id = Lower(Id);
	
	SetPrivilegedMode(True);
	RecordManager.Read();
	SetPrivilegedMode(False);
	
	If RecordManager.Selected() Then
		
		If CurrentUniversalDate() - RecordManager.Date < DataTransferInternal.ValidityPeriodOfTemporaryID() Then
			
			JSONReader = New JSONReader;
			JSONReader.SetString(RecordManager.Query.Get());
			Query = ReadJSON(JSONReader, True);
			
		EndIf;
		
	EndIf;
	
	Return Query;
		
EndFunction

Procedure ExtendTemporaryID(Id) Export
	
	RecordManager = CreateRecordManager();
	RecordManager.Id = Lower(Id);
	
	SetPrivilegedMode(True);
	RecordManager.Read();
	SetPrivilegedMode(False);
	
	If RecordManager.Selected() Then
		
		RecordManager.Date = CurrentUniversalDate();
		
		DataTransferInternal.OnExtendTemporaryIDValidity(Id, RecordManager);
		
		SetPrivilegedMode(True);
		RecordManager.Write(True);
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

Procedure DeleteExpiredRequests() Export

	SetPrivilegedMode(True);

	Try

		Query = New Query;
		Query.SetParameter("ShelfLife", BegOfDay(CurrentUniversalDate()) - 86400 * 7);
		Query.Text =
		"SELECT TOP 10
		|	TemporaryQueriesIDs.Id AS Id
		|FROM
		|	InformationRegister.TemporaryQueriesIDs AS TemporaryQueriesIDs
		|WHERE
		|	TemporaryQueriesIDs.Date < &ShelfLife
		|
		|ORDER BY
		|	TemporaryQueriesIDs.Date";

		Result = Query.Execute();
		If Result.IsEmpty() Then
			Return;
		EndIf;

		Selection = Result.Select();
		While Selection.Next() Do

			RecordKey = CreateRecordKey(New Structure("Id", Selection.Id));
			Try
				LockDataForEdit(RecordKey);
			Except
				Continue;
			EndTry;

			RecordManager = CreateRecordManager();
			RecordManager.Id = Selection.Id;
			RecordManager.Delete();

		EndDo;

	Except

		WriteLogEvent(NStr("en = 'DataTransfer';", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , DataTransferClientServer.DetailedErrorText(ErrorInfo()));

	EndTry;

EndProcedure

#EndRegion

#Region Private

Function HeadersWithoutAuthorization(Headers)

	If TypeOf(Headers) <> Type("FixedMap") And TypeOf(Headers) <> Type("Map") Then
		Return Headers;
	EndIf;
	
	Result = New Map();
	
	For Each CollectionItem In Headers Do
		
		TitleName = CollectionItem.Key;
		HeaderValue = CollectionItem.Value;
		
		If Lower(TitleName) = "authorization" Then
			AuthorizationElements = StrSplit(HeaderValue, " ", False);
			If AuthorizationElements.Count() > 1 Then
				HeaderValue = AuthorizationElements[0] + " ***";
			Else
				HeaderValue = "***";
			EndIf;	
		EndIf;
		
		Result.Insert(TitleName, HeaderValue);
		
	EndDo;
	
	Return New FixedMap(Result);

EndFunction

#EndRegion

#EndIf