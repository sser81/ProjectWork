///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var Subsystems; // See InitializeTable
Var RequiredSubsystems;

#EndRegion

#Region Internal

Function SubsystemsDependencies() Export
	
	Subsystems = InitializeTable();
	
	RequiredSubsystems = New Map;
	RequiredSubsystems["Core"] = True;
	RequiredSubsystems["IBVersionUpdate"] = True;
	RequiredSubsystems["Users"] = True;

#Region AddressClassifier
	Subsystem = AddSubsystem("AddressClassifier");
	Subsystem.Synonym = NStr("en = 'Address classifier';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("GetFilesFromInternet,ContactInformation");
	Subsystem.LongDesc = NStr("en = '• Storage and provision of the address classifier to use in other applications.
		|• Entering addresses and verifying them via the Internet using web service of 1C Company.
		|• Importing the address classifier to the application from the user section of 1C Company website or from the specified directory (in standalone mode without stable Internet connection).';");
#EndRegion
	
#Region Surveys
	Subsystem = AddSubsystem("Surveys");
	Subsystem.Synonym = NStr("en = 'Surveys';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ItemOrderSetup,AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,AttachableCommands");
	Subsystem.LongDesc = NStr("en = '• Conduct a survey for external application users.
		|• Develop survey templates and send it to the list of respondents.
		|• Analyze the survey results.';");
#EndRegion
	
#Region Core
	Subsystem = AddSubsystem("Core");
	Subsystem.Synonym = NStr("en = 'Core';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Common procedures and functions for operations with strings, other data types, event log, and so on.
		|• Standard roles (%1, %2, %3, and so on).
		|• Automatic tracking of renamed metadata objects.
		|• Basic service features of the application administrator (event log, application window header setup, and so on).';");
	Subsystem.LongDesc = StrTemplate(Subsystem.LongDesc,
		"Administration", "FullAccess", "StartThinClient");
#EndRegion
	
#Region Banks
	Subsystem = AddSubsystem("Banks");
	Subsystem.Synonym = NStr("en = 'Banks';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("GetFilesFromInternet");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Store and provide access to the RF bank classifier (list of bank codes) to be used in other application subsystems.
		|• Import the RF bank classifier (list of bank codes) from ITS or the 1C website, automatically or on demand.';");
#EndRegion
	
#Region BusinessProcessesAndTasks
	Subsystem = AddSubsystem("BusinessProcessesAndTasks");
	Subsystem.Synonym = NStr("en = 'Business processes and tasks';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("EmailOperations,AccessManagement");
	Subsystem.LongDesc = NStr("en = '• Interactive task entry for application users.
		|• Informing users of their current tasks.
		|• Monitoring and controlling task execution by interested party - task authors and control managers.
		|• The basis for developing arbitrary business processes in the configuration.';");
#EndRegion
	
#Region Currencies
	Subsystem = AddSubsystem("Currencies");
	Subsystem.Synonym = NStr("en = 'Currencies';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("GetFilesFromInternet");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("FormulasConstructor");
	Subsystem.LongDesc = NStr("en = '• Storage and provision of access to the currency list and exchange rates.
		|• Downloading exchange rates from the 1C website.
		|• Choosing currencies from the all-Russian classifier (RCC).';");
#EndRegion
	
#Region ReportsOptions
	Subsystem = AddSubsystem("ReportsOptions");
	Subsystem.Synonym = NStr("en = 'Report options';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("FormulasConstructor");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("EmailOperations,AdditionalReportsAndDataProcessors,AttachableCommands,ReportMailing");
	Subsystem.LongDesc = NStr("en = '• Joint operation with report options, provided by the application and set up by users.
		|• Quick access toolbar to report options.
		|• Universal report option with quick settings, sending reports via email, report mailing setup, autosum, and other service features.
		|• Application interface for thin setting of report appearance.';");
#EndRegion
	
#Region ObjectsVersioning
	Subsystem = AddSubsystem("ObjectsVersioning");
	Subsystem.Synonym = NStr("en = 'Object versioning';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Storing and viewing the history of changes in directories and documents (user who made the changes, change time and the nature of change up to object attributes and attributes of its tables).
		|• Comparing arbitrary object versions.
		|• View and rollback to the previously saved object version.';");
#EndRegion
	
#Region Interactions
	Subsystem = AddSubsystem("Interactions");
	Subsystem.Synonym = NStr("en = 'Business interactions';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ContactInformation,ItemOrderSetup,AttachableCommands,FullTextSearch,EmailOperations,FilesOperations,Properties,SendSMSMessage");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("AdditionalReportsAndDataProcessors,AttachableCommands");
	Subsystem.LongDesc = NStr("en = '• Planning, registering, and organizing interactions: email, calls, meetings, and SMS messages.
		|• Storing all interactions and their contacts in the infobase.
		|• Operations with interaction results.';");
#EndRegion
	
#Region AddIns
	Subsystem = AddSubsystem("AddIns");
	Subsystem.Synonym = NStr("en = 'Add-ins';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Import third-party add-ins into the application without the need to update it.
		|• Install and attach add-ins using the API.
		|• Automatically receive and update add-ins from the 1C website (when used together with the Online Support Library).';");
#EndRegion
	
#Region BarcodeGeneration
	Subsystem = AddSubsystem("BarcodeGeneration");
	Subsystem.Synonym = NStr("en = 'Barcode generation';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("AddIns");
	Subsystem.LongDesc = NStr("en = '• Application interface to generate barcode images %1.';");
	Codes = "EAN8, EAN13, EAN128, Code39, Code93, Code128, Code16k, PDF417, ITF14, RSS14, EAN13AddOn2, EAN13AddOn5, QR, GS1DataBarExpandedStacked, Datamatrix";
	Subsystem.LongDesc = StrReplace(Subsystem.LongDesc, "%1",Codes);
#EndRegion
	
#Region WorkSchedules
	Subsystem = AddSubsystem("WorkSchedules");
	Subsystem.Synonym = NStr("en = 'Work schedules';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("CalendarSchedules");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Storing info on business calendars that are used in the enterprise.
		|• Getting a date that comes after the specified number of days on the specified calendar and another application interface.';");
#EndRegion
	
#Region BatchEditObjects
	Subsystem = AddSubsystem("BatchEditObjects");
	Subsystem.Synonym = NStr("en = 'Bulk edit';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Bulk edit of attributes and tables of the application objects (catalogs, documents and so on).
		|• The ability to change values of additional attributes and information records.
		|• Considering the preset application rules that prohibit editing applied object attributes.';");
#EndRegion
	
#Region PeriodClosingDates
	Subsystem = AddSubsystem("PeriodClosingDates");
	Subsystem.Synonym = NStr("en = 'Period-end closing dates';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Locking changes to any data (documents, register records, catalog items, and so on) that was entered before the specified date.
		|• Flexible setting of one common date of prohibition to change for all applied objects in general or several dates by sections and/or separate objects of accounting sections.';");
#EndRegion
	
#Region AdditionalReportsAndDataProcessors
	Subsystem = AddSubsystem("AdditionalReportsAndDataProcessors");
	Subsystem.Synonym = NStr("en = 'Additional reports and data processors';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("Print,ReportsOptions,BatchEditObjects");
	Subsystem.LongDesc = NStr("en = '• Attaching additional (external) reports and data processors to the application without changing the configuration.
		|• Linking additional reports and data processors to specific types of objects or sections of the command interface.
		|• Routine execution of data processors on schedule.
		|• Tools for administrating the list of additional reports and data processors.';");
#EndRegion
	
#Region UsersSessions
	Subsystem = AddSubsystem("UsersSessions");
	Subsystem.Synonym = NStr("en = 'Closing user sessions';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Viewing and completing active application sessions.
		|• Temporarily locking user work in the application, prohibiting scheduled jobs.';");
#EndRegion
	
#Region ImportDataFromFile
	Subsystem = AddSubsystem("ImportDataFromFile");
	Subsystem.Synonym = NStr("en = 'Import data from spreadsheets';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("AdditionalReportsAndDataProcessors,BatchEditObjects");
	Subsystem.LongDesc = NStr("en = '• Importing tabular data to catalogs and document tables.';");
#EndRegion
	
#Region UserNotes
	Subsystem = AddSubsystem("UserNotes");
	Subsystem.Synonym = NStr("en = 'Notes';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Electronic replacement of stickers on the edges of the monitor that can be used without closing your application window.
		|• Quick list of notes on your desktop, list of notes on the subject, common list.
		|• Various colors and design of note text, inserting pictures into notes.';");
#EndRegion
	
#Region ObjectAttributesLock
	Subsystem = AddSubsystem("ObjectAttributesLock");
	Subsystem.Synonym = NStr("en = 'Object attribute lock';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Application interface to check the required filling of some object attributes that define character of this object (they are conditionally called ""key"" attributes).
		|• The prohibition to edit ""key"" attributes of the saved objects.
		|• Check if it is possible to change ""key"" attributes by the user who has rights to do it.';");
#EndRegion
	
#Region PersonalDataProtection
	Subsystem = AddSubsystem("PersonalDataProtection");
	Subsystem.Synonym = NStr("en = 'Personal data protection';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("Print,AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Supporting the requirements of the Federal Law No. 152-FZ (""On personal data"").
		|• Managing events of access to personal data (setting event usage, getting relevant status of using events, preparing system setting form).
		|• Classifying personal data by areas.
		|• Considering consents to process personal data.
		|• Hiding subject personal data.';");
#EndRegion
	
#Region InformationOnStart
	Subsystem = AddSubsystem("InformationOnStart");
	Subsystem.Synonym = NStr("en = 'Startup notifications';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Displaying various information (for example, advertisements) on the application startup.';");
#EndRegion
	
#Region ODataInterface
	Subsystem = AddSubsystem("ODataInterface");
	Subsystem.Synonym = NStr("en = 'OData standard interface';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Setting automatic REST service for request and data update.';");
#EndRegion
	
#Region CalendarSchedules
	Subsystem = AddSubsystem("CalendarSchedules");
	Subsystem.Synonym = NStr("en = 'Calendar schedules';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Storing info on calendar schedules that are used in the enterprise.';");
#EndRegion

#Region FormulasConstructor
	Subsystem = AddSubsystem("FormulasConstructor");
	Subsystem.Synonym = NStr("en = 'Formula editor';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("NationalLanguageSupport");
	Subsystem.LongDesc = NStr("en = '• Provides a convenient form for editing formulas.';");
#EndRegion
	
#Region ContactInformation
	Subsystem = AddSubsystem("ContactInformation");
	Subsystem.Synonym = NStr("en = 'Contact information';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ItemOrderSetup,AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("AddressClassifier");
	Subsystem.LongDesc = NStr("en = '• Add attributes to arbitrary catalogs and attribute documents to enter contact information: postal addresses, email addresses, phone numbers, and so on.
		|• Check automatically or manually if addresses are correct (when used together with the ""Address classifier"" subsystem).
		|• Provide the classifier of countries of the world (ARCC).';");
#EndRegion
	
#Region AccountingAudit
	Subsystem = AddSubsystem("AccountingAudit");
	Subsystem.Synonym = NStr("en = 'Data integrity';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,Users,AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ToDoList,AttachableCommands");
	Subsystem.LongDesc = NStr("en = '• Validate infobase data using arbitrary applied rules.
		|• Identify issues and display ways to fix them for various user categories.
		|• Replace similar systems in ERP, ASDS, Enterprise Accounting 3.0, and Governmental Accounting.';");
#EndRegion
	
#Region UserMonitoring
	Subsystem = AddSubsystem("UserMonitoring");
	Subsystem.Synonym = NStr("en = 'User monitoring';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,ReportMailing");
	Subsystem.LongDesc = NStr("en = '• Generate reports on user activity and operations, on the duration of scheduled jobs, and on critical records in the event log.';");
#EndRegion
	
#Region MachineReadableLettersOfAuthority
	Subsystem = AddSubsystem("MachineReadableLettersOfAuthority");
	Subsystem.Synonym = NStr("en = 'Machine-readable letters of authority (unified format)';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems(
		"ContactInformation,
		|Print,
		|AttachableCommands,
		|GetFilesFromInternet,
		|FilesOperations,
		|ObjectPresentationDeclension,
		|DigitalSignature");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Application and user interface for operations with machine-readable letters of authority in the format that corresponds to Order of the Ministry for Digital Development, Communications and Mass Media of the Russian Federation No. 857 dated 08/18/2021 ""On approving standardized format for letters of authority required to use a qualified digital signature"".
		|• Registration of letters of authority in the distributed ledger of the Federal Tax Service.';");
#EndRegion
	
#Region NationalLanguageSupport
	Subsystem = AddSubsystem("NationalLanguageSupport");
	Subsystem.Synonym = NStr("en = 'National Language Support';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• With National Language Support, your applications can support multiple languages.
		|It enhances the functionality of other subsystems that have multilingual data.
		|Each subsystem in National Language Support just complements its main subsystem.
		|Which means that the ""Print"" subsystem in National Language Support provides no printing features. To print a document, you need the main ""Print"" subsystem.';");
	
	Subsystem = AddSubsystem("NationalLanguageSupport.Core");
	Subsystem.Parent = "NationalLanguageSupport";
	Subsystem.Synonym = NStr("en = 'Core: National Language Support';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = 'The core mechanisms that support other National Language Support subsystems.';");
	
	Subsystem = AddSubsystem("NationalLanguageSupport.Print");
	Subsystem.Parent = "NationalLanguageSupport";
	Subsystem.Synonym = NStr("en = 'Print: National Language Support';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("Print,"
		+ "NationalLanguageSupport.Core");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Print out documents in multiple languages.';");
	
	Subsystem = AddSubsystem("NationalLanguageSupport.TextTranslation");
	Subsystem.Parent = "NationalLanguageSupport";
	Subsystem.Synonym = NStr("en = 'Translator: National Language Support';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("NationalLanguageSupport.Core,GetFilesFromInternet");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Translate texts with online services.';");
#EndRegion
	
#Region UserReminders
	Subsystem = AddSubsystem("UserReminders");
	Subsystem.Synonym = NStr("en = 'User reminders';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Entering personal reminders in the application for the required time.
		|• Connecting reminders to catalogs, documents, and chats.';");
#EndRegion
	
#Region ItemOrderSetup
	Subsystem = AddSubsystem("ItemOrderSetup");
	Subsystem.Synonym = NStr("en = 'Item order';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Setting order of arbitrary list items using the Up and Down buttons.';");
#EndRegion
	
#Region ApplicationSettings
	Subsystem = AddSubsystem("ApplicationSettings");
	Subsystem.Synonym = NStr("en = 'Application settings';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Ready workstations (panels) for the Administration section.
		|• Adjusting administration panel content to the current application mode.';");
#EndRegion
	
#Region DataExchange
	Subsystem = AddSubsystem("DataExchange");
	Subsystem.Synonym = NStr("en = 'Data exchange';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ConfigurationUpdate,ScheduledJobs,GetFilesFromInternet,ObjectsPrefixes");
	Subsystem.LongDesc = NStr("en = '• Application interface and ready workstations to organize collaboration in distributed infobase and to synchronize data with other applications.
		|• Data synchronization upon request and in auto mode on schedule.
		|• Connect via different communication links: local or network directory, email, FTP resource or via the Internet (including data synchronization with cloud applications).
		|• Flexible setup of data synchronization rules between applications, assistant to map similar data.
		|• Tools for monitoring and diagnosing data synchronization.
		|• The ability to develop exchange plans with or without data conversion rules, convenient debugging of event handlers for conversion rules in Designer.
		|• Automatic update of subordinate DIB node configuration (when used together with the ""Configuration update"" subsystem).';");
#EndRegion
	
#Region IBVersionUpdate
	Subsystem = AddSubsystem("IBVersionUpdate");
	Subsystem.Synonym = NStr("en = 'Infobase version update';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Perform initial population and update of the infobase data when a configuration version changes.
		|• Display details of the new version updates.
		|• Provide API to run exclusive, real-time and deferred update handlers.';");
#EndRegion
	
#Region ConfigurationUpdate
	Subsystem = AddSubsystem("ConfigurationUpdate");
	Subsystem.Synonym = NStr("en = 'Configuration update';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("UsersSessions");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("EmailOperations,SoftwareLicenseCheck,AccountingAudit");
	Subsystem.LongDesc = NStr("en = '• Automatically update the configuration (without opening Designer) on demand, at scheduled time, or upon exiting the application.
		|• Check for configuration updates and download them via the Internet (manually or on schedule).
		|• Update the application from files in local or network directories.
		|• Apply main configuration changes to the database configuration.';");
#EndRegion
	
#Region Companies
	Subsystem = AddSubsystem("Companies");
	Subsystem.Synonym = NStr("en = 'Companies';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Application interface to get company data.';");
#EndRegion
	
#Region Conversations
	Subsystem = AddSubsystem("Conversations");
	Subsystem.Synonym = NStr("en = 'Conversations';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Enable the Internet service of the collaboration system so that application users can communicate with each other online, create topic conversations, and correspond on specific documents, for example, orders, sales, or counterparties.
		|• Enable chats in messengers and social networks to communicate with customers.';");
#EndRegion
	
#Region SendSMSMessage
	Subsystem = AddSubsystem("SendSMSMessage");
	Subsystem.Synonym = NStr("en = 'Text messaging';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("GetFilesFromInternet");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Bulk email and text messaging. SMS delivery status.';");
#EndRegion
	
#Region DocumentRecordsReport
	Subsystem = AddSubsystem("DocumentRecordsReport");
	Subsystem.Synonym = NStr("en = 'Document record history';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AttachableCommands,ReportsOptions");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Allows to view register records of documents that, when posted, reflect changes in registers.';");
#EndRegion
	
#Region PerformanceMonitor
	Subsystem = AddSubsystem("PerformanceMonitor");
	Subsystem.Synonym = NStr("en = 'Performance monitor';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Evaluating integral system productivity by APDEX method.
		|• It simplifies and automates collection of information on the execution time of each key operation.
		|• Tools to analyze measurement results.
		|• Automatic export of performance indicators.';");
#EndRegion
	
#Region Print
	Subsystem = AddSubsystem("Print");
	Subsystem.Synonym = NStr("en = 'Print';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AttachableCommands,FormulasConstructor");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("FilesOperations,AdditionalReportsAndDataProcessors,EmailOperations,SourceDocumentsOriginalsRecording");
	Subsystem.LongDesc = NStr("en = '• Application interface and ready workstation to generate print forms of arbitrary applied objects.
		|• Output of print forms as spreadsheet documents and office documents Office Open XML (docx).
		|• Send print forms via email, saving them to the computer or in attachments (when using together with the ""Attachments"" subsystem).
		|• Attach external print forms and printing them together with main print forms (when using together with the ""Additional reports and data processors"" subsystem).
		|• Output the QR code picture to the print form by a given text string.';");
#EndRegion
	
#Region AttachableCommands
	Subsystem = AddSubsystem("AttachableCommands");
	Subsystem.Synonym = NStr("en = 'Attachable commands';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,AdditionalReportsAndDataProcessors,Print");
	Subsystem.LongDesc = NStr("en = '• Application interface to output dynamically attachable commands and integrations with extensions.
	|• Adapting command components to types of selected documents in document journals and to object attribute values.';");
#EndRegion
	
#Region DuplicateObjectsDetection
	Subsystem = AddSubsystem("DuplicateObjectsDetection");
	Subsystem.Synonym = NStr("en = 'Duplicate cleaner';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Search and clean up duplicate catalog items.';");
#EndRegion
	
#Region FullTextSearch
	Subsystem = AddSubsystem("FullTextSearch");
	Subsystem.Synonym = NStr("en = 'Full-text search';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Setting and full text search by all application data.';");
#EndRegion
	
#Region GetFilesFromInternet
	Subsystem = AddSubsystem("GetFilesFromInternet");
	Subsystem.Synonym = NStr("en = 'Network download';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Application interface to get files from the Internet.
		|• Getting a file from the network on the client.
		|• Saving files to client computer and to the infobase.
		|• Requesting and storing proxy server parameters.';");
#EndRegion
	
#Region Users
	Subsystem = AddSubsystem("Users");
	Subsystem.Synonym = NStr("en = 'Users';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("AccessManagement,ContactInformation");
	Subsystem.LongDesc = NStr("en = '• Keep the list of users that work in the application.
		|• Keep the list of users that have restricted access to specialized workstations (for example, ""My orders"", ""Respondent questionnaires"", ""Create requests"", and so on).
		|• Set up access rights of users and external users (when implementing together with the ""Access management"" subsystem it is done using the ""Access management"" subsystem tools).
		|• Grouping the list of users (and external users).
		|• Clear and copy settings of reports, forms, desktop, command interface sections, favorites, spreadsheet document printing and other personal settings of users and external users.';");
#EndRegion
	
#Region ObjectsPrefixes
	Subsystem = AddSubsystem("ObjectsPrefixes");
	Subsystem.Synonym = NStr("en = 'Object prefixes';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Automatic assignment of prefixes to objects considering application settings.
		|• Object prefixation broken down by infobases and the Companies catalog items.
		|• Application interface to reprefix catalogs and documents when changing infobase prefix.';");
#EndRegion
	
#Region SoftwareLicenseCheck
	Subsystem = AddSubsystem("SoftwareLicenseCheck");
	Subsystem.Synonym = NStr("en = 'Licensed update verification';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Application and user interface to confirm that configuration update was obtained legally.';");
#EndRegion
	
#Region SecurityProfiles
	Subsystem = AddSubsystem("SecurityProfiles");
	Subsystem.Synonym = NStr("en = 'Security profiles';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Operations with infobase security profiles
		|• Setting permissions to use external resources.';");
#EndRegion
	
#Region SaaSOperations
	Subsystem = AddSubsystem("SaaSOperations");
	Subsystem.Synonym = NStr("en = 'SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("DataExchange,ScheduledJobs,UsersSessions");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = 'The ""SaaS"" subsystem contains core required for all applications designed to work in SaaS.
		|It also includes a number of subsystems not intended for independent use.
		|They must be included in the configuration only together with the matching main subsystem.
		|For example if the ""Users"" subsystem is marked for integration, the ""Users SaaS"" subsystem must be marked too.';");
	
	Subsystem = AddSubsystem("SaaSOperations.CoreSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("en = 'Core SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("SaaSOperations.IBVersionUpdateSaaS,SaaSOperations.UsersSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = 'Includes a set of auxiliary functionalities used by other subsystems from SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.AddInsSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("en = 'Add-ins SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AddIns,"
		+ "SaaSOperations.CoreSaaS,"
		+ "SaaSOperations.IBVersionUpdateSaaS,"
		+ "SaaSOperations.UsersSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = 'Provides the ability to connect and use add-ins in an application running in SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.AdditionalReportsAndDataProcessorsSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("en = 'Additional reports and data processors SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AdditionalReportsAndDataProcessors,SecurityProfiles,"
		+ "SaaSOperations.CoreSaaS,"
		+ "SaaSOperations.IBVersionUpdateSaaS,"
		+ "SaaSOperations.UsersSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = 'Provides the ability to connect and use additional reports and data processors in an application running in SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.DataExchangeSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("en = 'Data exchange SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems(
		"DataExchange,"
		+ "SaaSOperations.CoreSaaS,"
		+ "SaaSOperations.IBVersionUpdateSaaS,"
		+ "SaaSOperations.UsersSaaS,"
		+ "SaaSOperations.FilesOperationsSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = 'Provides functionality related to the exchange of information between different applications when executed in SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.IBVersionUpdateSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("en = 'Infobase version update SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("IBVersionUpdate,UsersSessions,"
		+ "SaaSOperations.CoreSaaS,SaaSOperations.UsersSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = 'Provides functionality connected with updating infobase versions when working in SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.UsersSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("en = 'Users SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("Users,"
		+ "SaaSOperations.CoreSaaS,SaaSOperations.IBVersionUpdateSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = 'Provides user experience for an application that runs in SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.FilesOperationsSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("en = 'File management SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("FilesOperations,FullTextSearch,"
		+ "SaaSOperations.CoreSaaS,"
		+ "SaaSOperations.IBVersionUpdateSaaS,"
		+ "SaaSOperations.UsersSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = 'Provides the ability to export to a file and import from an application data file running in SaaS.';");
	
	Subsystem = AddSubsystem("SaaSOperations.AccessManagementSaaS");
	Subsystem.Parent = "SaaSOperations";
	Subsystem.Synonym = NStr("en = 'Access management SaaS';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("AccessManagement,"
		+ "SaaSOperations.CoreSaaS,"
		+ "SaaSOperations.IBVersionUpdateSaaS,"
		+ "SaaSOperations.UsersSaaS");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = 'Allows you to configure user rights for arbitrary items of the application data (items of catalogs,
		|documents, register records, business processes, tasks, and so on) of the application running in SaaS.';");
	
#EndRegion
	
#Region EmailOperations
	Subsystem = AddSubsystem("EmailOperations");
	Subsystem.Synonym = NStr("en = 'Email management';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Application interface to send and receive emails.
		|• Keeping a list of accounts to work with email.
		|• Basic user interface to send messages.';");
#EndRegion
	
#Region FilesOperations
	Subsystem = AddSubsystem("FilesOperations");
	Subsystem.Synonym = NStr("en = 'File management';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,Properties,AccessManagement");
	Subsystem.LongDesc = NStr("en = '• Collaboratively manage files in a hierarchical folder structure.
		|• Store and grant access to file versions.
		|• Attach files from the file system, create files from templates, or get them from scanner.
		|• Digitally sign and encrypt files.
		|• Use the API and user interface to attach files to the application objects.
		|• Use multiple file owners without compromising performance under access restrictions at the record level.
		|• Collaboratively edit, scan, digitally sign, and encrypt files.
		|• Use common functions and basic user interface to manage files and store them in volumes, as well as functions to support DIB and create initial image of an infobase.';");
#EndRegion
	
#Region ReportMailing
	Subsystem = AddSubsystem("ReportMailing");
	Subsystem.Synonym = NStr("en = 'Report distribution';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,ContactInformation,EmailOperations");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("AdditionalReportsAndDataProcessors,GetFilesFromInternet,FilesOperations,AccessManagement,BatchEditObjects");
	Subsystem.LongDesc = NStr("en = '• Email reports to a user list.
		|• Publish reports on FTP, in network directories, or in folders of the ""File management"" subsystem.
		|• Send emails manually or set up a schedule.';");
#EndRegion
	
#Region ScheduledJobs
	Subsystem = AddSubsystem("ScheduledJobs");
	Subsystem.Synonym = NStr("en = 'Scheduled jobs';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Outputting list and setting scheduled job parameters (schedule, startup, stop).';");
#EndRegion
	
#Region IBBackup
	Subsystem = AddSubsystem("IBBackup");
	Subsystem.Synonym = NStr("en = 'Infobase backup';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("UsersSessions");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Saving reserve file infobase copies upon request or on the specified schedule.
		|• Restoring file infobase from the copy.
		|• Notifying that it is required to set up backups (also in client/server mode).';");
#EndRegion
	
#Region Properties
	Subsystem = AddSubsystem("Properties");
	Subsystem.Synonym = NStr("en = 'Properties';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ObjectAttributesLock");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Adding additional properties to arbitrary documents and catalogs.
		|• Outputting property values in any reports and dynamic lists.
		|• Storing properties separately both in the object itself (additional attributes) and outside of owner object in a separate information register (additional info).
		|• The ability to set similar properties for different objects, required properties and other server features.';");
#EndRegion
	
#Region ObjectPresentationDeclension
	Subsystem = AddSubsystem("ObjectPresentationDeclension");
	Subsystem.Synonym = NStr("en = 'Declension tool';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("GetFilesFromInternet");
	Subsystem.LongDesc = NStr("en = '• Automatic declension of object presentations with available manual user correction.';");
#EndRegion
	
#Region SubordinationStructure
	Subsystem = AddSubsystem("SubordinationStructure");
	Subsystem.Synonym = NStr("en = 'Hierarchy';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Display of information on parent and child documents for the selected document and their interaction structure.';");
#EndRegion
	
#Region ToDoList
	Subsystem = AddSubsystem("ToDoList");
	Subsystem.Synonym = NStr("en = 'To-do list';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Display of user to-dos on the desktop (new emails, tasks, requests, unapproved orders, and so on).';");
#EndRegion
	
#Region MarkedObjectsDeletion
	Subsystem = AddSubsystem("MarkedObjectsDeletion");
	Subsystem.Synonym = NStr("en = 'Marked object deletion';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Deletion of objects marked for deletion. With integrity control (check of references to the objects being deleted from other objects).
		|• Scheduled background deletion.';");
#EndRegion
	
#Region AccessManagement
	Subsystem = AddSubsystem("AccessManagement");
	Subsystem.Synonym = NStr("en = 'Access management';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Individual and group setting of user access rights using profiles and access groups.
		|• Setting access right restrictions on the record level: for separate infobase data items (items of catalogs, documents, register records, and so on.)
		|• Report on the rights of a user or a user group of interest.
		|• There are two options for integration into application: usual and simplified.
		|The usual mode of setting access rights is designed for multi-user applications, where, as a rule, group right setting is performed on the access group basis.
		|In the simplified mode, rights are set individually for each user.
		|The second mode is designed for configuration with a small number of users, each of them having his own set of rights.';");
#EndRegion
	
#Region TotalsAndAggregatesManagement
	Subsystem = AddSubsystem("TotalsAndAggregatesManagement");
	Subsystem.Synonym = NStr("en = 'Totals and aggregates';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Administration of totals and turnover accumulation registers
		|• Scheduled operation execution on shifting the limit of totals, recalculation and update of aggregates (on schedule and when closing the application).';");
#EndRegion
	
#Region SourceDocumentsOriginalsRecording
	Subsystem = AddSubsystem("SourceDocumentsOriginalsRecording");
	Subsystem.Synonym = NStr("en = 'Source document tracking';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("ItemOrderSetup,AttachableCommands,Print,ObjectsPrefixes,AdditionalReportsAndDataProcessors");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.LongDesc = NStr("en = '• Record whether signed originals of outgoing or incoming documents are available.
	|• Store and provide current states of source document originals.';");
#EndRegion
	
#Region MonitoringCenter
	Subsystem = AddSubsystem("MonitoringCenter");
	Subsystem.Synonym = NStr("en = 'Monitoring center';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("PerformanceMonitor");
	Subsystem.LongDesc = NStr("en = '• Collects impersonal configuration usage statistics
		|• Transfers the impersonal statistics to the unified quality control center.';");
#EndRegion
	
#Region MessageTemplates
	Subsystem = AddSubsystem("MessageTemplates");
	Subsystem.Synonym = NStr("en = 'Message templates';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("Interactions,AdditionalReportsAndDataProcessors,Print,SendSMSMessage,EmailOperations,FilesOperations");
	Subsystem.LongDesc = NStr("en = '• Sending emails and SMS messages generated on the basis of catalogs or documents and according to prearranged message templates.
		|• Developing message templates for mail and SMS messages.
		|• Application interface to send standard notifications created according to template as emails and SMS messages.';");
#EndRegion
	
#Region DigitalSignature
	Subsystem = AddSubsystem("DigitalSignature");
	Subsystem.Synonym = NStr("en = 'Digital signature';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ContactInformation,AddressClassifier,Print,UserReminders,ReportsOptions,GetFilesFromInternet");
	Subsystem.LongDesc = NStr("en = '• Application and user interface to work with cryptography tools: digital signature and signature check.
		|• Send applications to 1C Certificate authority to issue a certificate of encrypted and certified digital signature and install them on the computer.';");
#EndRegion
	
#Region DSSElectronicSignatureService
	Subsystem = AddSubsystem("DSSElectronicSignatureService");
	Subsystem.Synonym = NStr("en = 'DSS service digital signature';");
	Subsystem.DependsOnSubsystems = DependenceOnSubsystems("DigitalSignature,GetFilesFromInternet,AttachableCommands");
	Subsystem.ConditionallyDependsOnSubsystems = DependenceOnSubsystems("ReportsOptions,AttachableCommands");
	Subsystem.LongDesc = NStr("en = '• Programming and user interface for managing digital signatures and completing cryptography operations with cryptographic keys stored on the CryptoPro DSS servers.
		|• It adds new features to the ""Digital signature"" subsystem and enables you to use keys and certificates stored in the DSS server';");
#EndRegion
	
	Return Subsystems;
	
EndFunction

#EndRegion

#Region Private

// Returns:
//  ValueTable:
//    * Name - String
//    * Synonym  - String
//    * Required - Boolean
//    * DependsOnSubsystems - Array of String
//    * ConditionallyDependsOnSubsystems - Array of String
//    * LongDesc - String
//    * Check - Boolean
//    * Parent - String
// 
Function InitializeTable()
	
	Subsystems = New ValueTable;
	Subsystems.Columns.Add("Name");
	Subsystems.Columns.Add("Synonym");
	Subsystems.Columns.Add("Required");
	Subsystems.Columns.Add("DependsOnSubsystems");
	Subsystems.Columns.Add("ConditionallyDependsOnSubsystems");
	Subsystems.Columns.Add("LongDesc");
	Subsystems.Columns.Add("Check");
	Subsystems.Columns.Add("Parent");
	Return Subsystems;
	
EndFunction

Function DependenceOnSubsystems(SubsystemsNames)
	
	If IsBlankString(SubsystemsNames) Then
		DependsOnSubsystems = New Array;
	Else
		DependsOnSubsystems = StrSplit(SubsystemsNames, ", " + Chars.LF, False);
	EndIf;
	Return DependsOnSubsystems;
	
EndFunction

// Parameters:
//  SubsystemName - String
//
// Returns:
//  ValueTableRow of See InitializeTable 
// 
Function AddSubsystem(SubsystemName)
	
	NewRow = Subsystems.Add();
	NewRow.Name = SubsystemName;
	NewRow.Required = RequiredSubsystems[SubsystemName] <> Undefined;
	NewRow.Check = NewRow.Required;
	
	Return NewRow;
	
EndFunction

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf