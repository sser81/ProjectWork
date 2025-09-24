///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	WindowsFolder = "%APPDATA%\1C\1Cv8\ExtCompT";
	WindowsFolderWeb = "%ProgramData%\1C\1CEWebExt";
	
	LinuxFolder = "~/.1cv8/1C/1cv8/ExtCompT/";
	LinuxFolderWeb = "~/bin";
	
	GenerateInformationPresentation();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AttachAddInWithoutCaching(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Key", "Value");
	
	Notification = New NotifyDescription("AttachComponentAfterAttachment", ThisObject, AdditionalParameters);
	
	ConnectionParameters = AddInsClient.ConnectionParameters();
	ConnectionParameters.Cached = False;
	ConnectionParameters.ExplanationText = 
		NStr("en = 'Demo: To use a barcode scanner, the
		           |""1C:Barcode scanners (NativeApi)"" add-in is required.';");
	
	AddInsClient.AttachAddInSSL(Notification, "InputDevice",, ConnectionParameters);
	
EndProcedure

&AtClient
Procedure AttachAddInSSL(Command)

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Key", "Value");
	
	Notification = New NotifyDescription("AttachComponentAfterAttachment", ThisObject, AdditionalParameters);
	
	ConnectionParameters = AddInsClient.ConnectionParameters();
	ConnectionParameters.ExplanationText = 
		NStr("en = 'Demo: To use a barcode scanner, the
		           |""1C:Barcode scanners (NativeApi)"" add-in is required.';");
	
	AddInsClient.AttachAddInSSL(Notification, "InputDevice", "8.1.7.1", ConnectionParameters);
	
EndProcedure

&AtClient
Procedure AttachCOMComponent(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Key", "Value");
	
	Notification = New NotifyDescription("AttachComponentAfterAttachment", ThisObject, AdditionalParameters);
	
	ConnectionParameters = AddInsClient.ConnectionParameters();
	ConnectionParameters.ExplanationText = 
		NStr("en = 'Demo: To use a barcode scanner, the
		           |""1C:Barcode scanners"" add-in is required.';");
	
	AddInsClient.AttachAddInSSL(Notification, "Scanner",, ConnectionParameters);
	
EndProcedure

&AtClient
Procedure AttachAddInFromTemplate(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Key", "Value");
	
	Notification = New NotifyDescription("AttachComponentAfterAttachment", ThisObject, AdditionalParameters);
	
	ConnectionParameters = CommonClient.AddInAttachmentParameters();
	ConnectionParameters.ExplanationText = 
		NStr("en = 'Demo: To scan documents, attach the add-in.';");
	ConnectionParameters.Cached = False;
	
	CommonClient.AttachAddInFromTemplate(Notification, 
	"ImageScan",
	"CommonTemplate.DocumentScanningAddIn",
	ConnectionParameters);
	
EndProcedure

&AtClient
Procedure AttachAddInFromWindowsRegistry(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Key", "Value");
	
	Notification = New NotifyDescription("AttachComponentAfterAttachment", ThisObject, AdditionalParameters);
	
	AddInsClient.AttachAddInFromWindowsRegistry(Notification, "SBRFCOMObject", "SBRFCOMExtension");
	
EndProcedure

&AtClient
Procedure AttachAddInFromTemplateAtServer(Command)
	
	ClearMessages();
	AttachComponentFromTemplateAtServerAtServer();
	
EndProcedure

&AtClient
Procedure AttachAddInSSLAtServer(Command)
	ClearMessages();
	AttachAddInSSLAtServerAtServer();
EndProcedure

&AtClient
Procedure InstallAddInSSL(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Key", "Value");
	
	InstallationParameters = AddInsClient.InstallationParameters();
	InstallationParameters.ExplanationText = 
		NStr("en = 'Demo: To use a barcode scanner, the
		           |""1C:Barcode scanners (NativeApi)"" add-in is required.';");
	
	Notification = New NotifyDescription(
		"InstallAddInAfterInstall", ThisObject, AdditionalParameters);
	
	AddInsClient.InstallAddInSSL(Notification, "InputDevice",, InstallationParameters);
	
EndProcedure

&AtClient
Procedure InstallAddInFromTemplate(Command)
	
	Notification = New NotifyDescription("InstallAddInAfterInstall", ThisObject);
	
	InstallationParameters = CommonClient.AddInInstallParameters();
	InstallationParameters.ExplanationText = 
		NStr("en = 'To submit a certificate application,
		           |install the CryptS add-in.';");
	
	CommonClient.InstallAddInFromTemplate(Notification,
		"DataProcessor._DemoAddInOperations.Template.ExchangeComponent",
		InstallationParameters);
	
EndProcedure

&AtClient
Procedure ImportExternalModuleFromFile(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Key", "Value");
	
	ImportParameters = AddInsClient.ImportParameters();
	ImportParameters.Id = Id;
	ImportParameters.Version = Version;
	
	Notification = New NotifyDescription(
		"ImportExternalModuleFromFileAfterIimport", ThisObject, AdditionalParameters);
	
	AddInsClient.ImportAddInFromFile(Notification, ImportParameters);
	
EndProcedure

&AtClient
Procedure ImportExternalModuleFromFileWithAdditionalInformation(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Key", "Value");
	
	DriverTypeSearchParameters = AddInsClient.AdditionalInformationSearchParameters();
	DriverTypeSearchParameters.XMLFileName = "INFO.XML";
	DriverTypeSearchParameters.XPathExpression = "//drivers/component/@type";
	
	ImportParameters = AddInsClient.ImportParameters();
	ImportParameters.Id = Id;
	ImportParameters.Version = Version;
	ImportParameters.AdditionalInformationSearchParameters.Insert("DriverType", DriverTypeSearchParameters);
	
	Notification = New NotifyDescription(
		"ImportExternalModuleFromFileAfterIimport", ThisObject, AdditionalParameters);
	
	AddInsClient.ImportAddInFromFile(Notification, ImportParameters);
	
EndProcedure

&AtClient
Procedure GetInformation(Command)
	
	ClearMessages();
	GetInformationAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AttachComponentAfterAttachment(Result, AdditionalParameters) Export
	
	If Result.Attached Then 
		Attachable_Module = Result.Attachable_Module;
		If Attachable_Module <> Undefined Then 
			ShowMessageBox(, NStr("en = 'The add-in is attached successfully.';"));
		EndIf;
	ElsIf Not IsBlankString(Result.ErrorDescription) Then 
		ShowMessageBox(, Result.ErrorDescription);
	EndIf;
	
EndProcedure

&AtServer
Procedure AttachComponentFromTemplateAtServerAtServer()
	
	Attachable_Module = Common.AttachAddInFromTemplate(
		"CryptS", "DataProcessor._DemoAddInOperations.Template.ExchangeComponent");
	If Attachable_Module = Undefined Then
		Common.MessageToUser(NStr("en = 'Demo: Add-in is not attached';"));
	Else
		Common.MessageToUser(NStr("en = 'Demo: Successful attachment';"));
	EndIf;
	
	Attachable_Module = Undefined;
	
EndProcedure

&AtServer
Procedure AttachAddInSSLAtServerAtServer()
	Result = AddInsServer.AttachAddInSSL("CustomerDisplay1C");
	If Not Result.Attached Then
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Demo: Cannot attach the add-in: %1';"),
			Result.ErrorDescription));
	Else
		Common.MessageToUser(NStr("en = 'Demo: Successful attachment';"));
	EndIf;
EndProcedure

&AtClient
Procedure InstallAddInAfterInstall(Result, AdditionalParameters) Export
	
	If Result.IsSet Then 
		ShowMessageBox(, NStr("en = 'The add-in is installed successfully.';"));
	ElsIf Not IsBlankString(Result.ErrorDescription) Then
		ShowMessageBox(, Result.ErrorDescription);
	EndIf;
	
EndProcedure

// Parameters:
//  Result - See AddInInformation
//  AdditionalParameters - Arbitrary
//
&AtClient
Procedure ImportExternalModuleFromFileAfterIimport(Result, AdditionalParameters) Export
	
	If Result.Imported1 Then 
		
		AddInInformation = AddInInformation();
		FillPropertyValues(AddInInformation, Result);
		Id = Result.Id;
		Version        = Result.Version;
		DriverType = Result.AdditionalInformation.Get("DriverType");
		
		ShowMessageBox(, NStr("en = 'The add-in is imported successfully';"));
	Else 
		ShowMessageBox(, NStr("en = 'The add-in is not imported';"));
	EndIf;
	
	GenerateInformationPresentation();
	
EndProcedure

// Returns:
//  Structure:
//   * Description - String
//   * Version - String
//   * Id - String
//
&AtClientAtServerNoContext
Function AddInInformation()
	
	Information = New Structure;
	Information.Insert("Id");
	Information.Insert("Version");
	Information.Insert("Description");
	Return Information;
	
EndFunction

&AtServer
Procedure GenerateInformationPresentation()
	
	If ValueIsFilled(AddInInformation) Then 
		
		Template = NStr("en = 'Demo:%1. Version %2.';");
		Information = AddInInformation; // See AddInInformation
		Items.ExternalModuleInformation.Title = StringFunctionsClientServer.SubstituteParametersToString(Template,
			Information.Description, Information.Version);
			
		Items.ImportExternalModuleFromFile.Title = NStr("en = 'Demo: Update from file…';");
		Items.ImportExternalModuleFromFileWithAdditionalInformation.Title = 
			NStr("en = 'Demo: Update from file (with determining driver type)…';");
	Else
		Items.ExternalModuleInformation.Title = NStr("en = 'Demo: Not imported.';");
		Items.ImportExternalModuleFromFile.Title = NStr("en = 'Demo: Import from file…';");
		Items.ImportExternalModuleFromFileWithAdditionalInformation.Title = 
			NStr("en = 'Demo: Import from file (with determining driver type)…';");
	EndIf;
	
EndProcedure

&AtServer
Procedure GetInformationAtServer()
	
	Result = AddInServerCall.AddInInformation(Id,
		?(IsBlankString(Version), Undefined, Version));
		
	If Result.Exists Then
		AddInInformation = AddInInformation();
		FillPropertyValues(AddInInformation, Result);
		
		Id = Result.Id;
		Version        = Result.Version;
	Else
		AddInInformation = Undefined;
		Common.MessageToUser(Result.ErrorDescription);
	EndIf;
	
	GenerateInformationPresentation();
	
EndProcedure

#EndRegion


