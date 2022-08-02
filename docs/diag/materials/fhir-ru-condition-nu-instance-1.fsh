Alias: $nsi-cs-1005 = https://nsi.rosminzdrav.ru/#!/refbook/1.2.643.5.1.13.13.11.1005

Instance:  fhir-ru-condition-nu-instance-1
InstanceOf: http://fhir.ru/fhir/StructureDefinition/fhir-ru-condition-nu
Title:   "Пример нозологической единицы - C50.3 Злокачественное новообразование нижневнутреннего квадранта молочной железы"
Usage:  #example

* identifier.system = "urn:fhir:ru:entity:condition"
* identifier.value = "d34c35ab-4c2e-4c6e-9f42-a7879d47dcd5"

* extension[condition-assertedDate].valueDateTime = "2019-04-01"

* subject = Reference(fhir-ru-patient-instance-konstantinopolskaya)

* code.coding.system = $nsi-cs-1005
* code.coding.code = #C50.3
* code.coding.display = "Злокачественное новообразование нижневнутреннего квадранта молочной железы"

* bodySite = http://snomed.info/sct#80248007 "Left breast structure (body structure)"

* stage.summary = http://cancerstaging.org#3C "IIIC"
* stage.type = http://loinc.org#21908-9 "Stage group.clinical Cancer"

* stage.assessment = Reference(fhir-ru-observation-nustagingonco-instance-1)