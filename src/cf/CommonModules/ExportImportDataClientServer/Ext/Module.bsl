////////////////////////////////////////////////////////////////////////////////
// "Data import export" subsystem.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Export file name.
// 
// Returns: 
//  String - Export file name.
Function NameOfDataUploadFile() Export

	Return "data_dump.zip"

EndFunction

Function LongTermOperationHint() Export
	Return NStr("en = 'The operation might take a long time. Please wait...';");
EndFunction

Function ExportImportDataAreaPreparationStateView(importDataArea) Export
	If importDataArea Then
		StatusPresentation = NStr("en = 'Preparing to import data.';");
	Else
		StatusPresentation = NStr("en = 'Preparing to export data.';");
	EndIf;
	Return StatusPresentation;
EndFunction

#EndRegion