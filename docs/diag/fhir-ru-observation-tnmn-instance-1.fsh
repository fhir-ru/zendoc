Instance:  fhir-ru-observation-tnmn-instance-1
InstanceOf: Observation
Title:   "Пример стадирование N (nodus) — наличие метастазов в регионарных лимфатических узлах"
Usage:  #example

* status = #final

* code = http://loinc.org#21907-1 "Distant metastases.clinical [Class] Cancer"

* subject = Reference(fhir-ru-patient-instance-konstantinopolskaya)

* focus = Reference(fhir-ru-condition-nu-instance-1)

* effectiveDateTime = "2019-04-01"

* valueCodeableConcept = http://cancerstaging.org#cN3 "N3"

* method = http://snomed.info/sct#897275008 "American Joint Commission on Cancer, Cancer Staging Manual, 8th edition neoplasm staging system (tumor staging)"