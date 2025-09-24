﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

// Checks for active infobase connections.
//
// Returns:
//  Boolean       - True if there are connections.
//                 False if there are no connections.
//
Function HasActiveConnections(MessagesForEventLog = Undefined) Export
	
	VerifyAccessRights("Administration", Metadata);
	EventLog.WriteEventsToEventLog(MessagesForEventLog);
	Return IBConnections.InfobaseSessionsCount(False, False) > 1;
EndFunction

Procedure WriteUpdateStatus(ParametersOfUpdate, MessagesForEventLog = Undefined) Export
	
	VerifyAccessRights("Administration", Metadata);
	
	ScriptDirectory = "";
	If Not IsBlankString(ParametersOfUpdate.MainScriptFileName) Then 
		ScriptDirectory = Left(ParametersOfUpdate.MainScriptFileName, StrLen(ParametersOfUpdate.MainScriptFileName) - 10);
	EndIf;
	ParametersOfUpdate.ScriptDirectory = ScriptDirectory;
	
	ConfigurationUpdate.WriteUpdateStatus(
		ParametersOfUpdate,
		MessagesForEventLog);
	
EndProcedure

Function TemplatesTexts(MessagesForEventLog, InteractiveMode, ExecuteDeferredHandlers, IsDeferredUpdate) Export
	
	VerifyAccessRights("Administration", Metadata);
	
	TemplatesTexts = New Structure;
	TemplatesTexts.Insert("AdditionalConfigurationUpdateFile");
	TemplatesTexts.Insert(?(InteractiveMode, "ConfigurationUpdateSplash", "NonInteractiveConfigurationUpdate"));
	
	If IsDeferredUpdate Then
		TemplatesTexts.Insert("TaskSchedulerTaskCreationScript");
	EndIf;
	
	TemplatesTexts.Insert("PatchesDeletionScript");
	
	For Each TemplateProperties In TemplatesTexts Do
		TemplatesTexts[TemplateProperties.Key] = DataProcessors.InstallUpdates.GetTemplate(TemplateProperties.Key).GetText();
	EndDo;
	
	If InteractiveMode Then
		TemplatesTexts.ConfigurationUpdateSplash = GenerateSplashText(TemplatesTexts.ConfigurationUpdateSplash); 
	EndIf;
	
	// Configuration update file: main.js.
	ScriptTemplate = DataProcessors.InstallUpdates.GetTemplate("ConfigurationUpdateFileTemplate");
	
	ParametersArea = ScriptTemplate.GetArea("ParametersArea");
	ParametersArea.DeleteLine(1);
	ParametersArea.DeleteLine(ParametersArea.LineCount());
	If StrStartsWith(ParametersArea.GetLine(ParametersArea.LineCount()), "#") Then
		ParametersArea.DeleteLine(ParametersArea.LineCount());
	EndIf;
	TemplatesTexts.Insert("ParametersArea", ParametersArea.GetText());
	
	ConfigurationUpdateArea = ScriptTemplate.GetArea("ConfigurationUpdateArea");
	ConfigurationUpdateArea.DeleteLine(1);
	ConfigurationUpdateArea.DeleteLine(ConfigurationUpdateArea.LineCount());
	TemplatesTexts.Insert("ConfigurationUpdateFileTemplate", ConfigurationUpdateArea.GetText());
	
	// Writing accumulated events to the event log.
	EventLog.WriteEventsToEventLog(MessagesForEventLog);
	ExecuteDeferredHandlers = ConfigurationUpdate.ExecuteDeferredHandlers();
	
	ScriptMessages = ScriptMessages();
	For Each TemplateProperties In TemplatesTexts Do
		TemplatesTexts[TemplateProperties.Key] = SubstituteParametersToText(TemplatesTexts[TemplateProperties.Key], ScriptMessages);
	EndDo;
	
	Return TemplatesTexts;
	
EndFunction

