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

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN Catalog._DemoCounterparties AS T1
	|ON T1.TIN = T.TIN AND T1.CRTR = T.CRTR
	|;
	|AllowReadUpdate
	|WHERE
	| ValueAllowed(T1.Partner)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf
