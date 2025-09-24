﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("Reports.*");
	Result.Add("ReportFormats.*");
	Result.Add("Recipients.*");
	
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsAuthorizedUser(Author)
	|	OR Personal = FALSE
	|	OR Predefined = TRUE";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.ReportsOptions

// Defines the list of report commands.
//
// Parameters:
//   ReportsCommands - ValueTable - a table with report commands. For changing.
//       See details of parameter 1 of the ReportsOptionsOverridable.BeforeAddReportsCommands() procedure.
//   Parameters - Structure - auxiliary parameters. For reading.
//       See details of parameter 2 of the ReportsOptionsOverridable.BeforeAddReportsCommands() procedure.
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	If AccessRight("View", Metadata.Reports.ReportDistributionControl)
		And GetFunctionalOption("RetainReportDistributionHistory") Then
		Command = ReportsCommands.Add();
		Command.Presentation = NStr("en = 'Report distribution control';");
		Command.VariantKey  = "ReportDistributionControl";
		Command.Picture  = PictureLib.Report;
		Command.MultipleChoice = False;
		Command.Manager = "Report.ReportDistributionControl";
		Command.ParameterType = New TypeDescription("CatalogRef.ReportMailings");
	EndIf;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

// StandardSubsystems.Print

// Generates print forms.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ModulePrintManager.OutputSpreadsheetDocumentToCollection(
				PrintFormsCollection,
				"ReportDistributionPasswords", 
				NStr("en = 'Passwords for report distribution';"),
				PrintFormReportDistributionPasswords(PrintParameters, PrintObjects),
				,
				"Catalog.ReportMailings.PrintForm_MXL_ReportDistributionPasswords", NStr("en = 'Passwords for report distribution';"));
	EndIf;
	
EndProcedure

// End StandardSubsystems.Print

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the ObjectsVersioning subsystem.
//
// Parameters:
//   Settings - Structure - Subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure

// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndRegion

#Region Private

// Registers report distributions for processing.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	ReportMailings.Ref
		|FROM
		|	Catalog.ReportMailings AS ReportMailings
		|WHERE
		|	NOT ReportMailings.IsFolder
		|	AND NOT ReportMailings.ShouldInsertReportsIntoEmailBody
		|	AND NOT ReportMailings.ShouldAttachReports";
	
	QueryResult = Query.Execute().Unload();

	InfobaseUpdate.MarkForProcessing(Parameters,
		QueryResult.UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ReportsDistributionRef = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.ReportMailings");
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	SetReportsDescriptionTemplates = SetReportsDescriptionTemplates();
	
	While ReportsDistributionRef.Next() Do
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.ReportMailings");
		LockItem.SetValue("Ref", ReportsDistributionRef.Ref);
		
		RepresentationOfTheReference = String(ReportsDistributionRef.Ref);
		
		BeginTransaction();
		Try
			
			Block.Lock();
			
			ReportDistributionObject = ReportsDistributionRef.Ref.GetObject(); // CatalogObject.ReportMailings
			
			// During a configuration update, predefined items might be registered in the exchange plan even if auto-registration is disabled.
			// Therefore, explicitly skip groups (including the predefined group "PersonalMailings").
			If ReportDistributionObject.IsFolder Then
				InfobaseUpdate.MarkProcessingCompletion(ReportsDistributionRef.Ref);
				ObjectsProcessed = ObjectsProcessed + 1;
				CommitTransaction();
				Continue;
			EndIf;
			
			FilterParameters = New Structure;
			FilterParameters.Insert("Format", Enums.ReportSaveFormats.HTML4);
			
			ArrayOfFormatStrings = ReportDistributionObject.ReportFormats.FindRows(FilterParameters);
			
			For Each String In ArrayOfFormatStrings Do
				String.Format = Enums.ReportSaveFormats.HTML;
			EndDo;
			
			If SetReportsDescriptionTemplates Then
				
				FilterParameters = New Structure("DescriptionTemplate", "");
				RowsWithoutNamingTemplates = ReportDistributionObject.Reports.FindRows(FilterParameters);
				
				If ReportDistributionObject.DeleteIncludeDateInFileName Then
					DefaultTemplate = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = '%1 dated %2 %3';"), "[ReportDescription1]", "[MailingDate()]", "[ReportFormat]");
				Else
					DefaultTemplate = "[ReportDescription1] [ReportFormat]";
				EndIf;
				
				For Each String In RowsWithoutNamingTemplates Do
					String.DescriptionTemplate = DefaultTemplate;
				EndDo;
			EndIf;
			
			If Not ReportDistributionObject.ShouldInsertReportsIntoEmailBody And Not ReportDistributionObject.ShouldAttachReports Then
				If ReportDistributionObject.Personalized Or ReportDistributionObject.Personal Then
					ReportDistributionObject.ShouldAttachReports = True;
				ElsIf ReportDistributionObject.UseEmail And Not ReportDistributionObject.NotifyOnly Then
					ReportDistributionObject.ShouldAttachReports = True;
				EndIf;
			EndIf;
			
			InfobaseUpdate.WriteData(ReportDistributionObject);
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			// If failed to process a report distribution, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				ReportsDistributionRef.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.ReportMailings");
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot process some report distributions (skipped): %1';"), 
				ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.ContactInformationKinds,,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Another batch of report distributions is processed: %1';"),
					ObjectsProcessed));
	EndIf;
	