Function GenerateSplashText(Val TextTemplate1)
	
	TextParameters = New Map;
	TextParameters["[SplashTitle]"] = NStr("en = 'Updating 1C:Enterprise configuration…';");
	TextParameters["[SplashText]"] = NStr("en = 'Please wait.
		|<br/> Application update is in progress.';");
	
	TextParameters["[Step1Initialization]"] = NStr("en = 'Initializing';");
	TextParameters["[Step2ClosingUserSessions]"] = NStr("en = 'Closing user sessions';");
	TextParameters["[Step3BackupCreation]"] = NStr("en = 'Creating infobase backup';");
	TextParameters["[Step4ConfigurationUpdate]"] = NStr("en = 'Updating infobase configuration';");
	TextParameters["[Step4DownloadExtensions]"] = NStr("en = 'Updating infobase extensions';");
	TextParameters["[Step5IBUpdate]"] = NStr("en = 'Running update handlers';");
	TextParameters["[Step6DeferredUpdate]"] = NStr("en = 'Running deferred update handlers';");
	TextParameters["[Step7CompressTables]"] = NStr("en = 'Compressing infobase tables';");
	TextParameters["[Step8AllowConnections]"] = NStr("en = 'Granting permission for new connections';");
	TextParameters["[Step9Completion]"] = NStr("en = 'Completing';");
	TextParameters["[Step10Recovery]"] = NStr("en = 'Restoring infobase';");
	TextParameters["[Step11PatchesDeletion]"] = NStr("en = 'Deleting patches';");
	
	TextParameters["[Step41Load]"] = NStr("en = 'Loading update file to the main infobase';");
	TextParameters["[Step42ConfigurationUpdate]"] = NStr("en = 'Updating infobase configuration';");
	TextParameters["[Step43IBUpdate]"] = NStr("en = 'Running update handlers';");
	
	TextParameters["[ProcessIsAborted]"] = NStr("en = 'Warning! The update was terminated and the infobase remains locked.';");
	TextParameters["[AbortedTooltip]"] = NStr("en = 'To unlock the infobase, use the server cluster console or run 1C:Enterprise.';");
	
	TextParameters["[ProductName]"] = NStr("en = '1C:ENTERPRISE 8.3';");
	TextParameters["[Copyright]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = '© 1C Company, 1996-%1';"), Format(Year(CurrentSessionDate()), "NG=0"));
	
	Return SubstituteParametersToText(TextTemplate1, TextParameters);
	
EndFunction

Function SubstituteParametersToText(Val Text, Val TextParameters)
	
	Result = Text;
	For Each TextParameter In TextParameters Do
		Result = StrReplace(Result, TextParameter.Key, TextParameter.Value);
	EndDo;
	Return Result; 
	
EndFunction

Procedure SaveConfigurationUpdateSettings(Settings) Export
	VerifyAccessRights("Administration", Metadata);
	ConfigurationUpdate.SaveConfigurationUpdateSettings(Settings);
EndProcedure

Procedure UpdatePatchesFromScript(NewPatches, PatchesToDelete) Export // ACC:557 To call from a script.
	ConfigurationUpdate.UpdatePatchesFromScript(NewPatches, PatchesToDelete);
EndProcedure

Function ScriptDirectory() Export
	
	Return ConfigurationUpdate.ScriptDirectory();
	
EndFunction

// ACC:299–off for using from the update script.
// ACC:557–off for using from the update script.
//
Procedure DeletePatchesFromScript() Export
	
	MessageText = NStr("en = 'Starting patch clean up followed by application update.';");
	WriteLogEvent(ConfigurationUpdate.EventLogEvent(), EventLogLevel.Information,,, MessageText);
	
	AllExtensions = ConfigurationExtensions.Get();
	For Each Extension In AllExtensions Do
		If Not ConfigurationUpdate.IsPatch(Extension) Then
			Continue;
		EndIf;
		Try
			Extension.Delete();
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot delete patch ""%1."" Reason:
				           |
				           |%2';"), Extension.Name, ErrorProcessing.BriefErrorDescription(ErrorInfo));
			WriteLogEvent(NStr("en = 'Patch.Delete';", Common.DefaultLanguageCode())
				, EventLogLevel.Error,,, ErrorText);
		EndTry;
	EndDo;
	
	MessageText = NStr("en = 'Patch deletion completed.';");
	WriteLogEvent(ConfigurationUpdate.EventLogEvent(), EventLogLevel.Information,,, MessageText);
	
EndProcedure
// ACC:299-on
// ACC:557-on

