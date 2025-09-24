﻿#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	NewPhone = Parameters.NewPhone;
	Certificate = Parameters.Certificate;
		
	ApplicationID = String(New UUID);
	
	FillInVariablesForPhoneVerification(ThisObject);
	If Parameters.Property("CheckID") Then
		ConfirmPhoneNumberForPasswords.CheckID = Parameters.CheckID;
		ConfirmPhoneNumberForPasswords.ConfirmationCompleted = ValueIsFilled(ConfirmPhoneNumberForPasswords.CheckID);
		ConfirmPhoneNumberForPasswords.ValueEntered = ValueIsFilled(ConfirmPhoneNumberForPasswords.CheckID);
	EndIf;

	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.NewPhone.UpdateEditText();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NewPhoneOnChange(Item)
	
	NewPhoneEditTextChange(Item, Item.EditText, True);
	
EndProcedure

&AtClient
Procedure NewPhoneEditTextChange(Item, Text, StandardProcessing)
	
	Presentation = DigitalSignatureSaaSClientServer.GetPhonePresentation(Text);
	NewPhone = Presentation;
	
	ConfirmPhoneNumberForPasswords.ValueEntered = ValueIsFilled(Presentation);
	If Not ValueIsFilled(Presentation) Then
		NewPhone = Text;
	EndIf;
	
	DetachIdleHandler("Attachable_HandlerCountdown");
	DetachIdleHandler("Attachable_UpdateNewPhone");
	AttachIdleHandler("Attachable_UpdateNewPhone", 1, True);
	
EndProcedure

&AtClient
Procedure ConfirmationCodeOnChange(Item)
	
	ConfirmationCodeEditTextChange(Item, Item.EditText, True);
	
EndProcedure

&AtClient
Procedure ConfirmationCodeEditTextChange(Item, Text, StandardProcessing)
	
	If StrLen(TrimAll(Text)) = 6 Then
		ConfirmationCode = TrimAll(Text);
		AttachIdleHandler("Attachable_CheckConfirmationCode", 0.5, True); 
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConfirmPhoneNumber(Command)
	
	SendConfirmationCode();

EndProcedure

&AtClient
Procedure CancelPhoneNumberConfirmationClick(Item)
	
	ConfirmPhoneNumberForPasswords = ConfirmPhoneNumberForPasswords(False, False, "", False, False);
	NewPhone = Undefined;
	Timer = 0;
	DetachIdleHandler("Attachable_HandlerCountdown");
	AttachIdleHandler("Attachable_UpdateTextOfNewPhoneField", 0.1, True);
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure ResendCode(Command)
	
	SendConfirmationCode();
	
EndProcedure

&AtClient
Procedure Step1LabelURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;	
	If Var_URL = "#PrintStatement" And VerifyPhoneVerification() Then
		Result = GetTabularDocumentOnServer(
			ApplicationID, ConfirmPhoneNumberForPasswords.CheckID, 
			CryptographyServiceInternalClient.Id(Certificate));
		If Result.Completed2 Then
			ApplicationIsPrinted = True;
			PrintFormID = "ApplicationForChangeOfPhoneNumber";
			PrintFormName = NStr("en = 'Application for changing the cell phone number';");
			
			If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
				ModuleNamePrintManagementClient = "PrintManagementClient"; 
				ModulePrintManagerClient = CommonClient.CommonModule(ModuleNamePrintManagementClient);
				
				PrintFormsCollection = ModulePrintManagerClient.NewPrintFormsCollection(PrintFormID);
				PrintForm = ModulePrintManagerClient.PrintFormDetails(PrintFormsCollection, PrintFormID);
				PrintForm.TemplateSynonym = PrintFormName;
				PrintForm.SpreadsheetDocument = Result.File;
				PrintForm.PrintFormFileName = PrintFormName;
				
				ObjectsAreas = New ValueList;
				ModulePrintManagerClient.PrintDocuments(PrintFormsCollection, ObjectsAreas);
			Else
				Result.File.Show(PrintFormName);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationFileClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not VerifyPhoneVerification() Then
		Return;
	EndIf;
	
	Notification = New NotifyDescription("FileStatementClickingAfterPlacingFile", ThisObject);
	BeginPutFile(Notification,,, True, UUID);
	
EndProcedure

&AtClient
Procedure FileStatementClickingAfterPlacingFile(Result, Address, SelectedFileName, IncomingContext) Export
	
	If Result Then
		File = New File(SelectedFileName);
		ApplicationFile = File.Name;
		ApplicationFilePath = Address;
	EndIf;
	
EndProcedure

