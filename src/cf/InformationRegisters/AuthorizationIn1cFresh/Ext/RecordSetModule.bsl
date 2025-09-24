﻿#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel, Replacing)

	If DataExchange.Load Then
		Return;
	EndIf;
		
	If AdditionalProperties.Property("Password") Then
		SecureStorageKey = InformationRegisters.AuthorizationIn1cFresh.OwnerOfSecureStorage(Filter.User.Value);
		Common.WriteDataToSecureStorage(SecureStorageKey, AdditionalProperties.Password);
	EndIf;
	
EndProcedure

#EndRegion 

#EndIf
