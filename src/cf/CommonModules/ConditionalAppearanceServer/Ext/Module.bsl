////////////////////////////////////////////////////////////////////////////////
// PUBLIC

#Region Public

Procedure SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems) Export
	
	For Each Item In AppearanceItems Do
		
		If Item.Value <> Undefined Then
			
			AppearanceItem = ConditionalAppearanceItem.Appearance.Items.Find(Item.Key);
			
			AppearanceItem.Value	= Item.Value;
			AppearanceItem.Use		= True;
			
		EndIf; 
		
	EndDo;
	
EndProcedure

Function NotApplicableText() Export
	
	Return NStr(
		"en = 'Not Applicable';
		|ru = 'Не применимо';
		|ar = 'غير قابل للتطبيق'"
	);
	
EndFunction 

Function NotRequiredText() Export
	
	//-> FBI-3601
	
	Return NStr(
		"en = 'Not Required';
		|ru = 'Не требуется';
		|ar = 'غير مطلوب'"
	);
	
	//<- FBI-3601
	
EndFunction 

Function NotPresentedText() Export
	
	Return NStr(
		"en = '<Not presented>';
		|ru = '<Не предъявлена>';
		|ar = '<غير معروض>'"
	);
	
EndFunction

Function AutoText() Export
	
	//-> FBI-2637
	
	Return NStr(
		"en = '<Auto>';
		|ru = '<Авто>';
		|ar = '<تلقائي>'"
	); 
	
	//<- FBI-2637
	
EndFunction 

Function InaccessibleTextColor() Export
	
	Return Metadata.StyleItems.InaccessibleTextFirstBIT.Value;
	
EndFunction 

Function AmountDoesNotMatchCalculatedTextColor() Export
	
	Return StyleColors.NegativeTextColor;
	
EndFunction

Function AppearanceItemsTemplate() Export
	
	// Help: DataCompositionAppearance
	
	AppearanceItems = New Structure;
	AppearanceItems.Insert("BackColor");
	AppearanceItems.Insert("TextColor");
	AppearanceItems.Insert("BorderColor");
	AppearanceItems.Insert("BorderStyle");
	AppearanceItems.Insert("Font");
	AppearanceItems.Insert("Indent");
	AppearanceItems.Insert("AutoIndent");
	AppearanceItems.Insert("HorizontalAlign");
	AppearanceItems.Insert("VerticalAlign");
	AppearanceItems.Insert("Placement");
	AppearanceItems.Insert("TextOrientation");
	AppearanceItems.Insert("Format");
	AppearanceItems.Insert("MarkNegatives");
	AppearanceItems.Insert("MinWidth");  // FBI-4631
	AppearanceItems.Insert("MaxWidth");  // FBI-4631
	AppearanceItems.Insert("MinHeight"); // FBI-4631
	AppearanceItems.Insert("MaxHeight"); // FBI-4631
	AppearanceItems.Insert("Text");
	AppearanceItems.Insert("MarkIncomplete");
	AppearanceItems.Insert("Visible");
	AppearanceItems.Insert("Enabled");
	AppearanceItems.Insert("ReadOnly");
	AppearanceItems.Insert("Show");
	AppearanceItems.Insert("ColorInChart");
	AppearanceItems.Insert("ShowGraphicalRepresentationOfDataOnChart");
	AppearanceItems.Insert("ShowGraphicalRepresentationOfDataInChartLegend");
	AppearanceItems.Insert("ChartTrendlines");
	AppearanceItems.Insert("LineInChart");
	AppearanceItems.Insert("MarkerInChart");
	AppearanceItems.Insert("IndicatorInChart");
	AppearanceItems.Insert("HorizontalStretch");
	AppearanceItems.Insert("WidthWeightFactor");
	AppearanceItems.Insert("ReferenceLineInChart");
	AppearanceItems.Insert("ReferenceBandInChart"); 
	
	Return New FixedStructure(AppearanceItems);
	
EndFunction

Function AppearanceItems() Export

	//-> FBI-3343
	
	AppearanceItemsTemplate	= AppearanceItemsTemplate();	
	
	Return New Structure(AppearanceItemsTemplate);	
	
	//<- FBI-3343
	
EndFunction

Function AddFormItem(ConditionalAppearanceItem, Item) Export

	AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
	
	AppearanceField.Field	= New DataCompositionField(Item.Name);
	AppearanceField.Use		= True;
	
	Return AppearanceField;
	
EndFunction  	

