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

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef._DemoGoodsReceipt") Then
		BusinessOperation = Enums._DemoBusinessOperations.IssueCashToAdvanceHolder;
		DocumentObject = FillingData.GetObject();
		Sum = DocumentObject.AgentServices.Total("Sum");
		For Each TableRow In DocumentObject.Goods Do
			Sum = Sum + TableRow.Price * TableRow.Count;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf