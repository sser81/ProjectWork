///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2019, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
			
	If Not Users.IsFullUser() Then
		ErrorText =  NStr("en = 'Insufficient rights to end the session';");
		GoToWizardStep(5);
		Return;
	EndIf;
				
	TerminateWithoutWarning = Constants.CloseSessionsWithoutWarningByDefaultSaaS.Get();
		
	GoToWizardStep(1);
		
EndProcedure

#EndRegion

#Region Private

//@skip-warning - EmptyMethod - Implementation feature.
&AtClient
Function CheckPasswordEntry()
	
	If IsBlankString(Password) Then	
		CommonClient.MessageToUser(
			NStr("en = 'Password to access the service is not specified';"), ,
			"Password");	
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

//@skip-warning - EmptyMethod - Implementation feature.
&AtClient
Function StartSendingAlerts()
			
	If TerminateWithoutWarning 
		Or Not SendAlertsToServer(Parameters.SessionsNumbers, MessageToUsers) Then
		GoToWizardStep(3);
		GoToNextStep();
		Return False;	
	EndIf;

	AttachIdleHandler("AfterPerformingSendingAlertsToUsers", 60, True);

	Return True;
				
EndFunction

&AtClient
Procedure AfterPerformingSendingAlertsToUsers() Export
	GoToNextStep();
EndProcedure

&AtServerNoContext
Function SendAlertsToServer(Val SessionsNumbers, Val MessageToUsers)
	
	SetPrivilegedMode(True);
	
	NotificationToTheUser = New Structure();
	NotificationToTheUser.Insert(
		"NotificationKind",
		"SessionTerminationWarning");
	
	UserDescription = Common.ObjectAttributeValue(
		Users.CurrentUser(),
		"Description");
	NotificationToTheUser.Insert("UserDescription", UserDescription);	 
	
	If ValueIsFilled(MessageToUsers) Then
		NotificationToTheUser.Insert("Message", MessageToUsers);	 
	EndIf;
	
	InteractiveApplicationNames = CommonCTL.InteractiveApplicationNames();
		
	SessionNumbersUserNames = New Map();
	For Each Session In GetInfoBaseSessions() Do
		
		If InteractiveApplicationNames.Find(Session.ApplicationName) = Undefined Then
			Continue;
		EndIf;
				
		SessionUser = Session.User;
		If SessionUser = Undefined Then
			Continue;	
		EndIf;
		
		UserName = SessionUser.Name;
		If Not ValueIsFilled(UserName) Then
			Continue;
		EndIf;
		
		SessionNumbersUserNames.Insert(Session.SessionNumber, UserName);
	
	EndDo;
	
	DataArea = SaaSOperations.SessionSeparatorValue();	
	DeliveredAlerts = New Array;	
		
	For Each SessionNumber In SessionsNumbers Do
		
		UserName = SessionNumbersUserNames.Get(SessionNumber);
		If Not ValueIsFilled(UserName) Then
			Continue
		EndIf;
		
		DeliveredNotification = New Structure();
		DeliveredNotification.Insert("DataArea", DataArea);
		DeliveredNotification.Insert("UserName", UserName);	
		DeliveredNotification.Insert("SessionNumber", SessionNumber);	
		DeliveredNotification.Insert("UserNotification", NotificationToTheUser);
		
		DeliveredAlerts.Add(DeliveredNotification);
				
	EndDo;
	
	If Not ValueIsFilled(DeliveredAlerts) Then
		Return False;
	EndIf;
		
	UsersNotificationCTL.DeliverAlerts(DeliveredAlerts);
	
	Return True;
	
EndFunction

//@skip-warning - EmptyMethod - Implementation feature.
&AtClient
Function StartTerminatingSessions()
							
	TimeConsumingOperation = RunSessionTerminationOnServer(
		Parameters.SessionsNumbers,
		Password,
		MessageToUsers);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	NotificationOnCompletion = New NotifyDescription("AfterCompletingSessions", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, NotificationOnCompletion, IdleParameters);

	Return True;
	
EndFunction

