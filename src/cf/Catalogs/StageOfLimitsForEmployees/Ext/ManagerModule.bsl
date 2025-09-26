Function FindByDescriptionKey(Description, EmploymentContract, TypeOfLimit) Export 

	Query = New Query;
	Query.Text =
	"SELECT
	|	StageOfLimitsForEmployees.Ref AS Ref
	|FROM
	|	Catalog.StageOfLimitsForEmployees AS StageOfLimitsForEmployees
	|WHERE
	|	StageOfLimitsForEmployees.EmploymentContract = &EmploymentContract
	|	AND StageOfLimitsForEmployees.TypeOfLimit = &TypeOfLimit
	|	AND StageOfLimitsForEmployees.DescriptionKey = &DescriptionKey";

	Query.SetParameter("EmploymentContract", EmploymentContract);
	Query.SetParameter("TypeOfLimit", TypeOfLimit);
	Query.SetParameter("DescriptionKey", GetDescriptionKey(Description));

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Undefined;
	EndIf;

EndFunction

Function UpdateStage(Description, EmploymentContract, TypeOfLimit, StartData, EndData, Ref = Undefined, CreateNotFound = True) Export 

	If Ref <> Undefined Then
		Object = Ref.GetObject();
	Else
		Object = Undefined;
	EndIf;

	If Object = Undefined Then
		If CreateNotFound Then

			Object = Catalogs.StageOfLimitsForEmployees.CreateItem();
			
			If Ref <> Undefined Then
				Object.SetNewObjectRef(Ref);
			EndIf;
		Else
			Return Undefined;
		EndIf;
	EndIf;

	Object.Description 	= Description;
	Object.StartDate	= StartData;
	Object.EndDate		= EndData;

	Object.EmploymentContract 	= EmploymentContract;
	Object.TypeOfLimit 			= TypeOfLimit;
	Object.DescriptionKey 		= GetDescriptionKey(Object.Description);

	Object.Write();

	Return Object.Ref;

EndFunction

Procedure UpdateStageForRef(Ref, Description, StartData, EndData) Export 

	Object = Ref.GetObject();

	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	EmployeeLimitPlaningSliceLast.LimitDate AS StartData,
	|	EmployeeLimitPlaningSliceLast.LimitDateEnd AS EndData,
	|	EmployeeLimitPlaningSliceLast.StageDescription AS Description
	|FROM
	|	InformationRegister.EmployeeLimitPlaning.SliceLast(, Stage = &Ref) AS EmployeeLimitPlaningSliceLast";

	Query.SetParameter("Ref", Ref);

	Selection = Query.Execute().Select();

	// если по этапу уже есть движения в графике, то необходимо актуализировать
	// его в соответствии с последними изменениями графика
	If Selection.Next() Then
		FillPropertyValues(Object, Selection);
	Else
		Object.Description 	= Description;
		Object.StartDate	= StartData;
		Object.EndDate		= EndData;
	EndIf;

	Object.DescriptionKey 	= GetDescriptionKey(Object.Description);
	Object.Write();

EndProcedure

Function GetDescriptionKey(Description) Export 

	DescriptionKey = StrReplace(Description, " ", "");	
	DescriptionKey = Upper(DescriptionKey);

	Return DescriptionKey;

EndFunction