Function AddFilterGroupOr(ConditionalAppearanceItem) Export
	
	ItemType = Type("DataCompositionFilterItemGroup");
	
	If TypeOf(ConditionalAppearanceItem) = Type("DataCompositionFilterItemGroup") Then
			
		DataCompositionFilterItemGroup = ConditionalAppearanceItem.Items.Add(ItemType); // FBI-2554
		
	Else
		
		DataCompositionFilterItemGroup = ConditionalAppearanceItem.Filter.Items.Add(ItemType);
		
	EndIf;
	
	DataCompositionFilterItemGroup.GroupType	= DataCompositionFilterItemsGroupType.OrGroup;
	DataCompositionFilterItemGroup.Use			= True;
	
	Return DataCompositionFilterItemGroup;
	
EndFunction

Function AddFilterGroupAnd(ConditionalAppearanceItem) Export
	
	ItemType = Type("DataCompositionFilterItemGroup");
	
	If TypeOf(ConditionalAppearanceItem) = Type("DataCompositionFilterItemGroup") Then
		
		DataCompositionFilterItemGroup = ConditionalAppearanceItem.Items.Add(ItemType); // FBI-2554
		
	Else
		
		DataCompositionFilterItemGroup = ConditionalAppearanceItem.Filter.Items.Add(ItemType);
		
	EndIf;
	
	DataCompositionFilterItemGroup.GroupType	= DataCompositionFilterItemsGroupType.AndGroup;
	DataCompositionFilterItemGroup.Use			= True;
	
	Return DataCompositionFilterItemGroup;
	
EndFunction 

Function AddFilterItem(FilterItemGroup, FieldPath = Undefined) Export
	
	ItemType	= Type("DataCompositionFilterItem");	
	FilterItem	= FilterItemGroup.Items.Add(ItemType);
	
	If FieldPath <> Undefined Then
		FilterItem.LeftValue = New DataCompositionField(FieldPath);
	EndIf; 
	
	FilterItem.Use = True;
	
	Return FilterItem;
	
EndFunction 

Function AddConditionalAppearanceItem(AppearanceItems, Form, Item, ConditionFieldPath, ConditionRightValue = Undefined, ComparisonType = Undefined) Export

	//-> FBI-3343
	
	// Help: DataCompositionAppearance
		
	ConditionalAppearanceItem = Form.ConditionalAppearance.Items.Add();
	
	// ## Appearance
		
	SetAppearanceItems(ConditionalAppearanceItem, AppearanceItems); 
	
	// ## Items
	
	If TypeOf(Item) = Type("Array") Then
		
		For Each ArrayItem In Item Do
			AddFormItem(ConditionalAppearanceItem, ArrayItem);
		EndDo;
		
	Else
	
		AddFormItem(ConditionalAppearanceItem, Item);
		
	EndIf;
	
	// ## Filter
	
	If ConditionRightValue = Undefined Then
		ConditionRightValue = False;
	EndIf; 
	
	If ComparisonType = Undefined Then
		ComparisonType = DataCompositionComparisonType.Equal;
	EndIf;
	
	FilterGroupOr	= AddFilterGroupOr(ConditionalAppearanceItem);
	
	FilterItem		= AddFilterItem(FilterGroupOr, ConditionFieldPath);
	FilterItem.ComparisonType	= ComparisonType;
	FilterItem.RightValue		= ConditionRightValue;
	
	Return ConditionalAppearanceItem;
	
	//<- FBI-3343
	
EndFunction

#Region Presets

Procedure MarkDefaultValueWithBold(List, DefaultValue, SettingName = "DefaultValue") Export

	ListOfItemsForDeletion = New ValueList;
	
	For Each ConditionalAppearanceItem In List.ConditionalAppearance.Items Do
		If ConditionalAppearanceItem.UserSettingID = SettingName Then
			ListOfItemsForDeletion.Add(ConditionalAppearanceItem);
		EndIf;
	EndDo;
	
	For Each Item In ListOfItemsForDeletion Do
		List.ConditionalAppearance.Items.Delete(Item.Value);
	EndDo;

	If Not ValueIsFilled(DefaultValue) Then
		Return;
	EndIf;

	ConditionalAppearanceItem = List.ConditionalAppearance.Items.Add();

	FilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));

	FilterItem.LeftValue 		= New DataCompositionField("Ref");
	
	If TypeOf(DefaultValue) = Type("ValueList") Then
		FilterItem.ComparisonType 	= DataCompositionComparisonType.InList;
	Else
		FilterItem.ComparisonType 	= DataCompositionComparisonType.Equal;
	EndIf;
	
	FilterItem.RightValue 		= DefaultValue;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Font", New Font(, , True));
	ConditionalAppearanceItem.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
	ConditionalAppearanceItem.UserSettingID = SettingName;
	ConditionalAppearanceItem.Presentation 	= "Default value bold font";

EndProcedure // MarkDefaultValueWithBold()

