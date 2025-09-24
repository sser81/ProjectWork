///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

// Returns the result of the unposted document print check.
Function PrintingEnabled(DocumentReference) Export
	
	If Common.ObjectAttributeValue(DocumentReference, "Posted") Then
		Return
			NStr("en = 'Printing of all posted documents is allowed.
			           |To check, select an unposted document.';")
	EndIf;
	
	If AccessManagement.HasRole("_DemoPrintUnpostedDocuments", DocumentReference) Then
		Return
			NStr("en = 'Printing of this unposted document is allowed, since the document
			           |is available for reading (considering the restriction at the record level), and the ""Demo: Unposted document printing"" role is included
			           |in the profile.';");
	Else
		Return
			NStr("en = 'You cannot print this unposted document. This may be because the document
				       |is not available for reading due to RLS restrictions,
				       |or because the profile does not include the ""Demo: Print unposted documents"" role.';");
	EndIf;
	
EndFunction

#EndRegion

