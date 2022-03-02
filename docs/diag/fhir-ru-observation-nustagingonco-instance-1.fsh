Instance:  fhir-ru-observation-nustagingonco-instance-1
InstanceOf: Observation
Title:   "Пример стадирование онкологического заболевания"
Usage:  #example

* status = #final

* code = http://loinc.org#21908-9 "Stage group.clinical Cancer"

* subject = Reference(fhir-ru-patient-instance-konstantinopolskaya)

* focus = Reference(fhir-ru-condition-nu-instance-1)

* effectiveDateTime = "2019-04-01"

* valueCodeableConcept = http://cancerstaging.org#3C "IIIC"

* method = http://snomed.info/sct#897275008 "American Joint Commission on Cancer, Cancer Staging Manual, 8th edition neoplasm staging system (tumor staging)"

* hasMember[0] = Reference(fhir-ru-observation-tnmt-instance-1)
* hasMember[+] = Reference(fhir-ru-observation-tnmn-instance-1)
* hasMember[+] = Reference(fhir-ru-observation-tnmm-instance-1)