&AtClient
Procedure SendApplication(Command)
	
	If Not VerifyPhoneVerification() Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ApplicationFilePath) Then
		MessageText = NStr("en = 'Select application file';");
		CommonClient.MessageToUser(MessageText,, "ApplicationFile");
		Return;
	EndIf;
	
	TheNotificationIsAsFollows = New NotifyDescription("UserSelectionResult", ThisObject);
	ListOfCommands = New ValueList;
	ListOfCommands.Add(SendApplicationCommand(), NStr("en = 'Send application';"), True);
	ListOfCommands.Add(CancelCommand(),  NStr("en = 'Cancel';"));
	
	QueryText = StringFunctionsClient.FormattedString(
		NStr("en = 'Note that the attached scanned document must be certified with:
			|1. Seal of your company and signature of the certificate owner.
			|2. Seal of the service provider and signature of its authorized employee.
			|
			|<b>Both certifications are required, otherwise the application will be rejected. </b>
			|';"));

	FormParameters = New Structure;
	FormParameters.Insert("ListOfCommands", ListOfCommands);
	FormParameters.Insert("QueryText", QueryText);
	FormParameters.Insert("Title",  NStr("en = 'Make sure the application is certified correctly';"));
	FormParameters.Insert("ConfirmationHeader",  NStr("en = 'I confirm that the application is certified by both companies';"));
	
	OpenForm("CommonForm.ConfirmationOfPhoneChange", FormParameters, ThisForm, , , , TheNotificationIsAsFollows);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UserSelectionResult(SelectionResult, AdditionalParameters) Export
	
	If SelectionResult = SendApplicationCommand() Then
		File = New Structure("Name,Address", ApplicationFile, ApplicationFilePath);
		Result = PreparationOfApplication(File); 
		If Result.Completed2 Then
			ApplicationSent = True;
			FormControl(ThisObject);
		Else
			CommonClient.MessageToUser(Result.ErrorDescription); 
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function SendApplicationCommand()
	
	Return "SendApplication";
	
EndFunction

&AtClient
Function CancelCommand()
	
	Return "Cancel";
	
EndFunction

&AtClient
Procedure SendConfirmationCode()
	
	DetachIdleHandler("Attachable_UpdateNewPhone");
	ClearMessages();
	ConfirmationCode = Undefined;
	
	Result = CheckNumberOnServer(NewPhone, ConfirmPhoneNumberForPasswords.CheckID);
	If Result.Completed2 Then
		Timer = Result.DelayBeforeResending;
		ConfirmPhoneNumberForPasswords.CheckID = Result.Id;
		StartCountdown();
		ConfirmPhoneNumberForPasswords.CheckInProgress = True;
		ConfirmPhoneNumberForPasswords.CodeSent = True;
		
		AttachIdleHandler("Attachable_ActivateConfirmationCodeField", 0.1, True);	
	Else
		CommonClient.MessageToUser(Result.ErrorDescription,, "NewPhone");
	EndIf;
	FormControl(ThisObject);
	
EndProcedure

&AtServerNoContext
Function CheckNumberOnServer(Phone, Id)
	
	Return CryptographyServiceManager.GetPhoneVerificationCode(Phone, Id);
	
EndFunction

&AtClient
Procedure Attachable_ActivateConfirmationCodeField()
	
	CurrentItem = Items.ConfirmationCode;
	
EndProcedure

&AtClient
Procedure StartCountdown()
	
	AttachIdleHandler("Attachable_HandlerCountdown", 1, True);
	
EndProcedure

&AtClient
Procedure Attachable_HandlerCountdown()
	
	Timer = Timer - 1;
	If Timer >= 0 Then
		CountdownLabel = StrTemplate(NStr("en = 'You can request the code again in %1 sec.';"), Timer);
		AttachIdleHandler("Attachable_HandlerCountdown", 1, True);		
	Else
		CountdownLabel = "";
		ConfirmPhoneNumberForPasswords.CodeSent = False;
		FormControl(ThisObject);
	EndIf;
	
EndProcedure

// Returns:
//  Boolean - Confirmation flag.
&AtClient
Function VerifyPhoneVerification()
	
	If Not ConfirmPhoneNumberForPasswords.ConfirmationCompleted Then
		MessageText = NStr("en = 'Confirm a new phone number first';");
		CommonClient.MessageToUser(MessageText,, "NewPhone");		
	EndIf;
	
	Return ConfirmPhoneNumberForPasswords.ConfirmationCompleted;
	
EndFunction

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items = Form.Items;
	
	Items.PhoneNumberConfirmedPicture.Visible = Form.ConfirmPhoneNumberForPasswords.ConfirmationCompleted;
	Items.ConfirmPhoneNumber.Visible = 
		Form.ConfirmPhoneNumberForPasswords.ValueEntered 
		And Not Form.ConfirmPhoneNumberForPasswords.ConfirmationCompleted 
		And Not Form.ConfirmPhoneNumberForPasswords.CheckInProgress;
	Items.NewPhone.ReadOnly = ValueIsFilled(Form.ConfirmPhoneNumberForPasswords.CheckID);
	Items.ConfirmationCodeGroup.Visible = 
		Form.ConfirmPhoneNumberForPasswords.CheckInProgress 
		And Not Form.ConfirmPhoneNumberForPasswords.ConfirmationCompleted;
		
	Items.ResendCode.Visible = Not Form.ConfirmPhoneNumberForPasswords.CodeSent;
	Items.CountdownLabel.Visible = Form.ConfirmPhoneNumberForPasswords.CodeSent;
	
	Form.ApplicationFile = NStr("en = 'Select';");
	
	Items.InstructionGroup_.Visible = Not Form.ApplicationSent;
	Items.Information.Visible = Form.ApplicationSent;
	Items.Information.Title = StrTemplate(NStr("en = 'Your request is under review.
                                                    |We''ll send you a text with the status to %1';"), Form.NewPhone);
													
EndProcedure

&AtServerNoContext
Function GetTabularDocumentOnServer(ApplicationID, CheckID, CertificateID)
	
	Result = CryptographyServiceManager.PrintStatement(ApplicationID, CheckID, CertificateID);
	If Not Result.Completed2 Then
		Common.MessageToUser(Result.ErrorDescription);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function SendApplicationAtServer(ApplicationID, ApplicationFile)
	
	Result = CryptographyServiceManager.SendApplication(ApplicationID, ApplicationFile);
	If Not Result.Completed2 Then
		Common.MessageToUser(Result.ErrorDescription);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function PreparationOfApplication(File)
	
	Result	= New Structure();
	Result.Insert("Completed2", True);
	
	If Not ApplicationIsPrinted Then
		Result = GetTabularDocumentOnServer(
			ApplicationID, ConfirmPhoneNumberForPasswords.CheckID, 
			CryptographyServiceInternal.Id(Certificate));
	EndIf;
	
	If Result.Completed2 Then
		Result = SendApplicationAtServer(ApplicationID, File);
	EndIf;	
	
	Return Result;
	
EndFunction

&AtClient
Procedure Attachable_CheckConfirmationCode()
	
	ClearMessages();
	
	ConfirmationCode = TrimAll(ConfirmationCode);
	If StrLen(ConfirmationCode) = 6 Then
		Result = Undefined;
		
		If ConfirmPhoneNumberForPasswords.CheckInProgress Then
			Result = CheckPhoneByCodeOnServer(
				ConfirmPhoneNumberForPasswords.CheckID, ConfirmationCode);
			If Result.Completed2 Then
				ConfirmPhoneNumberForPasswords.CheckInProgress = False;
				ConfirmPhoneNumberForPasswords.ConfirmationCompleted = True;				
			EndIf;
		EndIf;
		
		If Result <> Undefined Then
			If Result.Completed2 Then
				DetachIdleHandler("Attachable_HandlerCountdown");
				FormControl(ThisObject);
			Else
				CommonClient.MessageToUser(Result.ErrorDescription,, "ConfirmationCode");
			EndIf;
		EndIf;	
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CheckPhoneByCodeOnServer(Id, ConfirmationCode) 
	
	Return CryptographyServiceManager.CheckPhoneNumberByCode(Id, ConfirmationCode);
	
EndFunction

&AtClient
Procedure Attachable_UpdateNewPhone()
	
	Items.ConfirmPhoneNumber.Visible = ConfirmPhoneNumberForPasswords.ValueEntered;
	If ConfirmPhoneNumberForPasswords.ValueEntered Then
		Items.NewPhone.UpdateEditText();
		DetachIdleHandler("Attachable_ActivateCheckNumberButton");
		AttachIdleHandler("Attachable_ActivateCheckNumberButton", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_UpdateTextOfNewPhoneField()
	
	Items.NewPhone.UpdateEditText();
	
EndProcedure

&AtClient
Procedure Attachable_ActivateCheckNumberButton()
	
	CurrentItem = Items.ConfirmPhoneNumber;	
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInVariablesForPhoneVerification(Form)
	
	Form.ConfirmPhoneNumberForPasswords = ConfirmPhoneNumberForPasswords(False, False, "", False, False);
	
EndProcedure

&AtClientAtServerNoContext
Function ConfirmPhoneNumberForPasswords(ValueEntered, CheckInProgress, CheckID, ConfirmationCompleted, CodeSent)
	
	ConfirmPhoneNumberForPasswords = New Structure;
	
	ConfirmPhoneNumberForPasswords.Insert("ValueEntered", ValueEntered);
	ConfirmPhoneNumberForPasswords.Insert("CheckInProgress", CheckInProgress);
	ConfirmPhoneNumberForPasswords.Insert("CheckID", CheckID);
	ConfirmPhoneNumberForPasswords.Insert("ConfirmationCompleted", ConfirmationCompleted);
	ConfirmPhoneNumberForPasswords.Insert("CodeSent", CodeSent);
	
	Return ConfirmPhoneNumberForPasswords;
	
EndFunction

#EndRegion