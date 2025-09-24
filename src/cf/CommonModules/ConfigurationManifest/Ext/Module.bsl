﻿
#Region Public

// Generates a configuration manifest.
// The manifest describes information about the configuration to other service add-ins.
//
// Returns:
//	XDTODataObject - {http://www.1c.ru/1cFresh/Application/Manifest/a.b.c.d}ApplicationInfo.
// 
Function GenerateConfigurationManifest() Export
	
	Manifest = XDTOFactory.Create(ConfigurationManifestType());
	
	Manifest.Name = Metadata.Name;
	Manifest.Presentation = Metadata.Synonym;
	Manifest.Version = Metadata.Version;
	Manifest.PlatformVersion = Common.CommonCoreParameters().MinPlatformVersion1;
	
	AdvancedInformation = New Array();
	
	SaaSOperationsCTL.OnGenerateConfigurationManifest(AdvancedInformation);
	
	For Each InformationElement In AdvancedInformation Do
		AddlInfo = Manifest.ExtendedInfo; // XDTOList
		AddlInfo.Add(InformationElement);
	EndDo;
	
	Return Manifest;
	
EndFunction

// Generates a configuration manifest, writes it to file, and puts the binary file data to a temporary storage.
// Wrapper for ConfigurationManifest.GenerateConfigurationManifest() to be called from long-running
//  operations or from external connections.
//
// Parameters:
//  StorageAddress - String - Address in temporary storage to save the manifest binary data to.
//  	
//
Procedure PlaceConfigurationManifestInTemporaryStorage(Val StorageAddress) Export
	
	Manifest = GenerateConfigurationManifest();
	
	TempFile = GetTempFileName("xml");
	
	WriteStream = New XMLWriter();
	WriteStream.OpenFile(TempFile);
	WriteStream.WriteXMLDeclaration();
	XDTOFactory.WriteXML(WriteStream, Manifest, , , , XMLTypeAssignment.Explicit);
	WriteStream.Close();
	
	PutToTempStorage(New BinaryData(TempFile), StorageAddress);
	
	DeleteFiles(TempFile);
	
EndProcedure

#EndRegion

#Region Private

Function ConfigurationManifestType(Val Package = Undefined)
	
	Return CreateXDTOType(Package, "ApplicationInfo");
	
EndFunction

Function ConfigurationManifestPackage()
	
	Return "http://www.1c.ru/1cFresh/Application/Manifest/" + ConfigurationManifestVersion();
	
EndFunction

Function ConfigurationManifestVersion()
	
	Return "1.0.0.1";
	
EndFunction

Function CreateXDTOType(Val PackageToUse, Val Type)
		
	If PackageToUse = Undefined Then
		PackageToUse = ConfigurationManifestPackage();
	EndIf;
	
	Return XDTOFactory.Type(PackageToUse, Type);
	
EndFunction

#EndRegion
