﻿#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	Cancel = True;
	ShowMessageBox(, NStr("en = 'The data processor cannot be opened manually.';"));
EndProcedure

#EndRegion