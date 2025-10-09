&AtClient
Procedure OnOpen(Cancel)

	If Not ValueIsFilled(RabbitMQURL) Then
		RabbitMQURL = "localhost";
	EndIf;

	If Not ValueIsFilled(RabbitMQPort) Then
		RabbitMQPort = 5672;
	EndIf;

	If Not ValueIsFilled(RabbitMQLogin) Then
		RabbitMQLogin = "guest";
	EndIf;

	If Not ValueIsFilled(RabbitMQPassword) Then
		RabbitMQPassword = "guest";
	EndIf;

EndProcedure

#Region ConnectionInitializationOfComponent

&AtServer
Procedure ConnectionToComponent(ComponentConnectionSuccessful = Undefined)

	TempStorageURL = GetURLTemplateComposition(ThisObject.UUID);
	ComponentConnectionSuccessful = AttachAddIn(TempStorageURL, "BITERP", AddInType.Native);

	Message(NStr("ru = 'Компонента подключена!'; en = 'Component connection successful!'"));

EndProcedure

&AtServer
Function GetComponent()

	ComponentClient = Undefined;
	If Not InitializationComponentClientServer(ComponentClient) Then

		ConnectionToComponent();
		InitializationComponentClientServer(ComponentClient);
	EndIf;

	Return ComponentClient;

EndFunction

#EndRegion

&AtClient
Procedure GetFromDocflow(Command)

	GetAtServer("AccSystem");

EndProcedure

&AtClient
Procedure GetFromAccSystem(Command)

	GetAtServer("Docflow");

EndProcedure

&AtClient
Procedure SendToDocflow(Command)

	SendAtServer("AccSystem");

EndProcedure

&AtClient
Procedure SendToAccSystem(Command)

	SendAtServer("Docflow");

EndProcedure

&AtServer
Procedure GetAtServer(Customer)

	PrivilegedMode();

	Component = GetComponent();
	AuthParameters = GetAuthParameters();

	Try
		CheckConnection(Component, AuthParameters);
	Except
		Message(ErrorDescription());
		Return;
	EndTry;

	If Customer = "AccSystem" Then

		AccountingSystemGetText.Clear();

	ElsIf Customer = "Docflow" Then

		DocflowGetText.Clear();

		arrObjectsXDTO = New Array;
		
		While True Do

			Answer = RabbitMQ_Get(Component, AuthParameters, "Docflow_MDM");

			If ValueIsFilled(Answer) Then

				DocflowGetText.AddLine("----------------------------------------------------------------------------------------");
				DocflowGetText.AddLine(Answer);

				XMLReader = New XMLReader;
				XMLReader.SetString(Answer);

				ObjectXDTO = XDTOFactory.ReadXML(XMLReader);
				If TypeOf(ObjectXDTO) = Type("XDTODataObject") Then
					arrObjectsXDTO.Add(ObjectXDTO);
				Else
					Continue;
				EndIf;
			Else
				Break;
			EndIf;
		EndDo;

		LimitsForEmployeesServer.LoadChangeObjects(arrObjectsXDTO);
	EndIf;

EndProcedure

&AtServer
Procedure SendAtServer(Source)

	If Not ValueIsFilled(Node) Then
		Message(NStr("ru = 'Не заполнен узел обмена!'; en = 'Exchange node not is filed!'"));
		Return;
	EndIf;

	Component = GetComponent();
	AuthParameters = GetAuthParameters();

	Try
		CheckConnection(Component, AuthParameters);
	Except
		Message(ErrorDescription());
		Return;
	EndTry;

	If Source = "AccSystem" Then

		AccountingSystemSendText.Clear();

		Changes = LimitsForEmployeesServer.GetChangedObjects(Node);

		For Each ObjectXDTO In Changes.XDTO_Objects Do

			XMLWriter = New XMLWriter;
			XMLWriter.SetString();

			XDTOFactory.WriteXML(XMLWriter, ObjectXDTO);

			XMLRequest = XMLWriter.Close();
			RabbitMQ_Send(Component, AuthParameters, "AccSystem", "MDM", XMLRequest);

			AccountingSystemSendText.AddLine("----------------------------------------------------------------------------------------");
			AccountingSystemSendText.AddLine(XMLRequest);
		EndDo;

		If Changes.Property("Refs") And Changes.Refs.Count() Then
			ExchangePlans.DeleteChangeRecords(Node, Changes.Refs);
		EndIf;

		If Changes.Property("RecordSets") And Changes.RecordSets.Count() Then
			For Each strRecordSet In Changes.RecordSets Do

				ObjectManager = Common.ObjectManagerByFullName(strRecordSet.Type + "." + strRecordSet.Name);
				RecordSet = ObjectManager.CreateRecordSet();
				
				For Each Dimension In strRecordSet.Dimensions Do
					RecordSet.Filter[Dimension.Key].Set(Dimension.Value);
				EndDo;

				ExchangePlans.DeleteChangeRecords(Node, RecordSet);
			EndDo;
		EndIf;

	ElsIf Source = "Docflow" Then

		DocflowSendText.Clear();

	EndIf;

