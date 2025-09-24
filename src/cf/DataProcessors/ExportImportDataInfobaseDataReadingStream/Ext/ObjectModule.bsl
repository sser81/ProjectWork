﻿#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurInitialization;
Var CurFileName;
Var ReaderStream;
Var CurrentObject;
Var TypeOfCurrentObject;
Var CurArtifacts; // See CurObjectArtifacts
Var SkipErrors;
Var Errors; // See Errors

#EndRegion

#Region Internal

Procedure OpenFile(Val FileName, IgnoreErrors = False) Export
	
	If CurInitialization Then
		
		Raise NStr("en = 'The object has already been initialized earlier.';");
		
	Else
		
		CurFileName = FileName;
	
		ReaderStream = New XMLReader();
		ReaderStream.OpenFile(FileName);
		ReaderStream.MoveToContent();

		If ReaderStream.NodeType <> XMLNodeType.StartElement
			Or ReaderStream.Name <> "Data" Then
			
			Raise(NStr("en = 'XML reading error. Invalid file format. Start of ""Data"" element is expected.';"));
		EndIf;
		
		TypeOfCurrentObject = ReaderStream.GetAttribute("Type");

		If Not ReaderStream.Read() Then
			Raise(NStr("en = 'XML reading error. File end is detected.';"));
		EndIf;
		
		SkipErrors = IgnoreErrors;
		Errors = New Array();
			
		CurInitialization = True;
		
	EndIf;
	
EndProcedure

// Read the infobase data object.
// 
// Returns: 
//  Boolean - True if the object has been read.
Function ReadInformationDatabaseDataObject() Export
	
	If ReaderStream.NodeType <> XMLNodeType.StartElement Then
		CurrentObject = Undefined;
		CurArtifacts = Undefined;
		Return False;
	EndIf;
		
	If ReaderStream.Name <> "DumpElement" Then
		Raise NStr("en = 'XML reading error. Invalid file format. Start of ""DumpElement"" element is expected.';");
	EndIf;
	
	ReaderStream.Read(); // <DumpElement>
	
	CurArtifacts = New Array();
	
	If ReaderStream.Name = "Artefacts" Then
		
		ReaderStream.Read(); // <Artefacts>
		While ReaderStream.NodeType <> XMLNodeType.EndElement Do
			
			ElementURI = ReaderStream.NamespaceURI;
			TagName = ReaderStream.Name;
			ArtifactType = XDTOFactory.Type(ElementURI, TagName);
			
			Try
				
				Artifact = XDTOFactory.ReadXML(ReaderStream, ArtifactType);
				
			Except
				
				CauseExceptionErrorWhenReadingData();
				
			EndTry;
			
			CurArtifacts.Add(Artifact);
			
		EndDo;
		ReaderStream.Read(); // </Artefacts>
		
	EndIf;
	
	If SkipErrors Then
		
		ObjectFragment = ReadFragmentOfStream();
		ObjectReadingStream = FragmentReadingStream(ObjectFragment);
		
		Try
			CurrentObject = XDTOSerializer.ReadXML(ObjectReadingStream);
		Except
			
			OriginalException = CloudTechnology.DetailedErrorText(ErrorInfo());
			XMLReadingErrorText = XMLReadingErrorText(ObjectFragment, OriginalException);
				
			Errors.Add(XMLReadingErrorText);
			ReaderStream.Read();	
			Return ReadInformationDatabaseDataObject();
			
		EndTry;
		
	Else
		
		Try
			CurrentObject = XDTOSerializer.ReadXML(ReaderStream);
		Except
			CauseExceptionErrorWhenReadingData();
		EndTry;
		
	EndIf;
	
	ReaderStream.Read(); // </DumpElement>
	
	Return True;
	
EndFunction

// Returns: 
//  CatalogObject, DocumentObject, Structure - Current object.
Function CurrentObject() Export
	
	Return CurrentObject;
	
EndFunction

// Returns: 
//  String - Current object type.
Function TypeOfCurrentObject() Export
	
	Return TypeOfCurrentObject;
	
EndFunction

// Current object artifacts.
// 
// Returns: 
//  Array of Arbitrary - Current object artifacts.
Function CurObjectArtifacts() Export
	
	Return CurArtifacts;
	
EndFunction

// Returns errors.
// 
// Returns: 
//  Array of String
Function Errors() Export
	Return Errors;
EndFunction

Procedure Close() Export
	
	ReaderStream.Close();
	
EndProcedure

#EndRegion

#Region Private

