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

	If IsFolder Then
		Return;
	EndIf;

	If ValueIsFilled(Ref) Then
		AccessGroup = Ref;
	Else
		RefToNew = GetNewObjectRef();
		If Not ValueIsFilled(RefToNew) Then
			RefToNew = Catalogs._DemoProductAccessGroups.GetRef();
			SetNewObjectRef(RefToNew);
		EndIf;
		AccessGroup = RefToNew;
	EndIf;

EndProcedure

#EndRegion

#Else
	Raise NStr("en = 'Invalid object call on the client.';");
#EndIf