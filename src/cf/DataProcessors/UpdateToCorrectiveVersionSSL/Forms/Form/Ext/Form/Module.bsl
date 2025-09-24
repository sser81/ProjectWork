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

&AtClient
Procedure OnOpen(Cancel)
	
#If WebClient Or MobileClient Then
	ShowMessageBox(, NStr("en = 'Cannot start in web client or mobile client.
		|Start thin client.';"));
	Cancel = True;
	Return;
#EndIf
	
	StartupParametersInParts = StrSplit(LaunchParameter, ";", False);
	For Each Parameter In StartupParametersInParts Do
		If StrFind(Parameter, "UpdateFile") > 0 Then
			UpdateFile  = TrimAll(StrSplit(Parameter, "=")[1]);
			UpdateFile = StrReplace(UpdateFile, """", "");
		EndIf;
	EndDo;
	
	If ValueIsFilled(UpdateFile) Then
		BinaryData = New BinaryData(UpdateFile);
		Store = PutToTempStorage(BinaryData, UUID);
		UpdateToCorrectiveVersionAtServer(Store);
		Exit(False, False);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateSettingsFile(Command)
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title  = NStr("en = 'Specify a name of the comparison or merging setting file';");
	SavingParameters.Dialog.Filter     = NStr("en = 'File of comparison or merging settings (*.xml)|*.xml';");
	SavingParameters.Dialog.DefaultExt = "xml";
	FileSystemClient.SaveFile(Undefined, GenerateSettingsFileAtServer(), "settings.xml", SavingParameters);
	
EndProcedure

&AtClient
Procedure UpdateToCorrectiveVersion(Command)
	
	Notification = New NotifyDescription("UpdateToCorrectiveVersionFollowUp", ThisObject);
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Dialog.Filter = NStr("en = '1C:Enterprise 8 infobase configuration (*.cf)|*.cf';");
	ImportParameters.Dialog.Multiselect = False;
	ImportParameters.Dialog.Title = NStr("en = 'Select file with new SSL version';");
	ImportParameters.Dialog.FullFileName = NStr("en = '1Cv8';");
	ImportParameters.Dialog.DefaultExt     = "cf";
	FileSystemClient.ImportFile_(Notification, ImportParameters);
	
EndProcedure

&AtClient
Procedure Designer1(Command)
#If Not WebClient Then
	StartupCommand = New Array;
	StartupCommand.Add(BinDir() + "1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(InfoBaseConnectionString());
	StartupCommand.Add("/N");
	StartupCommand.Add(UserName());
	
	ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = False;
	
	FileSystemClient.StartApplication(StartupCommand, ApplicationStartupParameters);
#EndIf
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GenerateSettingsFileAtServer()
	UploadFileName = GetTempFileName("xml");
	FormAttributeToValue("Object").GenerateCompareMergeSettingsFile(UploadFileName);
	BinaryData = New BinaryData(UploadFileName);
	DeleteFiles(UploadFileName);
	Return PutToTempStorage(BinaryData, UUID);
EndFunction

&AtClient
Procedure UpdateToCorrectiveVersionFollowUp(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Status(NStr("en = 'Updating to hotfix version…';"));
	WarningsOnUpdate = UpdateToCorrectiveVersionAtServer(Result.Location);
	If Not ValueIsFilled(WarningsOnUpdate) Then
		Items.WarningsOnUpdate.Visible = False;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
		ShowMessageBox(, NStr("en = 'The configuration has been successfully updated to the hotfix version, but it has not been applied to the database.
			|Follow further instructions.';"));
	Else
		Items.WarningsOnUpdate.Visible = True;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		Items.Pages.CurrentPage = Items.PageWarningsOnUpdate;
		ShowMessageBox(, NStr("en = 'The configuration has not been updated to the hotfix version.
			|Handle the warnings in Designer or select the ""Skip warnings during update"" checkbox and try again.';"));
	EndIf;
	
EndProcedure

&AtServer
Function UpdateToCorrectiveVersionAtServer(SelectedUpdateFile)
	UpdateFileName = GetTempFileName("cf");
	BinaryData = GetFromTempStorage(SelectedUpdateFile); // BinaryData
	BinaryData.Write(UpdateFileName);
	
	WarningsOnUpdate = FormAttributeToValue("Object").UpdateToCorrectiveVersion(
		UpdateFileName, SkipWarningsOnUpdate);
	
	DeleteFiles(UpdateFileName);
	
	Return WarningsOnUpdate;
	
EndFunction

#EndRegion