// Copying the current item from the XML reader stream.
//
// Parameters:
//	ReaderStream - XMLReader - an export reader stream.
//
// Returns:
//	String - an XML fragment text.
//
Function ReadFragmentOfStream()
	
	RecordingFragment = New XMLWriter;
	RecordingFragment.SetString();
	
	FragmentNodeName = ReaderStream.Name;
	
	RootNode = True;
	Try
		
		While Not (ReaderStream.NodeType = XMLNodeType.EndElement
				And ReaderStream.Name = FragmentNodeName) Do
			
			RecordingFragment.WriteCurrent(ReaderStream);
			
			If ReaderStream.NodeType = XMLNodeType.StartElement Then
				
				If RootNode Then
					NamespaceURIs = ReaderStream.NamespaceContext.NamespaceURIs();
					For Each URI In NamespaceURIs Do
						RecordingFragment.WriteNamespaceMapping(ReaderStream.NamespaceContext.LookupPrefix(URI), URI);
					EndDo;
					RootNode = False;
				EndIf;
				
				ElementNamespaceURIPrefixes = ReaderStream.NamespaceContext.NamespaceMappings();
				For Each KeyAndValue In ElementNamespaceURIPrefixes Do
					Prefix = KeyAndValue.Key;
					URI = KeyAndValue.Value;
					RecordingFragment.WriteNamespaceMapping(Prefix, URI);
				EndDo;
				
			EndIf;
			
			ReaderStream.Read();
		EndDo;
		
		RecordingFragment.WriteCurrent(ReaderStream);
		
		ReaderStream.Read();
	Except
		TextLR = StrTemplate(NStr("en = 'An error occurred when copying the original file fragment. Partially copied fragment:
                  |%1';"),
				RecordingFragment.Close());
		
		// @skip-check module-nstr-camelcase - Check error.
		WriteLogEvent(NStr("en = 'Data import/export. XML reading error';", 
			Common.DefaultLanguageCode()), EventLogLevel.Error, , , TextLR);
		Raise;
	EndTry;
	
	Particle = RecordingFragment.Close();
	
	Return Particle;
	
EndFunction

Function FragmentReadingStream(Val Particle)
	
	ReadingFragment = New XMLReader();
	ReadingFragment.SetString(Particle);
	ReadingFragment.MoveToContent();
	
	Return ReadingFragment;
	
EndFunction

Function XMLReadingErrorText(Val Particle, Val ErrorText)
	
	Return StrTemplate(NStr("en = 'An error occurred while reading data from file %1: error reading fragment
              |
              |%2
              |
              |error:
              |
              |%3.';"),
		CurFileName,
		Left(Particle, 10000),
		ErrorText);
	
EndFunction

Procedure CauseExceptionErrorWhenReadingData()
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(CurFileName);
	ReaderStream.MoveToContent();
	ReaderStream.Read();
	
	While ReadProblematicObjectOfInformationBase() Do
		
	EndDo;
	
EndProcedure

Function ReadProblematicObjectOfInformationBase()
	
	If ReaderStream.NodeType <> XMLNodeType.StartElement Then
		CurrentObject = Undefined;
		CurArtifacts = Undefined;
		Return False;
	EndIf;
	
	If ReaderStream.Name <> "DumpElement" Then
		Raise NStr("en = 'XML reading error. Invalid file format. Start of ""DumpElement"" element is expected.';");
	EndIf;
	
	ReaderStream.Read(); // <DumpElement>
	
	If ReaderStream.Name = "Artefacts" Then
		
		ReaderStream.Read(); // <Artefacts>
		While ReaderStream.NodeType <> XMLNodeType.EndElement Do
			
			ElementURI = ReaderStream.NamespaceURI;
			TagName = ReaderStream.Name;
			ArtifactType = XDTOFactory.Type(ElementURI, TagName);
			
			ArtifactFragment = ReadFragmentOfStream();
			ArtifactReadingStream = FragmentReadingStream(ArtifactFragment);
			Try
				Artifact = XDTOFactory.ReadXML(ArtifactReadingStream, ArtifactType);
			Except
				OriginalException = CloudTechnology.ShortErrorText(ErrorInfo());
				Raise XMLReadingErrorText(ArtifactFragment, OriginalException);
			EndTry;
			
		EndDo;
		ReaderStream.Read(); // </Artefacts>
		
	EndIf;
	
	ObjectFragment = ReadFragmentOfStream();
	ObjectReadingStream = FragmentReadingStream(ObjectFragment);
		
	Try
		CurrentObject = XDTOSerializer.ReadXML(ObjectReadingStream);
	Except
		OriginalException = CloudTechnology.ShortErrorText(ErrorInfo());
		Raise XMLReadingErrorText(ObjectFragment, OriginalException);
	EndTry;
	
	ReaderStream.Read(); // </DumpElement>
	
	Return True;
	
EndFunction

#EndRegion

#Region Initialize

CurInitialization = False;

#EndRegion

#EndIf