EndProcedure

Function SetReportsDescriptionTemplates()
		
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	ReportMailingsReports.Ref
		|FROM
		|	Catalog.ReportMailings.Reports AS ReportMailingsReports
		|WHERE
		|	ReportMailingsReports.DescriptionTemplate <> """"";
	
	QueryResult = Query.Execute();
	
	Return QueryResult.IsEmpty();
	
EndFunction

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = False;
	
EndProcedure

// See also InfobaseUpdateOverridable.OnInitialItemsFilling
// 
// Parameters:
//   LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//   Items - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//   TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	Item = Items.Add();
	Item.PredefinedDataName = "PersonalMailings";
	Item.Description              = NStr("en = 'Personal distributions';", Common.DefaultLanguageCode());
	
EndProcedure

Function RecipientsCountIncludingGroups(Val RecipientsParameters) Export

	NumberOfRecipients = New Structure("Total, ExcludedCount", 0, Undefined);
	
	If RecipientsParameters.MailingRecipientType = Undefined Then
		Return NumberOfRecipients;
	EndIf;
	
	Query = New Query;
	RecipientsList = New Map;
	ReportMailingOverridable.BeforeGenerateMailingRecipientsList(RecipientsParameters, Query, True, RecipientsList);
	
	If ValueIsFilled(Query.Text) Then
		BulkEmailRecipients = ReportMailing.GenerateMailingRecipientsList(RecipientsParameters, Undefined);
		NumberOfRecipients.Total = BulkEmailRecipients.Count();
		Return NumberOfRecipients;
	EndIf;
	
	RecipientsMetadata = Common.MetadataObjectByID(RecipientsParameters.MailingRecipientType, False);
	
	If RecipientsMetadata = Undefined Or RecipientsMetadata = Null Then
		Return NumberOfRecipients;
	EndIf;
	
	RecipientsType = RecipientsParameters.MailingRecipientType.MetadataObjectKey.Get();

	Query = New Query;

	If RecipientsType = Type("CatalogRef.Users") Then

		QueryText =
		"SELECT
		|	TableOfRecipients.Recipient,
		|	TableOfRecipients.Excluded
		|INTO TableOfRecipients
		|FROM
		|	&TableOfRecipients AS TableOfRecipients
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	User.Ref AS Recipient,
		|	MAX(TableOfRecipients.Excluded) AS Excluded
		|INTO Recipients
		|FROM
		|	TableOfRecipients AS TableOfRecipients
		|		LEFT JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|		ON UserGroupCompositions.UsersGroup = TableOfRecipients.Recipient
		|		LEFT JOIN Catalog.Users AS Users
		|		ON Users.Ref = UserGroupCompositions.User
		|WHERE
		|	NOT Users.DeletionMark
		|	AND NOT Users.Invalid
		|	AND NOT Users.IsInternal
		|GROUP BY
		|	User.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	COUNT(Recipients.Recipient) AS NumOfExcluded,
		|	0 AS QtyToSend
		|INTO NumberOfRecipients
		|FROM
		|	Recipients AS Recipients
		|WHERE
		|	Recipients.Excluded
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	0 AS NumOfExcluded,
		|	COUNT(Recipients.Recipient) AS QtyToSend
		|FROM
		|	Recipients AS Recipients
		|WHERE
		|	NOT Recipients.Excluded
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(NumberOfRecipients.NumOfExcluded) AS NumOfExcluded,
		|	SUM(NumberOfRecipients.QtyToSend) AS QtyToSend
		|FROM
		|	NumberOfRecipients AS NumberOfRecipients";

	Else

		QueryText =
		"SELECT
		|	TableOfRecipients.Recipient,
		|	TableOfRecipients.Excluded
		|INTO TableOfRecipients
		|FROM
		|	&TableOfRecipients AS TableOfRecipients
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	COUNT(TRUE) AS NumOfExcluded,
		|	SUM(0) AS QtyToSend
		|INTO NumberOfRecipients
		|FROM
		|	Catalog.Users AS Recipients
		|WHERE
		|	Recipients.Ref IN HIERARCHY
		|		(SELECT
		|			Recipient
		|		FROM
		|			TableOfRecipients
		|		WHERE
		|			Excluded)
		|	AND NOT Recipients.DeletionMark
		|	AND &ThisIsNotGroup
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	SUM(0) AS NumOfExcluded,
		|	COUNT(FALSE) AS QtyToSend
		|FROM
		|	Catalog.Users AS Recipients
		|WHERE
		|	Recipients.Ref IN HIERARCHY
		|		(SELECT
		|			Recipient
		|		FROM
		|			TableOfRecipients
		|		WHERE
		|			NOT Excluded)
		|	AND NOT Recipients.DeletionMark
		|	AND &ThisIsNotGroup
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(NumberOfRecipients.NumOfExcluded) AS NumOfExcluded,
		|	SUM(NumberOfRecipients.QtyToSend) AS QtyToSend
		|FROM
		|	NumberOfRecipients AS NumberOfRecipients";

		If Not RecipientsMetadata.Hierarchical Then
			// Not hierarchical item.
			QueryText = StrReplace(QueryText, "IN HIERARCHY", "In");
			QueryText = StrReplace(QueryText, "AND &ThisIsNotGroup", "");
		ElsIf RecipientsMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyOfItems Then
			// Hierarchy of items.
			QueryText = StrReplace(QueryText, "AND &ThisIsNotGroup", "");
		Else
			// Hierarchy of groups.
			QueryText = StrReplace(QueryText, "AND &ThisIsNotGroup", "AND NOT Recipients.IsFolder");
		EndIf;

		QueryText = StrReplace(QueryText, "Catalog.Users", RecipientsMetadata.FullName());

	EndIf;

	Query.SetParameter("TableOfRecipients", RecipientsParameters.Recipients.Unload());
	Query.Text = QueryText;

	Try
		QueryResult = Query.Execute();
		SampleRecipients = QueryResult.Select();
		If SampleRecipients.Next() Then
			NumberOfRecipients.Total = SampleRecipients.QtyToSend;
			NumberOfRecipients.ExcludedCount = SampleRecipients.NumOfExcluded;
		EndIf;
	Except
		Return NumberOfRecipients;
	EndTry;

	Return NumberOfRecipients;

EndFunction

Function PrintFormReportDistributionPasswords(Parameters, PrintObjects)
	
	SpreadsheetDocument = New SpreadsheetDocument;

	Template = GetTemplate("PrintForm_MXL_ReportDistributionPasswords");

	RowNumberStart = SpreadsheetDocument.TableHeight + 1;
	
	PrintTitle = Template.GetArea("Title");

	PrintTitle.Parameters.Title =  StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Passwords to receive the %1 ""%2"" report distribution';"), Chars.LF, Parameters.MailingDescription);

	SpreadsheetDocument.Put(PrintTitle);

	TableHeader = Template.GetArea("TableHeader");
	SpreadsheetDocument.Put(TableHeader);

	TableRow = Template.GetArea("TableRow");

	Query = New Query;
	QueryText =
	"SELECT
	|	TableRecipients.Recipient,
	|	TableRecipients.Email,
	|	TableRecipients.ArchivePassword
	|INTO TableRecipients
	|FROM
	|	&TableRecipients AS TableRecipients
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CatalogRecipients.Description AS Recipient,
	|	Recipients.Email,
	|	Recipients.ArchivePassword
	|FROM
	|	TableRecipients AS Recipients
	|	LEFT JOIN Catalog.Users AS CatalogRecipients
	|		ON CatalogRecipients.Ref = Recipients.Recipient";

	RecipientsMetadata = Common.MetadataObjectByID(Parameters.MetadataObjectID,
		False);
	QueryText = StrReplace(QueryText, "Catalog.Users", RecipientsMetadata.FullName());

	TableRecipients = New ValueTable;
	TableRecipients.Columns.Add("Recipient", Parameters.MailingRecipientType);
	TableRecipients.Columns.Add("Email", New TypeDescription("String", ,
		New StringQualifiers(250)));
	TableRecipients.Columns.Add("ArchivePassword", New TypeDescription("String", , New StringQualifiers(50)));

	For Each RecipientItem In Parameters.Recipients Do
		RowRecipients = TableRecipients.Add();
		FillPropertyValues(RowRecipients, RecipientItem);
	EndDo;

	Query.SetParameter("TableRecipients", TableRecipients);
	Query.Text = QueryText;

	LineNumber = 1;

	QueryResult = Query.Execute();
	Selection= QueryResult.Select();

	While Selection.Next() Do
		FillPropertyValues(TableRow.Parameters, Selection);
		TableRow.Parameters.LineNumber = LineNumber;
		SpreadsheetDocument.Put(TableRow);
		LineNumber = LineNumber + 1;
	EndDo;

	SpreadsheetDocument.FitToPage = True;

	ModulePrintManager = Common.CommonModule("PrintManagement");
	ModulePrintManager.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Parameters.Ref);

	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#EndIf

