﻿#Region Variables

&AtClient
Var SessionID;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping initialization to ensure getting the form when passing the Autotest parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Certificate = Parameters.Certificate;
	
	If Not ValueIsFilled(Certificate) Then
		Cancel = True;
		Return;
	EndIf;
	
	PasswordsDeliveryMethod = "phone";
	
	ProcedureParameters = New Structure("CertificateID", CryptographyServiceInternal.Id(Certificate));
	
	TimeConsumingOperation = CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetSettingsForGettingTemporaryPasswords", ProcedureParameters);
	
	PasswordBeingSent = True;
	Items.FormOtherMethod.Visible = False;	
	Phone = "...";
	
	NewTitle 		= "";
	NewDetails 		= "";
	OperationParametersList 	= Undefined;
	Parameters.Property("OperationParametersList", OperationParametersList);
	
	If TypeOf(OperationParametersList) = Type("Structure") Then
		OperationParametersList.Property("Operation", NewTitle);
		OperationParametersList.Property("DataTitle", NewDetails);
	EndIf;
	
	If ValueIsFilled(NewTitle) Then
		Title = NewTitle;
	EndIf;
	
	If ValueIsFilled(NewDetails) Then
		Items.DetailsDecoration.Title = NewDetails;
	Else
		Items.DetailsDecoration.Visible = False;
	EndIf;
	
	Items.TimeConsumingOperationIndicator.Picture = GetLibraryImage("TimeConsumingOperation16");
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SessionID = Undefined;
	Notification = New NotifyDescription("GetSettingsForGettingTemporaryPasswordsAfterExecution", ThisObject);
	CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, TimeConsumingOperation);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DigitEditTextChange(Item, Text, StandardProcessing)
	
	StandardProcessing 	= True;
	
	If StrLen(Text) = 6 Then
		FinalNumber = TrimAll(Text);
		Digits = "";
		Items.Digits.UpdateEditText();
		CheckEnteredCode(FinalNumber);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OtherMethod(Command)
	
	If PasswordsDeliveryMethod = "phone" Then
		PasswordsDeliveryMethod = "email";
	Else
		PasswordsDeliveryMethod = "phone";
	EndIf;
	
	SessionID = "";
	ResendPassword(False);
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure Settings(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Certificate", Certificate);
	FormParameters.Insert("State", "ChangingSettingsForGettingTemporaryPasswords");
	
	CloseOpen(FormParameters);
	
EndProcedure

&AtClient
Procedure SendAgain(Command)

	ResendPassword();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ResendPassword(Resending = True)

	Notification = New NotifyDescription("GetTemporaryPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, GetPasswordOnServer(Resending, SessionID));
		
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure GetSettingsForGettingTemporaryPasswordsAfterExecution(Result, IncomingContext) Export
	
	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		Phone          = Result.ExecutionResult.Phone;
		Email = Result.ExecutionResult.Email;
		
		Notification = New NotifyDescription("GetTemporaryPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, GetPasswordOnServer());
		FormControl(ThisObject);
		
	Else
		Notification = New NotifyDescription("AfterDisplayingWarning", ThisObject);
		ShowMessageBox(Notification, NStr("en = 'SMS service is temporarily unavailable. Try again later.';"));		
	EndIf;
	
EndProcedure

&AtServer
Function GetPasswordOnServer(Repeatedly = False, SessionID = Undefined)
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CertificateID", CryptographyServiceInternal.Id(Certificate));
	ProcedureParameters.Insert("Resending", Repeatedly);
	ProcedureParameters.Insert("Type", PasswordsDeliveryMethod);
	ProcedureParameters.Insert("SessionID", SessionID);
	
	Return CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetTemporaryPassword", ProcedureParameters);
	
EndFunction

&AtClient
Procedure GetTemporaryPasswordAfterExecution(Result, IncomingContext) Export
	
	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		Timer = Result.ExecutionResult.DelayBeforeResending;
		PasswordSent = True;
		PasswordBeingSent = False;
		If Result.ExecutionResult.Property("SessionID") Then 
			SessionID = Result.ExecutionResult.SessionID;
		EndIf;
		StartCountdown();
		FormControl(ThisObject);
		CurrentItem = Items.Digits;
		#If MobileAppClient Then
			BeginEditingItem();
		#EndIf	
	Else
		Notification = New NotifyDescription("AfterDisplayingWarning", ThisObject);
		ShowMessageBox(Notification, NStr("en = 'SMS service is temporarily unavailable. Try again later.';"));
	EndIf;
	
EndProcedure

&AtClient
Procedure StartCountdown()
	
	AttachIdleHandler("Attachable_HandlerCountdown", 1, True);
	
EndProcedure

&AtClient
Procedure Attachable_HandlerCountdown()
	
	Timer 		= Timer - 1;
	Delay1	= Max(Delay1 - 1, 0);

	If Timer >= 0 Then
		If Delay1 = 0 Then
			ErrorState = StrTemplate(NStr("en = 'Retry in %1 sec.';"), Timer);
		EndIf;	
		AttachIdleHandler("Attachable_HandlerCountdown", 1, True);		
	Else
		ErrorState = "";
		PasswordSent = False;		
		Items.FormOtherMethod.Visible = ValueIsFilled(Email);
		Items.FormSettings.Title = NStr("en = 'Change address';");
		
		FormControl(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseOpen(FormParameters)
	
	If IsOpen() Then 
		Close(FormParameters);
	EndIf;
	
EndProcedure

&AtServer
Function ConfirmOnServer(CurrentCode, SessionID = Undefined)
	
	PasswordBeingChecked = True;

	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CertificateID", CryptographyServiceInternal.Id(Certificate));
	ProcedureParameters.Insert("TemporaryPassword", CurrentCode);
	ProcedureParameters.Insert("SessionID", SessionID);
	
	Return CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetSessionKey", ProcedureParameters);
	
EndFunction

&AtClient
Procedure AfterDisplayingWarning(IncomingContext) Export
	
	CloseOpen(Undefined);
	
EndProcedure

&AtClient
Procedure CheckEnteredCode(CurrentCode)
	
	ErrorState = "";
	If ValueIsFilled(CurrentCode) And StrLen(CurrentCode) = 6 Then
		Notification = New NotifyDescription("ConfirmPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, ConfirmOnServer(CurrentCode, SessionID));
		FormControl(ThisObject);
	ElsIf ValueIsFilled(CurrentCode) And StrLen(CurrentCode) <> 6 Then
		ErrorState = NStr("en = '6-digit password';");
		Delay1		= 10;
	Else
		ErrorState = NStr("en = 'Password is not specified';");
		Delay1		= 10;
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfirmPasswordAfterExecution(Result, IncomingContext) Export

	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		SaveSecurityTokens(Result.ExecutionResult);
		CloseOpen(New Structure("State", "PasswordAccepted"));
	Else
		PasswordBeingChecked = False;
		FormControl(ThisObject);
		
		ExceptionText = ErrorProcessing.DetailErrorDescription(Result.ErrorInfo);
		If StrFind(ExceptionText, "PasswordIsIncorrect") Then
			ErrorState = NStr("en = 'Password is incorrect';");
			Delay1		= 10;
			CurrentItem = Items.Digits;
			#If MobileAppClient Then
				BeginEditingItem();
			#EndIf	
		ElsIf StrFind(ExceptionText, "ExceededNumberOfAttemptsToEnterPassword") Then
			CloseOpen(New Structure("State, ErrorDescription", "PasswordNotAccepted", NStr("en = 'Exceeded number of attempts to enter password';"))); 
		ElsIf StrFind(ExceptionText, "PasswordExpired") Then
			CloseOpen(New Structure("State, ErrorDescription", "PasswordNotAccepted", NStr("en = 'Password expired';")));
		Else 
			CloseOpen(New Structure("State, ErrorDescription", "PasswordNotAccepted", NStr("en = 'Operation temporarily cannot be executed';")));
		EndIf;		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SaveSecurityTokens(Val SecurityTokens)
	
	SetPrivilegedMode(True);
	CryptographyServiceInternal.SaveSecurityTokens(SecurityTokens);
	SetPrivilegedMode(False);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items = Form.Items;
	
	Items.SendAgain.Enabled = Not Form.PasswordSent And Not Form.PasswordBeingSent;
	
	CommandText 	= NStr("en = 'Send password to %1';");
	SubjectOfSubmission	= "";
	If Form.PasswordsDeliveryMethod = "phone" Then
		If Form.PasswordBeingSent Then
			SubjectOfSubmission = NStr("en = 'Sending SMS message with password to the number';");
		Else
			SubjectOfSubmission = NStr("en = 'SMS message with password is sent to the number';");
		EndIf;
		Items.FormSettings.Title = NStr("en = 'Change number';");
		Items.FormOtherMethod.Title = StrTemplate(CommandText, Form.Email);
		SubjectOfSubmission = SubjectOfSubmission + Chars.LF + Form.Phone;
	ElsIf Form.PasswordsDeliveryMethod = "email" Then
		If Form.PasswordBeingSent Then
			SubjectOfSubmission = NStr("en = 'Sending password to email:';");
		Else
			SubjectOfSubmission = NStr("en = 'Password is sent to email:';");
		EndIf;	
		Items.FormSettings.Title = NStr("en = 'Change address';");
		Items.FormOtherMethod.Title = StrTemplate(CommandText, Form.Phone);
		SubjectOfSubmission = SubjectOfSubmission + Chars.LF + Form.Email;
	EndIf;
	
	Form.CurrentStatus = SubjectOfSubmission;
	Items.TimeConsumingOperationIndicator.Visible = Form.PasswordBeingSent Or Form.PasswordBeingChecked;
	Items.CodeGroup.Enabled = Not Form.PasswordBeingSent And Not Form.PasswordBeingChecked;		
	Items.CommandGroup.Enabled = Not Form.PasswordBeingSent And Not Form.PasswordBeingChecked;
		
EndProcedure

&AtServerNoContext
Function GetLibraryImage(IconName)
	
	If Metadata.CommonPictures.Find(IconName) <> Undefined Then
		Result = PictureLib[IconName];
	Else
		Result = New Picture;
	EndIf;	
	
	Return Result;
	
EndFunction

#EndRegion
