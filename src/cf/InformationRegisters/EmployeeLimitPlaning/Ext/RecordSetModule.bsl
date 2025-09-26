
Procedure OnWrite(Cancel, Replacing)

	For Each Record In ThisObject Do
		If ValueIsFilled(Record.Stage) Then
			Catalogs.StageOfLimitsForEmployees.UpdateStageForRef(Record.Stage, Record.StageDescription, Record.LimitDate, Record.LimitDateEnd);
		EndIf;
	EndDo;

EndProcedure