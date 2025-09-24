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

// It is called after creation on the server, but before opening the DataSigning and DataDecryption forms.
// It is used for additional actions that require
// a server call not to call server once again.
//
// Parameters:
//  Operation          - String - the Signing or Decryption string.
//
//  InputParameters  - Arbitrary - AdditionalActionsParameters property value
//                      of the DataDetails parameter of the Sign and Decrypt methods
//                      of the ClientDigitalSignature common module.
//                      
//  OutputParametersSet - Arbitrary - arbitrary data that was returned
//                      from the common module procedure of the same name on the server.
//                      DigitalSignatureOverridable.
//
Procedure BeforeOperationStart(Operation, InputParameters, OutputParametersSet) Export
	
	
	
EndProcedure

// It is called from the CertificateCheck form if additional checks were added when creating the form.
//
// Parameters:
//  Parameters - Structure:
//   * WaitForContinue   - Boolean - a return value. If True, an additional check
//                            will be performed asynchronously and it will continue after the notification is executed.
//                            The initial value is False.
//   * Notification           - NotifyDescription - a data processor that needs to be called for continuation
//                              after the additional check was performed asynchronously.
//   * Certificate           - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - a certificate being checked.
//   * Validation             - String - a check name, added in the OnCreateFormCertificateCheck procedure
//                              of the DigitalSignatureOverridable common module.
//   * CryptoManager - CryptoManager - a prepared crypto manager to
//                              perform a check.
//                         - Undefined - if standard checks are disabled in procedure
//                              OnCreateFormCertificateCheck of the DigitalSignatureOverridable common module.
//   * ErrorDescription       - String - a return value. An error description received when performing the check.
//                              User can see the details by clicking the result picture.
//   * IsWarning    - Boolean - a return value. A picture kind is Error/Warning,
//                            the initial value is False.
//   * Password   - String - a password entered by the user.
//                   - Undefined - if the EnterPassword property is set to False in the
//                            OnCreateFormCertificateCheck procedure of the DigitalSignatureOverridable common module.
//   * ChecksResults   - Structure:
//      * Key     - String - a name of a standard or an additional check, or an error name. The property key
//                 containing an error, contains the check name with the Error ending.
//      * Value - Undefined - the check was not performed (ErrorDetails is still Undefined).
//                 - Boolean - an additional check execution result.
//                 - String - when a property key contains the Error ending and check result is False,
//                 contains details of the error.
//
Procedure OnAdditionalCertificateCheck(Parameters) Export
	
	// _Demo Example Start
	_DemoStandardSubsystemsClient.OnAdditionalCertificateCheck(Parameters);
	// _Demo Example End
	
EndProcedure

// It is called when opening the instruction on how to work with digital signature and encryption apps.
//
// Parameters:
//  Section - String - the initial value of BookkeepingAndTaxAccounting.
//                    You can specify AccountingForPublicInstitutions.
//
Procedure OnDetermineArticleSectionAtITS(Section) Export
	
	
	
EndProcedure

// Called after the interactive addition to the digital signature certificate catalog.
//
// Parameters:
//  Parameters - Structure:
//    * Certificates - Array of Structure:
//     ** NewCertificate  - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - The added certificate.
//     ** OldCertificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates, Undefined - The found certificate with 
//             similar subject properties that is subject to replacement.
//
Procedure AfterAddingElectronicSignatureCertificatesToDirectory(Parameters) Export
	
	// _Demo Example Start
	_DemoStandardSubsystemsClient.AfterAddingElectronicSignatureCertificatesToDirectory(Parameters);
	// _Demo Example End
	
EndProcedure

#EndRegion
