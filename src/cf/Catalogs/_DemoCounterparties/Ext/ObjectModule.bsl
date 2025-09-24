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

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed("Catalog._DemoCounterparties");
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
EndProcedure

#EndRegion

#Else
	Raise NStr("en = 'Invalid object call on the client.';");
#EndIf