Function ScriptMessages()
	
	Messages = New Map;
		
	// Messages in templates ConfigurationUpdateFileTemplate, NonInteractiveConfigurationUpdate, and ConfigurationUpdateSplash.
	Messages["[TheStartOfStartupMessage]"] = NStr("en = 'Starting: {0}; parameters: {1}; window: {2}; waiting: {3}';");
	Messages["[ExceptionDetailsMessage]"] = NStr("en = 'Exception at the application start: {0}, {1}';");
	Messages["[MessageLaunchResult]"] = NStr("en = 'Return code: {0}';");
	Messages["[TheMessageIsThePathToTheScriptFile]"] = NStr("en = 'Script file: {0}';");
	Messages["[UpdateFileCounterMessage]"] = NStr("en = 'Number of update files: {0}';");
	Messages["[TheMessageRestoringTheDatabase]"] = NStr("en = 'Restore infobase from a temporary archive';");
	Messages["[TheMessageTheBeginningOfTheConnectionSessionWithTheDatabase]"] = NStr("en = 'External infobase connection session started';");
	Messages["[MessageDeletingASchedulerTask]"] = NStr("en = 'Deleting a scheduler task: {0}';");
	Messages["[TheSchedulerTaskDeletionFailureMessage]"] = NStr("en = 'Cannot delete the task from the task scheduler due to: {0}';");
	Messages["[TheMessageConnectionFailureWithTheDatabase]"] = NStr("en = 'Exception when creating COM connection: {0}, {1}';");
	Messages["[TheMessageIsACallToCompleteTheUpdate]"] = "ConfigurationUpdate.CompleteUpdate" + "({0}, {1}, {2})";
	Messages["[FailureMessageWhenCallingToCompleteTheUpdate]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Exception when calling %1: {0}, {1}';"), "ConfigurationUpdate.CompleteUpdate");
	Messages["[TheMessageDatabaseUpdateResult]"] = NStr("en = 'The infobase is updated.';");
	Messages["[DatabaseUpdateFailureMessage]"] = NStr("en = 'An unexpected error occurred while updating the infobase';");
	Messages["[TheMessageDatabaseParameters]"] = NStr("en = 'Infobase parameters: {0}.';");
	Messages["[LoggingFailureMessage]"] = NStr("en = 'Exception when writing Event log: {0}, {1}';");
	Messages["[MessageUpdateLogging1S]"] = NStr("en = 'The update protocol is saved to the event log.';");
	Messages["[TheMessageCopyingTheDatabase]"] = NStr("en = '\r\n\Copying from:\r\n\{0}\r\n\ to:\r\n\{1}';");
	Messages["[TheMessageDatabaseFileDoesNotExist]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = '%1 database file does not exist by path: {0}';"), "1Cv8.1CD");
	Messages["[TheMessageDatabaseBackupDirectoryDoesNotExist]"] = NStr("en = 'There is no folder to save the backup: {0}';");
	Messages["[MessageBackupFileParameters]"] = NStr("en = '\r\n\The backup file already exists: {0}\r\n\Created: {1}\r\n\Last accessed: {2}\r\n\Last modified: {3}\r\n\Size: {4}\r\n\Type: {5}\r\n\Attributes:\r\n\{6}';");
	Messages["[TheMessageDiskDoesNotExist]"] = NStr("en = '\r\n\Hard drive is not found at {0}\r\n\Exception: {1}, {2}';");
	Messages["[TheMessageDiskIsUnavailable]"] = NStr("en = 'Hard drive is unavailable at {0}';");
	Messages["[MessageEnoughDiskSpace]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Space available on drive {0}: {1} Mb\r\n\%1 file size: {2} Mb\r\n\Drive type: {3}';"), "1Cv8.1CD");
	Messages["[MessageDiskSpaceIsInsufficient]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = '\r\n\There is not enough free space to create a backup.\r\n\Free up some space or specify a folder on a different hard drive.\r\n\Required: {0} Mb\r\n\Space available on drive {1}: {2} Mb\r\n\%1 File size: {3} Mb\r\n\Drive type: {4}';"), "1Cv8.1CD");
	Messages["[TheMessageIsTheResultOfCreatingABackupCopyOfTheDatabase]"] = NStr("en = 'Infobase is backed up';");
	Messages["[TheMessageFailureToCreateABackupCopyOfTheDatabaseInDetail]"] = NStr("en = 'Exception when backing up the infobase: {0}, {1}';");
	Messages["[TheMessageDatabaseRecoveryResult]"] = NStr("en = 'Database is restored from the backup';");
	Messages["[TheMessageDatabaseRecoveryFailureInDetail]"] = NStr("en = 'Exception when restoring an infobase from a backup: {0}, {1}.';");
	Messages["[TheMessageChallengeAllowUsersToWork]"] = "IBConnections.AllowUserAuthorization";
	Messages["[MessageCallRefusalToAllowUsersToWork]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Exception when calling %1: {0}, {1}';"), "IBConnections.AllowUserAuthorization");
	Messages["[TheErrorMessageUpdatesFixes]"] = NStr("en = 'Cannot update the configuration patches. For more information, see the previous record.';");
	Messages["[CallFailureMessageUpdateFixesFromScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Exception when calling %1: {0}, {1}';"), "ConfigurationUpdateServerCall.UpdatePatchesFromScript");
	Messages["[MessageCallToUpdateTheInformationBase]"] = "InfobaseUpdateServerCall.UpdateInfobase" + "({0})";
	Messages["[MessageCallFailureToUpdateTheInformationBase]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Exception when calling %1: {0}, {1}.';"), "InfobaseUpdateServerCall.UpdateInfobase");
	Messages["[TheMessageDatabaseUpdateFailureIsGeneral]"] = NStr("en = 'Cannot update the infobase due to:';");
	Messages["[TheMessageBlockingTheDatabase]"] = NStr("en = 'because configuration update is pending';");
	Messages["[UserShutdownFailureMessage]"] = NStr("en = 'An attempt to close user sessions is unsuccessful. Infobase lock is canceled.';");
	Messages["[TheMessageCancelingTheBlockingOfUsersWork]"] = NStr("en = 'Exception when closing user sessions: {0}, {1}';");
	Messages["[MessageEndOfDatabaseConnectionSession]"] = NStr("en = 'External infobase connection session completed';");
	Messages["[TheMessageBlockingTheWorkOfUsersLogging]"] = NStr("en = 'Lock sessions because configuration update is pending';");
	Messages["[TheMessageBlockingTheWorkOfUsers]"] = NStr("en = 'because configuration update is pending';");
	Messages["[MessageDatabaseSessionCounter]"] = NStr("en = 'Number of infobase sessions: {0}';");
	Messages["[TheMessageIsTheResultOfBlockingSessions]"] = NStr("en = 'Session start lock is set: {0}';");
	Messages["[TheMessageTheCounterOfTheHungSessionsOfTheDatabase]"] = NStr("en = 'Number of hung infobase sessions: {0}, attempt #{1}';");
	Messages["[TheMessageIsACallToPerformADeferredUpdateNow]"] = "InfobaseUpdateInternal.ExecuteDeferredUpdateNow" + "()";
	Messages["[MessageCallFailureToPerformADelayedUpdateNow]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Exception when calling %1: {0}, {1}.';"), "InfobaseUpdateInternal.ExecuteDeferredUpdateNow");
	Messages["[CallFailureMessageRemoveFixesFromScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Exception when calling %1: {0}, {1}.';"), "ConfigurationUpdateServerCall.DeletePatchesFromScript");
	Messages["[TheMessageFailureToDeleteFixes]"] = NStr("en = 'Cannot delete the configuration patches. For more information, see the previous record.';");
	Messages["[MessageCOMConnectorParameters]"] = NStr("en = 'COM connection is used: {0}';");
	Messages["[TheMessageDatabaseUpdateFailureFromTheFile]"] = NStr("en = 'Cannot update by file. The configuration may not be supported. Attempting to load configuration.';");
	Messages["[SplashScreenMessageStepError]"] = NStr("en = 'An error occurred. Error code: {0}. For more information, see the previous record.';");
	Messages["[MessageInitialization]"] = NStr("en = 'Initializing';");
	Messages["[TheUserShutdownMessage]"] = NStr("en = 'Closing user sessions';");
	Messages["[TheMessageCreatingABackupCopyOfTheDatabase]"] = NStr("en = 'Creating infobase backup';");
	Messages["[MessageExecutingDeferredUpdateHandlers]"] = NStr("en = 'Running deferred update handlers';");
	Messages["[ConfigurationUpdateMessage]"] = NStr("en = 'Updating infobase configuration';");
	Messages["[MessageLoadingExtensions]"] = NStr("en = 'Infobase extension update';");
	Messages["[UpdateFileDownloadMessage]"] = NStr("en = 'Loading update file to the main infobase ({0}/{1})';");
	Messages["[MessageConfigurationUpdateParameters]"] = NStr("en = 'Updating infobase configuration ({0}/{1})';");
	Messages["[MessageExecutingUpdateHandlers]"] = NStr("en = 'Running update handlers ({0}/{1})';");
	Messages["[TheConnectionPermissionMessage]"] = NStr("en = 'Allowing new connections';");
	Messages["[UpdateCompletionMessage]"] = NStr("en = 'Completing';");
	
	// Messages in template PatchesDeletionScript.
	Messages["[InitializationFailureMessage]"] = NStr("en = 'Variables are not initialized';");
	Messages["[MessageCreatingACOMConnectorObject]"] = NStr("en = 'Creating a COM connector object…';");
	Messages["[MessageFailureToCreateACOMConnectorObject]"] = NStr("en = 'Cannot create a COM connector object:';");
	Messages["[TheMessageEstablishingAConnectionToTheDatabase]"] = NStr("en = 'Connecting with';");
	Messages["[TheMessageConnectionFailureWithTheDatabaseIsGeneral]"] = NStr("en = 'Cannot connect to';");
	Messages["[MessageMainEvent]"] = NStr("en = 'Deleting patches';");
	Messages["[TheMessageIsACallToRemoveFixesFromTheScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Calling %1…';"), "ConfigurationUpdateServerCall.DeletePatchesFromScript");
	Messages["[TheMessageIsACallToUpdateTheFixesFromTheScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Calling %1…';"), "ConfigurationUpdateServerCall.UpdatePatchesFromScript");
	Messages["[ErrorMessage_]"] = NStr("en = ': Configuration error:';") + Chars.NBSp;
	Messages["[MessageImportance]"] = NStr("en = 'Required';");
	
	Return Messages;
	
