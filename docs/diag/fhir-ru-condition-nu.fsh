Alias: $condition-assertedDate = http://hl7.org/fhir/StructureDefinition/condition-assertedDate
Alias: $nsi-cs-1005 = https://nsi.rosminzdrav.ru/#!/refbook/1.2.643.5.1.13.13.11.1005
Alias: $nsi-vs-1005 = http://fhir.ru/fhir/ValueSet/nsi-vs-1-2-643-5-1-13-13-11-1005
Alias: $fhir-ru-vs-stagetype = http://fhir.ru/fhir/ValueSet/fhir-ru-vs-stagetype

Profile:        Fhir_ru_condition_nu
Id:             fhir-ru-condition-nu
Parent:         Condition
Title:          "Нозологическая единица"
Description:    "Нозологическая единица."
* ^url = "http://fhir.ru/fhir/StructureDefinition/fhir-ru-condition-nu"
* ^version = "0.1.0"

* . MS
* . 1..1

* extension contains
    $condition-assertedDate named condition-assertedDate 0..1 MS

* extension[condition-assertedDate] ^short = "Дата установления нозологической единицы"
* extension[condition-assertedDate] ^definition = "Дата установления нозологической единицы."

* subject 1..1 MS
* subject ^short = "Пациент"
* subject ^definition = "Пациент."

* code ^short = "Код по МКБ-10"
* code ^definition = "Код (шифр) заболевания по справочнику МКБ-10."
* code 0..1 MS
* code from $nsi-vs-1005 (required)
* code.coding 1..1 MS
* code.coding.system 1..1 MS
* code.coding.system = $nsi-cs-1005
* code.coding.code 1..1 MS
* code.coding.display 1..1 MS

* bodySite 0..* MS
* bodySite ^short = "Локализация заболевания"
* bodySite ^definition = "Локализация заболевания."

* stage 0..* MS
* stage ^short = "Стадирование заболевания"
* stage ^short = "Стадирование заболевания."

* stage.type 0..1 MS
* stage.type from $fhir-ru-vs-stagetype (example)
* stage.type ^short = "Тип стадирования"
* stage.type ^definition = "Тип стадирования."