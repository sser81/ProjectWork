﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Gets details of predefined property sets.
//
// Parameters:
//  Sets - ValueTree:
//     * Name           - String - a property set name. Generated from the full metadata
//          object name by replacing a period (".") by an underscore ("_").
//          For example, Document_SalesOrder.
//     * Id - UUID - a UUID of the predefined property set.
//          Should not be repeated in other property sets.
//          ID format Random UUID (Version 4).
//          To get an ID, in 1C:Enterprise mode calculate the value of
//          the "New UniqueID" platform constructor or use an online generator,
//          for example, https://www.uuidgenerator.net/version4.
//     * Used  - Undefined
//                     - Boolean - indicates whether a property set is used.
//          For example, you can use it to hide a set by functional options.
//          Default value - Undefined, matches the True value.
//     * IsFolder     - Boolean - True if the property set is a folder.
//
Procedure OnGetPredefinedPropertiesSets(Sets) Export
	
	// _Demo Example Start
	_DemoProperties.OnGetPredefinedPropertiesSets(Sets);
	// _Demo Example End
	
EndProcedure

// Gets descriptions of second-level property sets in different languages.
//
// Parameters:
//  Descriptions - Map of KeyAndValue - a set presentation in the passed language:
//     * Key     - String - a property set name. For example, Catalog_Partners_Common.
//     * Value - String - a set description for the passed language code.
//  LanguageCode - String - a language code. For example, "en".
//
// Example:
//  Descriptions["Catalog_Partners_Common"] = NStr("en='Common';", LanguageCode);
//
Procedure OnGetPropertiesSetsDescriptions(Descriptions, LanguageCode) Export
	
	// _Demo Example Start
	_DemoProperties.OnGetPropertiesSetsDescriptions(Descriptions, LanguageCode);
	// _Demo Example End
	
EndProcedure

// Fills object property sets. Usually required if there is more than one set.
//
// Parameters:
//  Object       - AnyRef      - a reference to an object with properties.
//               - ClientApplicationForm - a form of the object, to which properties are attached.
//               - FormDataStructure - details of the object, to which properties are attached.
//
//  RefType    - Type - a type of the property owner reference.
//
//  PropertiesSets - ValueTable:
//     * Set - CatalogRef.AdditionalAttributesAndInfoSets
//     * SharedSet - Boolean - True if the property set contains properties
//                             common for all objects.
//    Then, form item properties of the FormGroup type and the usual group kind
//    or page that is created if there are more than one set excluding
//    a blank set that describes properties of deleted attributes group.
//
//    If the value is Undefined, use the default value.
//
//    For any group of a client application form.
//     * Height                   - Number
//     * Title                - String
//     * ToolTip                - String
//     * VerticalStretch   - Boolean
//     * HorizontalStretch - Boolean
//     * ReadOnly           - Boolean
//     * TitleTextColor      - Color
//     * Width                   - Number
//     * TitleFont           - Font
//                    
//    For regular group and page.
//     * Group              - ChildFormItemsGroup
//
//    For regular group.
//     * Representation              - UsualGroupRepresentation
//
//    For page.
//     * Picture                 - Picture
//     * ShowTitle      - Boolean
//
//  StandardProcessing - Boolean - an initial value is True. Indicates whether to get
//                         the default set when PropertiesSets.Count() is equal to zero.
//
//  AssignmentKey   - Undefined - (initial value) - specifies to calculate
//                      the assignment key automatically and add PurposeUseKey and WindowOptionsKey to
//                      form property values
//                      to save form changes (settings, position, and size)
//                      separately for different sets.
//                       For example, for each product kind - its own sets.
//
//                   - String - (not more than 32 characters) - use the specified assignment key
//                      to add it to form property values.
//                      Blank string - do not change form key properties as
//                      they are set in the form and already consider differences of sets.
//
//                    Addition has format "PropertySetKey<AssignmentKey>"
//                    to be able to update <AssignmentKey> without re-adding.
//                    Upon automatic calculation, <AssignmentKey> contains reference ID hash
//                    of ordered property sets.
//
Procedure FillObjectPropertiesSets(Val Object, RefType, PropertiesSets, StandardProcessing, AssignmentKey) Export
	
	// _Demo Example Start
	_DemoProperties.FillObjectPropertiesSets(Object, RefType, PropertiesSets, StandardProcessing, AssignmentKey);
	// _Demo Example End
	
EndProcedure

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
EndProcedure

// See also InfobaseUpdateOverridable.OnInitialItemsFilling
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	// _Demo Example Start
	_DemoProperties.OnInitialItemsFilling(LanguagesCodes, Items, TabularSections);
	// _Demo Example End
	
EndProcedure

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.
//
// Parameters:
//  Object                  - CatalogObject.PerformerRoles - Object to populate.
//  Data                  - ValueTableRow - object filling data.
//  AdditionalParameters - Structure:
//   * PredefinedData - ValueTable - Data populated in the OnInitialItemsFilling procedure.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
EndProcedure

#EndRegion