Function MakeInaccessible(Form, Item, ConditionFieldPath, ConditionRightValue = Undefined, ComparisonType = Undefined) Export

	//-> FBI-3343
	
	AppearanceItems = AppearanceItems();
	
	AppearanceItems.Enabled			= False;
	AppearanceItems.MarkIncomplete	= False;
	AppearanceItems.Text			= NotApplicableText();
	AppearanceItems.TextColor		= InaccessibleTextColor();	
	
	Return AddConditionalAppearanceItem(AppearanceItems, Form, Item, ConditionFieldPath, ConditionRightValue, ComparisonType);

	//<- FBI-3343
	
EndFunction

Function MakeNotRequired(Form, Item, ConditionFieldPath, ConditionRightValue = Undefined, ComparisonType = Undefined) Export

	//-> FBI-3601
	
	AppearanceItems = AppearanceItems();
	
	AppearanceItems.Enabled			= False;
	AppearanceItems.MarkIncomplete	= False;
	AppearanceItems.Text			= NotRequiredText();
	AppearanceItems.TextColor		= InaccessibleTextColor();	
	
	Return AddConditionalAppearanceItem(AppearanceItems, Form, Item, ConditionFieldPath, ConditionRightValue, ComparisonType);

	//<- FBI-3601
	
EndFunction

Function MakeNotEditable(Form, Item, ConditionFieldPath, ConditionRightValue = Undefined, ComparisonType = Undefined) Export

	//-> FBI-3343
	
	AppearanceItems = AppearanceItems();
	AppearanceItems.ReadOnly = True;
	
	Return AddConditionalAppearanceItem(AppearanceItems, Form, Item, ConditionFieldPath, ConditionRightValue, ComparisonType);
	
	//<- FBI-3343
	
EndFunction

Function MarkComplete(Form, Item, ConditionFieldPath, ConditionRightValue = Undefined, ComparisonType = Undefined) Export
	
	//-> FBI-3343
	
	AppearanceItems = AppearanceItems();
	AppearanceItems.MarkIncomplete = False;
	
	Return AddConditionalAppearanceItem(AppearanceItems, Form, Item, ConditionFieldPath, ConditionRightValue, ComparisonType);
	
	//<- FBI-3343
	
EndFunction

Function MarkIncomplete(Form, Item, ConditionFieldPath, ConditionRightValue = Undefined, ComparisonType = Undefined) Export
	
	//-> FBI-3343
	
	AppearanceItems = AppearanceItems();
	AppearanceItems.MarkIncomplete = True;
	
	Return AddConditionalAppearanceItem(AppearanceItems, Form, Item, ConditionFieldPath, ConditionRightValue, ComparisonType);
	
	//<- FBI-3343
	
EndFunction

Function MarkNegative(Form, Item, ConditionFieldPath, ConditionRightValue = Undefined, ComparisonType = Undefined) Export
	
	//-> FBI-3415
	
	AppearanceItems = AppearanceItems();
	AppearanceItems.TextColor = StyleColors.NegativeTextColor;
	
	Return AddConditionalAppearanceItem(AppearanceItems, Form, Item, ConditionFieldPath, ConditionRightValue, ComparisonType);
	
	//<- FBI-3415
	
EndFunction 

Function MakeInvisible(Form, Item, ConditionFieldPath, ConditionRightValue = Undefined, ComparisonType = Undefined) Export
	
	//-> FBI-4942
	AppearanceItems = AppearanceItems();
	AppearanceItems.Visible = False;
	
	Return AddConditionalAppearanceItem(AppearanceItems, Form, Item, ConditionFieldPath, ConditionRightValue, ComparisonType);
	//<- FBI-4942
	
EndFunction

#EndRegion // Presets

#Region DynamicLists

