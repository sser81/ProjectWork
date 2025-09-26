
#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Key = Undefined Or Parameters.Key.IsEmpty() Then
		Object.AmountLimitControl = True;
		Object.CountLimitControl = False;
		Object.CheckLimitControl = False;
	EndIf;

	GeneralFormSetup();

	SetVisibilityAndAccessibility();

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	CurrentObject.AmountLimitControl = ResourceType = 0;
	CurrentObject.CountLimitControl = ResourceType = 1;
	CurrentObject.CheckLimitControl = ResourceType = 2;

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	If ValueIsFilled(Object.CashFlowItem) Then

		Query = New Query;
		Query.Text =
		"SELECT
		|	TypesOfLimitsForEmployees.Ref AS Ref
		|FROM
		|	Catalog.TypesOfLimitsForEmployees AS TypesOfLimitsForEmployees
		|WHERE
		|	TypesOfLimitsForEmployees.CashFlowItem = &CashFlowItem
		|	AND TypesOfLimitsForEmployees.Ref <> &Ref";

		Query.SetParameter("Ref", Object.Ref);
		Query.SetParameter("CashFlowItem", Object.CashFlowItem);

		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			TextTemplate = NStr("ru = 'Статья движения денежных средств ""%1"" не может быть использована, так как она соответствует другому виду лимитов';
								|en = 'Cash flow item ""%1"" cannot be used, because it corresponds to a different type of limit'");
			CommonClientServer.MessageToUser(StrTemplate(TextTemplate, String(Object.CashFlowItem)),, "Object.CashFlowItem",, Cancel);
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region ItemEventHandlers

&AtClient
Procedure ResourceTypeOnChange(Item)

	If ResourceType = 2 Then
		Object.OneTime = True;
	EndIf;

	SetVisibilityAndAccessibility();

EndProcedure
 
#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure GeneralFormSetup(OnCreateAtServer = False, WriteParameters = Undefined)

	If Object.CountLimitControl Then
		ResourceType = 1;

	ElsIf Object.CheckLimitControl Then
		ResourceType = 2;
	Else
		ResourceType = 0;
	EndIf;

EndProcedure

&AtServer 
Procedure SetVisibilityAndAccessibility() 

	Items.OneTime.Visible = ResourceType = 0
							Or ResourceType = 1;

EndProcedure // SetVisibilityAndAccessibility()

#EndRegion
