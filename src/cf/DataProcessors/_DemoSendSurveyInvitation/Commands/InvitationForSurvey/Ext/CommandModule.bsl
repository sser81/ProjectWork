///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Template = TemplateMessageByOwner(CommandParameter);
	
	OpeningParameters          = MessageTemplatesClient.FormParameters(CommandExecuteParameters);
	OpeningParameters.Owner = CommandExecuteParameters.Source;
	
	MessageTemplatesClient.ShowTemplateForm(Template, OpeningParameters);
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//  TemplateOwner - DocumentRef.PollPurpose
//
&AtServer
Function TemplateMessageByOwner(TemplateOwner)

	Template = MessageTemplates.TemplateParameters(TemplateOwner);
	If ValueIsFilled(Template.Ref) Then
		Return TemplateOwner;
	Else
		FillTemplates(Template, TemplateOwner);
	EndIf;
	
	Return Template;
	
EndFunction

&AtServer
Procedure FillTemplates(Template, TemplateOwner)
	
	Template.Description = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Invitation for a survey on ""%1""';"), TemplateOwner.Description);
		
	Template.Subject = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Survey on [%1]';"), "PollPurpose.Description");
	
	TextTemplate1 = NStr("en = '<P>Hello, <P>We would like to invite you to participate in the survey on [%1]';")
		+ NStr("en = '<P><P>The survey will be open on [%2]';")
		+ NStr("en = 'To start the survey, click the link below.';")
		+ NStr("en = '<BR/> [%3]';")
		+ NStr("en = '<P><P>Thank you for taking part in the survey.';")
		+ NStr("en = '<P><P>[%4]';")
		+ NStr("en = '<P>[%5]';")
		+ NStr("en = '<P>[%6]';")
		+ NStr("en = '<P>[%7]';");
		
	Template.Text = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, 
		"PollPurpose.Description", "PollPurpose.StartDate{DLF=''DD''}", 
		"CommonAttributes.InfobasePublicationURL", "CommonAttributes.MainCompany",
		"CommonAttributes.CurrentUser.Individual", "CommonAttributes.CurrentUser.Phone",
		"CommonAttributes.CurrentUser.Email");
	
	Template.EmailFormat1 = Enums.EmailEditingMethods.HTML;
	Template.FullAssignmentTypeName = "Document.PollPurpose";
	
EndProcedure

#EndRegion