&AtServerNoContext
Function RunSessionTerminationOnServer(Val SessionsNumbers, Val Password, Val MessageFromUser)
	
	PartsOfMessageTextToUsers = New Array();
	
	UserDescription = Common.ObjectAttributeValue(
		Users.CurrentUser(),
		"Description");
	PartsOfMessageTextToUsers.Add(StrTemplate(NStr("en = 'Session is closed
		|User that closed the session: %1';"),
		UserDescription));
		 
	If ValueIsFilled(MessageFromUser) Then
		PartsOfMessageTextToUsers.Add(StrTemplate(NStr("en = 'Message from a user: %1';"), MessageFromUser));
	EndIf;	
	MessageToUsers = StrConcat(PartsOfMessageTextToUsers, Chars.LF); 
		
	ExecutionParameters = TimeConsumingOperations.ProcedureExecutionParameters();
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Close sessions';");

	Return TimeConsumingOperations.ExecuteProcedure(
		ExecutionParameters,
		"RemoteAdministrationCTLInternal.EndDataAreaSessions",
		SessionsNumbers,
		Password,
		MessageToUsers);
		
EndFunction

&AtClient
Procedure AfterCompletingSessions(Result, AdditionalParameters) Export
		
	If Result <> Undefined And Result.Status = "Completed2" Then
		
		Close(DialogReturnCode.OK);
	
	Else
		
		If Result = Undefined Then
			ErrorPresentation = NStr("en = 'Job is canceled';");
		Else
			ErrorPresentation = Result.DetailErrorDescription;
		EndIf;
		
		WriteError(
			NStr("en = 'An error occurred when closing the session';", CommonClient.DefaultLanguageCode()),
			ErrorPresentation);
		
		ErrorText = NStr("en = 'An error occurred when closing the sessions.
		|Check whether the password to access the service is correct, try again later, or contact the technical support of the service';");
		
		GoToWizardStep(5);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure WriteError(EventName, ErrorText)
	// @skip-check module-nstr-camelcase - Check error
	FullNameOfEvent = NStr("en = 'SessionsTerminationSaaS';", Common.DefaultLanguageCode()) + "." + EventName;
	WriteLogEvent(FullNameOfEvent, EventLogLevel.Error,,, ErrorText);
EndProcedure

&AtClient
Procedure Next(Command)
	
	GoToNextStep();
	
EndProcedure

&AtClient
Function ExecuteTransitionHandlerBetweenSteps()
	
	Result = True;
	
	If ValueIsFilled(TransitionFromCurrentStepHandler) Then
		
		Result = Eval(TransitionFromCurrentStepHandler + "()");
				
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure GoToWizardStep(Val Step)
	
	Scenario = WizardScript();
	
	StepDescription = Scenario.Find(Step, "StepNumber");
	Items.GroupPages.CurrentPage = Items[StepDescription.Page];
	Items.CommandsPagesGroup.CurrentPage = Items[StepDescription.CommandsPage];
	
	TransitionFromCurrentStepHandler = StepDescription.Handler;
	CurrentStep = Step;
	
EndProcedure

&AtServer
Function WizardScript()
	
	Result = New ValueTable();
	
	Result.Columns.Add("StepNumber", New TypeDescription("Number"));
	Result.Columns.Add("Page", New TypeDescription("String"));
	Result.Columns.Add("CommandsPage", New TypeDescription("String"));
	Result.Columns.Add("Handler", New TypeDescription("String"));
	
	// Password entry.
	NewRow = Result.Add();
	NewRow.StepNumber = 1;
	NewRow.Page = Items.PasswordInputPage.Name;
	NewRow.CommandsPage = Items.DataEntryCommandPage.Name;
	NewRow.Handler = "CheckPasswordEntry";
		
	// User notifications.
	NewRow = Result.Add();
	NewRow.StepNumber = 2;
	NewRow.Page = Items.UserAlertsPage.Name;
	NewRow.CommandsPage = Items.DataEntryCommandPage.Name;
	NewRow.Handler = "StartSendingAlerts";
	
	// Waiting for user notification.
	NewRow = Result.Add();
	NewRow.StepNumber = 3;
	NewRow.Page = Items.WaitingForUserNotificationsPage.Name;
	NewRow.CommandsPage = Items.WaitCommandPage.Name;
	NewRow.Handler = "StartTerminatingSessions";
		
	// Waiting for completion.
	NewRow = Result.Add();
	NewRow.StepNumber = 4;
	NewRow.Page = Items.WaitingForSessionsToEndPage.Name;
	NewRow.CommandsPage = Items.WaitCommandPage.Name;
	
	// View error.
	NewRow = Result.Add();
	NewRow.StepNumber = 5;
	NewRow.Page = Items.ErrorPage.Name;
	NewRow.CommandsPage = Items.ErrorCommandPage.Name;
	
	Return Result;
	
EndFunction

&AtClient
Procedure GoToNextStep()
	
	CurStepBeforeHandlerExecution = CurrentStep;
	
	If Not ExecuteTransitionHandlerBetweenSteps() Then
		Return;
	EndIf;
	
	If CurrentStep <> CurStepBeforeHandlerExecution Then
		Return;
	EndIf;
	
	GoToWizardStep(CurrentStep + 1);

EndProcedure

#EndRegion


