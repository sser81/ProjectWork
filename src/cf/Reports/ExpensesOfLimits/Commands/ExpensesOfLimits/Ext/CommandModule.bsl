
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters 	= New Structure;
	FormParameters.Insert("VariantKey", "ExpensesOfLimits");
	FormParameters.Insert("ReportDate", CurrentDate());
	FormParameters.Insert("Filter", New Structure);
	FormParameters.Insert("GenerateOnOpen", True);

	OpenForm("Report.ExpensesOfLimits.ObjectForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);

EndProcedure