EndProcedure

#Region Private

&AtServer
Function GetURLTemplateComposition(UUID)

	TemplateExternalComponent = FormAttributeToValue("Object").GetTemplate("ExternalComponent");
	TempStorageURL = PutToTempStorage(TemplateExternalComponent, UUID);

	Return TempStorageURL;

EndFunction

&AtClientAtServerNoContext
Function InitializationComponentClientServer(Component)

	Try
		Component  = New("AddIn.BITERP.PinkRabbitMQ");
		Return True;
	Except
		Return False;
	EndTry;

EndFunction

&AtServer
Function GetAuthParameters()

	AuthParameters = New Structure;
	AuthParameters.Insert("URL", RabbitMQURL);
	AuthParameters.Insert("Port", RabbitMQPort);
	AuthParameters.Insert("Login", RabbitMQLogin);
	AuthParameters.Insert("Password", RabbitMQPassword);

	Return AuthParameters;

EndFunction
	
#EndRegion

#Region RabbitMQ

&AtClientAtServerNoContext
Procedure CheckConnection(ComponentClient, AuthSetting)

	Try
		ComponentClient.Connect(AuthSetting.URL, AuthSetting.Port, AuthSetting.Login, AuthSetting.Password, "ProjectWork");
	Except
		SystemError = ErrorDescription();
		MessageText = NStr("ru = 'Ошибка подключения!
							|%SystemError%';
							|en = 'Connection error!
							|%SystemError%'");
		MessageText = StrReplace(MessageText, "%SystemError%", SystemError);
		Raise MessageText;
	EndTry;

	Message(NStr("ru = 'Подключение успешно выполнено!'; en = 'Connection successfuly!'"));

EndProcedure

&AtClientAtServerNoContext
Procedure RabbitMQ_Send(ComponentClient, AuthSetting, Exchange, RoutingKey, Request)

	Try
		ComponentClient.Connect(AuthSetting.URL, AuthSetting.Port, AuthSetting.Login, AuthSetting.Password, "ProjectWork");
		ComponentClient.BasicPublish(Exchange, RoutingKey, Request, 1, True);
	Except
		SystemError = ErrorDescription();
		MessageText = NStr("ru = 'Ошибка отправки сообщения!
							|%SystemError%';
							|en = 'Send message error!
							|%SystemError%'");
		MessageText = StrReplace(MessageText, "%SystemError%", SystemError);
		Raise MessageText;
	EndTry;

EndProcedure

&AtClientAtServerNoContext
Function RabbitMQ_Get(ComponentClient, AuthSetting, Queue)

	Answer = "";

	Try
		ComponentClient.Connect(AuthSetting.URL, AuthSetting.Port, AuthSetting.Login, AuthSetting.Password, "ProjectWork");

		Try
			ComponentClient.BasicConsume(Queue, "", False, False, 0);

			AnswerTag = 0;
			If ComponentClient.BasicConsumeMessage("", Answer, AnswerTag) Then
				ComponentClient.BasicAck();
			EndIf;

			ComponentClient.BasicCancel("");
		Except
			Raise ComponentClient.GetLastError();
		EndTry;
	Except
		SystemError = ErrorDescription();
		MessageText = NStr("ru = 'Ошибка чтения сообщения!
							|%SystemError%';
							|en = 'Read message error!
							|%SystemError%'");
		MessageText = StrReplace(MessageText, "%SystemError%", SystemError);
		Raise MessageText;
	EndTry;

	Return Answer;

EndFunction

#EndRegion
