///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

// _Demo Example Start

#Region EventHandlers

Procedure OnStart()
	
	// Skip initialization if the infobase update is not completed.
	If InfobaseUpdate.InfobaseUpdateRequired() Then
		Return;
	EndIf;
	
	WriteInformation(NStr("en = 'Demo: external connection session started.';"));
	
EndProcedure

Procedure OnExit()
	
	// Skip processing if the infobase update is not completed.
	If InfobaseUpdate.InfobaseUpdateRequired() Then
		Return;
	EndIf;
	
	WriteInformation(NStr("en = 'Demo: external connection session closed.';"));
	
EndProcedure

#EndRegion

#Region Private

Procedure WriteInformation(Val Text)
	
	WriteLogEvent(NStr("en = 'External connection';", Common.DefaultLanguageCode()),
		EventLogLevel.Information,,, Text);
	
EndProcedure

#EndRegion

// _Demo Example End