EndFunction

Function VersionsRequiringSuccessfulUpdate(FilesOfUpdate) Export
	
	Table = New ValueTable;
	Table.Columns.Add("Version");
	Table.Columns.Add("VersionWeight");
	Table.Columns.Add("Required");
	
	If FilesOfUpdate.Count() < 2 Then
		Return New Array;
	EndIf;
	
	For Each InformationRecords In FilesOfUpdate Do
		UpdateDetails1 = New ConfigurationUpdateDescription(InformationRecords.BinaryData);
		
		String = Table.Add();
		String.Version       = UpdateDetails1.TargetConfiguration.Version;
		String.VersionWeight    = VersionWeight(String.Version);
		String.Required = InformationRecords.Required;
	EndDo;
	
	Versions = New Array;
	Table.Sort("VersionWeight Asc");
	LastRow = Table[Table.Count() - 1];
	For Each TableRow In Table Do
		If Not TableRow.Required Then
			Continue;
		EndIf;
		
		If TableRow = LastRow Then
			Continue; // Ignore the latest version.
		EndIf;
		
		Versions.Add(TableRow.Version);
	EndDo;
	
	Return Versions;
	
EndFunction

Function VersionWeight(Version)
	
	VersionByParts = StrSplit(Version, ".");
	
	Return 0
		+ Number(VersionByParts[0]) * 1000000000000
		+ Number(VersionByParts[1]) * 100000000
		+ Number(VersionByParts[2]) * 10000
		+ Number(VersionByParts[3]);
	
EndFunction

Function ParametersOfUpdate() Export
	
	ParametersOfUpdate = New Structure;
	ParametersOfUpdate.Insert("UpdateAdministratorName", Undefined);
	ParametersOfUpdate.Insert("UpdateScheduled", False);
	ParametersOfUpdate.Insert("UpdateComplete", False);
	ParametersOfUpdate.Insert("ConfigurationUpdateResult", Undefined);
	ParametersOfUpdate.Insert("ScriptDirectory", "");
	ParametersOfUpdate.Insert("MainScriptFileName", "");
	ParametersOfUpdate.Insert("PatchInstallationResult", Undefined);
	ParametersOfUpdate.Insert("VersionsRequiringSuccessfulUpdate", Undefined);
	
	Return ParametersOfUpdate;
	
EndFunction

#EndRegion
