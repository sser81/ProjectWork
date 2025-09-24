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

// Changes, adds, or deletes contact information standard commands displayed in catalogs and documents.
// Toggles contact information icons on the left of the contact information kind title.
// Changes the position of the button "Add additional contact information field".
// Changes the width of the comment field for the contact information of the kinds
// "Phone", "Email", "Skype", "WebPage", and "Fax".
//
// Parameters:
//  Settings - Structure:
//    * ShouldShowIcons - Boolean
//    * DetailsOfCommands - See ContactsManager.DetailsOfCommands
//    * PositionOfAddButton - ItemHorizontalLocation - Valid values are Left, Right, or Auto.
//                                                                  If set to Left, it always appears on the left.
//                                                                  If set to Right, it always appears on the right.
//                                                                  If set to Auto, it is positioned on the right if
//                                                                         contact information is a field
//                                                                         and on the left if contact information is a hyperlink
//                                                                         or if there is no contact information field.
//                                                                         
//    * CommentFieldWidth - Number - Comment field width for contact information fields of the following types: Phone, Email,
//                                      Skype, WebPage, and Fax. This parameter is set only if the contact
//                                      information group is limited in width.
//
//  Example:
//     Settings.ShouldShowIcons = True;
//     Settings.CommentFieldWidth = 10;
//     Settings.PositionOfAddButton = ItemHorizontalLocation.Auto;
//
//     Address = Enum.ContactInformationTypes.Address;
//     Settings.CommandDetails[Address].PlanMeeting.Title = NStr("ru='Meeting'");
//     Settings.CommandDetails[Address].PlanMeeting.ToolTip = NStr("en='Schedule a meeting.'");
//     Settings.CommandDetails[Address].PlanMeeting.Picture = PictureLib.PlannedInteraction;
//     Settings.CommandDetails[Address].PlanMeeting.Action = "StandardSubsystemsClient.OpenMeetingDocForm";
//    
//     CompanyPhysicalAddress = ContactsManager.ContactInformationKindByName("_DemoCompanyPhysicalAddress");
//      Settings.CommandDetails[CompanyPhysicalAddress] = 
//    	Common.CopyRecursive(ContactsManager.CommandsOfContactInfoType(Enums.ContactInformationTypes.Address));
//      Settings.CommandDetails[CompanyPhysicalAddress].PlanMeeting.Action = ""; // Disable the command for the contact information kind.
//
//   2 parameters are passed to the procedures specified in "Action":
//       ContactInformation - Structure:
//         * Presentation - String
//         * Value - String
//         * Type - EnumRef.ContactInformationTypes
//         * Kind - CatalogRef.ContactInformationKinds
//       AdditionalParameters - Structure:        
//         * ContactInformationOwner - DefinedType.ContactInformationOwner.
//         * Form - ClientApplicationForm - Form of the owner object, where the contact information is to be displayed.
// 
//     Procedure OpenMeetingDocForm(ContactInformation, AdditionalParameters) Export
//		  FillingValues = New Structure;
//		  FillingValues.Insert("MeetingPlace", ContactInformation.Presentation);
//		  If TypeOf(AdditionalParameters.ContactInformationOwner) = Type("DocumentRef.SalesOrder") Then
//		    	FillingValues.Insert("SubjectOf", AdditionalParameters.ContactInformationOwner);
//		    	FillingValues.Insert("Contact", "");
//		  Else
//		    	FillingValues.Insert("Contact", AdditionalParameters.ContactInformationOwner);
//		    	FillingValues.Insert("SubjectOf", "");
//		  EndIf;
//
//		  OpenForm("Document.Meeting.ObjectForm", New Structure("FillingValues", FillingValues),
//			AdditionalParameters.Form);
//	   EndProcedure
//
Procedure OnDefineSettings(Settings) Export

	// _Demo Example Start

	Address = Enums.ContactInformationTypes.Address;
	Settings.DetailsOfCommands[Address].PlanMeeting.Title  = NStr("en = 'Appointment';");
	Settings.DetailsOfCommands[Address].PlanMeeting.ToolTip  = NStr("en = 'Create an appointment event';");
	Settings.DetailsOfCommands[Address].PlanMeeting.Picture   = PictureLib.GroupConversation;
	Settings.DetailsOfCommands[Address].PlanMeeting.Action   = "_DemoStandardSubsystemsClient.OpenMeetingDocForm";


    DemoCompanyPhysicalAddress = ContactsManager.ContactInformationKindByName("_DemoCompanyPhysicalAddress");
    Settings.DetailsOfCommands[DemoCompanyPhysicalAddress] = 
    	Common.CopyRecursive(ContactsManager.CommandsOfContactInfoType(Enums.ContactInformationTypes.Address));
    Settings.DetailsOfCommands[DemoCompanyPhysicalAddress].PlanMeeting.Action = ""; // Disables command actions for the given kind
    
    DemoCompanyLegalAddress = ContactsManager.ContactInformationKindByName("_DemoCompanyLegalAddress");
    Settings.DetailsOfCommands[DemoCompanyLegalAddress] = 
    	Common.CopyRecursive(ContactsManager.CommandsOfContactInfoType(Enums.ContactInformationTypes.Address));
    Settings.DetailsOfCommands[DemoCompanyLegalAddress].PlanMeeting.Action = ""; // Disables command actions for the given kind
    
    // _Demo Example End
    
EndProcedure

// Gets descriptions of contact information kinds in different languages.
//
// Parameters:
//  Descriptions - Map of KeyAndValue - a presentation of a contact information kind in the passed language:
//     * Key     - String - The name of a contact information kind. For example, "PartnerAddress".
//     * Value - String - a description of a contact information kind for the passed language code.
//  LanguageCode - String - a language code. For example, "en".
//
// Example:
//  Descriptions["PartnerAddress"] = NStr("ru='Адрес'; en='Address';", LanguageCode);
//
Procedure OnGetContactInformationKindsDescriptions(Descriptions, LanguageCode) Export
	
	// _Demo Example Start
	
	// "Partner contacts" catalog contact information
	Descriptions["_DemoContactPersonAddress"] = NStr("en = 'Contact person address';", LanguageCode);
	Descriptions["_DemoContactPersonEmail"] = NStr("en = 'Contact person''s email';", LanguageCode);
	Descriptions["Catalog_DemoPartnersContactPersons"] = NStr("en = '""Partner contacts"" catalog contact information';", LanguageCode);
	
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
	_DemoInfobaseUpdateSSL.AttheInitialFillingoftheTypesofContactInformation(LanguagesCodes, Items, TabularSections);
	// _Demo Example End
	
EndProcedure

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.
//
// Parameters:
//  Object                  - CatalogObject.PerformerRoles - Object to populate.
//  Data                  - ValueTableRow - Object fill data.
//  AdditionalParameters - Structure:
//   * PredefinedData - ValueTable - Data populated in the OnInitialItemsFilling procedure.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
EndProcedure

#EndRegion
