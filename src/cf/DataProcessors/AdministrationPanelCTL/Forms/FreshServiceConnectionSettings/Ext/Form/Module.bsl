﻿#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillInAuthorizationData();
	
	Items.Fresh1CAuthorizationSettingsGroup.Visible = Not SaaSOperations.DataSeparationEnabled();	
	Items.ServicePaymentSettings.Enabled = ConstantsSet.UseServicePayment;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not SaaSOperations.DataSeparationEnabled() Then
		MessageTemplate = NStr("en = 'The ""%1"" field is required.';");
		CheckedConstants = New Array;
		CheckedConstants.Add("Fresh1CServiceAddress");
		For Each Item In CheckedConstants Do
			If Not ValueIsFilled(Constants.Fresh1CServiceAddress.Get()) Then
				Common.MessageToUser(
					StrTemplate(MessageTemplate, Metadata.Constants[Item].Presentation()), , Item, "ConstantsSet", Cancel);
			EndIf;
		EndDo; 
	EndIf;
	AuthorizationData = InformationRegisters.AuthorizationIn1cFresh.Read(Users.CurrentUser());
	If Not ValueIsFilled(AuthorizationData.Login) Then
		Common.MessageToUser(
			NStr("en = 'Authorization data in the service is not specified.';"), , , , Cancel);
	EndIf; 
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure Fresh1CServiceAddressOnChange(Item)
	
	OnChangeAttribute(Item);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetAuthorizationData(Command)
	
	Notification = New NotifyDescription("AfterSettingAuthorizationData", ThisObject);
	
	FormParameters = Undefined;
	If AuthorizationSet Then
		KeyConstructor = New Array;
		KeyConstructor.Add(New Structure("User", UsersClient.CurrentUser()));
		RecordKey = New("InformationRegisterRecordKey.AuthorizationIn1cFresh", KeyConstructor);
		FormParameters = New Structure("Key", RecordKey);
	EndIf;

	OpenForm("InformationRegister.AuthorizationIn1cFresh.RecordForm", FormParameters, , , , , Notification);
	
EndProcedure

&AtClient
Procedure ServicePaymentSettings(Command)
	
	FormParameters = New Structure;
	OpenForm(
		"DataProcessor.AdministrationPanelCTL.Form.ServicePaymentSettings", FormParameters,ThisObject);
		
EndProcedure

&AtClient
Procedure DownloadServiceRates(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf; 
	
	TimeConsumingOperation = StartLoadingServiceRates();
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	Notification = New NotifyDescription("WhenLoadingTariffsIsComplete", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Notification, IdleParameters);
	
EndProcedure

&AtClient
Procedure UseServicePaymentOnChange(Item)
	
	OnChangeAttribute(Item);
	Items.ServicePaymentSettings.Enabled = ConstantsSet.UseServicePayment;
	RefreshInterface();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterSettingAuthorizationData(Result, AdditionalParameters) Export
	
	FillInAuthorizationData();
	
EndProcedure

&AtServer
Procedure FillInAuthorizationData()
	
	AuthorizationData = InformationRegisters.AuthorizationIn1cFresh.Read(Users.CurrentUser());
	If Not ValueIsFilled(AuthorizationData.Login) Then
		Items.SetAuthorizationData.Title = NStr("en = 'Set authorization data';")
	Else
		AuthorizationSet = True;
		Items.SetAuthorizationData.Title = StrTemplate(
			NStr("en = 'Username: %1, subscriber code: %2';"), AuthorizationData.Login, Format(AuthorizationData.SubscriberCode, "NG=0"));
	EndIf; 
	
EndProcedure

&AtServer
Function StartLoadingServiceRates()
	
	ExecutionParameters = TimeConsumingOperations.ProcedureExecutionParameters();
	Return TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, "ServicePayment.DownloadServiceRates");
	
EndFunction

&AtClient
Procedure WhenLoadingTariffsIsComplete(Result, AdditionalParameters) Export
	
	If Result = Undefined Then // The user has canceled the task.
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	ShowUserNotification(NStr("en = 'Import completed';"), , 
		NStr("en = 'Service plans are imported.';"), PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure OnChangeAttribute(Item)
	
	ConstantsNames = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	
	For Each ConstantName In ConstantsNames Do
		If ConstantName <> "" Then
			Notify("Write_ConstantsSet", New Structure, ConstantName);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(TagName)
	
	ConstantsNames = New Array;
	DataPathAttribute = Items[TagName].DataPath;
	
	BeginTransaction();
	Try
		
		ConstantName = SaveAttributeValue(DataPathAttribute);
		ConstantsNames.Add(ConstantName);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	RefreshReusableValues();
	Return ConstantsNames;
	
EndFunction

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	CurrentValue  = ConstantManager.Get();
	If CurrentValue <> ConstantValue Then
		Try
			ConstantManager.Set(ConstantValue);
		Except
			ConstantsSet[ConstantName] = CurrentValue;
			Raise;
		EndTry;
	EndIf;
	
	Return ConstantName;
	
EndFunction

#EndRegion
