#language: ru

@tree

Функционал: Тесты подсистемы "Limits for employees"

Как Администратор я хочу
установить лимиты расходов для нового сотрудника, 
чтобы выполнять контроль возмещения расходов    

Контекст:
	Дано Я запускаю сценарий открытия TestClient или подключаю уже существующий

Сценарий: Прием на работу с установкой значений лимитов

	* Заполнение нового договора
		И В командном интерфейсе я выбираю "Limits for employees" "Employment Contracts"
		Тогда открылось окно "Employment Contracts"
		И я нажимаю на кнопку "Создать"
		Тогда открылось окно "Employment Contract (создание)"
		И в поле "Employee" я ввожу текст "Петров Петр Петрович"
		И в поле "Employee ID" я ввожу текст "124"
		И в поле "Employment Date" я ввожу текст "10.04.2025"
		И в поле "Entity" я ввожу текст "Global management solutions"

	* Заполнение лимитов
	* строка "Medical insurance for family members"
		И я перехожу к закладке "Limits"
		И в таблице 'LimitTypeList' я перехожу к строке:
			| "Type of limit"                        |
			| "Medical insurance for family members" |
		И я изменяю флаг с именем 'LimitTypeListLimitCheck'
	
	* строка "Number of family members"
		И в таблице 'LimitTypeList' я перехожу к строке:
			| "Type of limit"            |
			| "Number of family members" |
		И в таблице 'LimitTypeList' в поле с именем 'LimitTypeListLimit' я ввожу текст "2,00"

	* строка "Schooling allowance"
		И в таблице 'LimitTypeList' я перехожу к строке:
			| "Type of limit"       |
			| "Schooling allowance" |
		И в таблице 'LimitTypeList' в поле с именем 'LimitTypeListLimit' я ввожу текст "65 000,00"
		И в поле "Start date" я ввожу текст "01.01.2026"
		И я нажимаю на кнопку "Generate"
		И в таблице 'LimitsForEmployeesTable' я нажимаю на кнопку "Добавить"
		И в таблице 'LimitsForEmployeesTable' в поле с именем 'LimitsForEmployeesTableLimitDate' я ввожу текст "10.04.2025"
		И в таблице 'LimitsForEmployeesTable' в поле с именем 'LimitsForEmployeesTableLimit' я ввожу текст "35 000,00"

	* строка "Tickets (Home leave)"
		И в таблице 'LimitTypeList' я перехожу к строке:
			| "Type of limit"        |
			| "Tickets (Home leave)" |
		И в таблице 'LimitTypeList' в поле с именем 'LimitTypeListLimit' я ввожу текст "4"
		И я нажимаю на кнопку "Generate"
		И в таблице 'LimitsForEmployeesTable' я нажимаю на кнопку "Добавить"
		И в таблице 'LimitsForEmployeesTable' в поле с именем 'LimitsForEmployeesTableLimitDate' я ввожу текст "10.04.2025"
		И в таблице 'LimitsForEmployeesTable' в поле с именем 'LimitsForEmployeesTableLimit' я ввожу текст "2"

	* Запись и проведение документа
		И я нажимаю на кнопку "Провести и закрыть"
		И я жду закрытия окна "Employment Contract (создание) *" в течение 10 секунд
		И я закрываю все окна клиентского приложения

Сценарий: Прием на работу сотрудника, принятого ранее

	* Заполнение нового договора
		И В командном интерфейсе я выбираю "Limits for employees" "Employment Contracts"
		Тогда открылось окно "Employment Contracts"
		И я нажимаю на кнопку "Создать"
		Тогда открылось окно "Employment Contract (создание)"
		И в поле "Employee" я ввожу текст "Петров Петр Петрович"
		И в поле "Employee ID" я ввожу текст "125"
		И в поле "Employment Date" я ввожу текст "12.05.2025"
		И в поле "Entity" я ввожу текст "Global management solutions"

		* Запись и проведение документа
		И я нажимаю на кнопку "Провести и закрыть"
		Тогда в логе сообщений TestClient есть строка "Employee Петров Петр Петрович is already working in the company."
		И я закрываю все окна клиентского приложения