// Procedure sets up conditional appearance in dynamic lists for column "Date"
//
Procedure ConfigureListDateColumn(List, DateFieldName = "Date") Export
		
	UserSettingID 			= "PredefinedOnlyTimeDateField";
	UserSettingPresentation = "Date Field Format (Today - Only Time)";
	
	AttributesToBeDeleted = New ValueList;
	
	// Delete existing conditional appearance items with required predefined setting ID or presentation
	For Each ConditionalAppearanceItem In List.SettingsComposer.Settings.ConditionalAppearance.Items Do	
		If ConditionalAppearanceItem.UserSettingID = UserSettingID
			Or ConditionalAppearanceItem.Presentation = UserSettingPresentation Then
			
			AttributesToBeDeleted.Add(ConditionalAppearanceItem);
			
		EndIf;		
	EndDo;
	
	For Each Item In AttributesToBeDeleted Do	
		List.SettingsComposer.Settings.ConditionalAppearance.Items(Item.Value);		
	EndDo;
	
	ConditionalAppearanceItem = List.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Presentation 	= UserSettingPresentation;
	ConditionalAppearanceItem.UserSettingID = UserSettingID;
	ConditionalAppearanceItem.Use 			= True;
	ConditionalAppearanceItem.ViewMode      = DataCompositionSettingsItemViewMode.Normal;
	
	FilterItemsGroup 			= ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemsGroup.Use 		= True;
	
	FilterItem   				= FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));	
	FilterItem.Use				= True;
	FilterItem.ComparisonType	= DataCompositionComparisonType.GreaterOrEqual;
	FilterItem.LeftValue		= New DataCompositionField(DateFieldName);
	FilterItem.RightValue		= New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);

	FilterItem   				= FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));	
	FilterItem.Use				= True;
	FilterItem.ComparisonType	= DataCompositionComparisonType.Less;
	FilterItem.LeftValue		= New DataCompositionField(DateFieldName);
	FilterItem.RightValue		= New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Format", "DLF=T");

	FormattedField 				= ConditionalAppearanceItem.Fields.Items.Add(); 
	FormattedField.Field		= New DataCompositionField(DateFieldName); 
	
EndProcedure // ConfigureListDateColumn()

// Procedure sets up conditional appearance in dynamic lists for column "Currency"
//
Procedure ConfigureListCurrencyColumn(List, CurrencyFieldName = "DocumentCurrency", CurrencySymbolFieldName = "DocumentCurrency.Symbol") Export
	
	AttributesToBeDeleted = New ValueList;
	
	// Delete existing conditional appearance items with required predefined setting ID or presentation
	For Each ConditionalAppearanceItem In List.SettingsComposer.Settings.ConditionalAppearance.Items Do	
		
		IsPredefinedCurrencySetting = ConditionalAppearanceItem.UserSettingID 		= "PredefinedCurrencyFieldVisibility"
										Or ConditionalAppearanceItem.Presentation 	= "Currency Field Visibility" 
										Or ConditionalAppearanceItem.UserSettingID 	= "PredefinedCurrencySymbolFieldVisibility"
										Or ConditionalAppearanceItem.Presentation 	= "Currency Symbol Field Visibility";
		
		If IsPredefinedCurrencySetting Then		
			AttributesToBeDeleted.Add(ConditionalAppearanceItem);			
		EndIf;	
		
	EndDo;
	
	For Each Item In AttributesToBeDeleted Do	
		List.SettingsComposer.Settings.ConditionalAppearance.Items(Item.Value);		
	EndDo;
	
	// CurrencyField visibility = True if symbol is not filled 
	ConditionalAppearanceItem = List.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Presentation 	= "Currency Field Visibility";
	ConditionalAppearanceItem.UserSettingID = "PredefinedCurrencyFieldVisibility";
	ConditionalAppearanceItem.Use 			= True;
	ConditionalAppearanceItem.ViewMode      = DataCompositionSettingsItemViewMode.Normal;
	
	FilterItem 					= ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.Use 				= True;
	
	FilterItem.ComparisonType	= DataCompositionComparisonType.Filled;
	FilterItem.LeftValue		= New DataCompositionField(CurrencySymbolFieldName);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Show", False);

	FormattedField 				= ConditionalAppearanceItem.Fields.Items.Add(); 
	FormattedField.Field		= New DataCompositionField(CurrencyFieldName); 
	
	// CurrencySumbolField visibility = False if symbol is not filled 
	ConditionalAppearanceItem = List.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	
	ConditionalAppearanceItem.Presentation 	= "Currency Symbol Field Visibility";
	ConditionalAppearanceItem.UserSettingID = "PredefinedCurrencySymbolFieldVisibility";
	ConditionalAppearanceItem.Use 			= True;
	ConditionalAppearanceItem.ViewMode      = DataCompositionSettingsItemViewMode.Normal;
	
	FilterItem 					= ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.Use 				= True;
	
	FilterItem.ComparisonType	= DataCompositionComparisonType.NotFilled;
	FilterItem.LeftValue		= New DataCompositionField(CurrencySymbolFieldName);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Show", False);

	FormattedField 				= ConditionalAppearanceItem.Fields.Items.Add(); 
	FormattedField.Field		= New DataCompositionField(CurrencySymbolFieldName); 
	
EndProcedure // ConfigureListCurrencyColumn()

// Procedure sets up a width of Amount column if Multi-Currencies disabled in data base
//
Procedure ConfigureListAmountWidth(AmountFormItem) Export
	
	If Not GetFunctionalOption("CurrencyTransactions") Then
		AmountFormItem.Width = 10;
	EndIf;
	
EndProcedure // ConfigureListAmountWidth()

#EndRegion // DynamicLists

#EndRegion // Public