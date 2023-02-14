<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet version='2.0'
xpath-default-namespace="urn:hl7-org:v3"
xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns:medService="urn:hl7-ru:medService"
xmlns:fias="urn:hl7-ru:fias"
xmlns:identity="urn:hl7-ru:identity"
xmlns:address="urn:hl7-ru:address">

<xsl:output method='text'/>

<xsl:template match="/ClinicalDocument">
resourceType: Bundle
type: 'document'
language: 'ru-RU'
identifier:
  system: 'urn:oid:<xsl:value-of select="id/@root" />'
  value: '<xsl:value-of select="id/@extension" />'
meta:
 versionId: '1'
entry: 
 - resource:
 <xsl:call-template name="composition" />
 <xsl:call-template name="patient" />
 <xsl:call-template name="practitioners" />
 <xsl:call-template name="organizations" />
 <xsl:call-template name="encounter" />
 <xsl:call-template name="orderTask" />
 <xsl:call-template name="resultTask" />
 <xsl:call-template name="serviceRequests" /> 
 <xsl:call-template name="diagnosticReports" />
 <xsl:call-template name="observations" />
 <xsl:call-template name="specimens" />
 <xsl:call-template name="substances" />
 <xsl:call-template name="devices" />
 <xsl:call-template name="medias" />
 <xsl:call-template name="coverage" />

</xsl:template>
       
<xsl:template name="composition">
    resourceType: 'Composition'
    type:
     coding:
      - system: 'http://loinc.org'
        code: '11502-2'
        display: 'Laboratory report'
      - system: 'urn:oid:<xsl:value-of select="code/@codeSystem" />'
        code: '<xsl:value-of select="code/@code" />'
        version: '<xsl:value-of select="code/@codeSystemVersion" />'
        display: '<xsl:value-of select="code/@displayName" />'
    author:
     - reference: '#Practitioner/<xsl:value-of select="author/assignedAuthor/id[@root!='1.2.643.100.3']/@extension" />'
    status: 'final'
    date: '<xsl:call-template name="FormatDate">
     <xsl:with-param name="DateTime" select="effectiveTime/@value"/>
    </xsl:call-template>'
    confidentiality: 'N'
    identifier: 
     system: 'urn:oid:1.2.643.5.1.13.13.12.2.77.8312.100.1.1.50'
     value: '9633'
    title: 'Протокол лабораторного исследования'
    section:
      <xsl:call-template name="compositionSection">
      <xsl:with-param name="title" select="'ДАННЫЕ О ПАЦИЕНТЕ'"/>
       <xsl:with-param name="display" select="'recordTarget'"/>
       <xsl:with-param name="reference" select="concat('#Patient/', recordTarget/patientRole/id[@root!='1.2.643.100.3']/@extension)" />
     </xsl:call-template> 
      <xsl:call-template name="compositionSection">
      <xsl:with-param name="title" select="'ДАННЫЕ ОБ АВТОРЕ ДОКУМЕНТА'"/>
       <xsl:with-param name="display" select="'author'"/>
       <xsl:with-param name="reference" select="concat('#Practitioner/', author/assignedAuthor/id[@root!='1.2.643.100.3']/@extension)" />
     </xsl:call-template>
      <xsl:call-template name="compositionSection">
      <xsl:with-param name="title" select="'ДАННЫЕ ОБ ОРГАНИЗАЦИИ-ВЛАДЕЛЬЦЕ ДОКУМЕНТА'"/>
       <xsl:with-param name="display" select="'custodian'"/>
       <xsl:with-param name="reference" select="concat('#Organization/', custodian/assignedCustodian/representedCustodianOrganization/id/@extension)" />
     </xsl:call-template>
      <xsl:call-template name="compositionSection">
      <xsl:with-param name="title" select="'ДАННЫЕ О ПОЛУЧАТЕЛЕ ДОКУМЕНТА'"/>
       <xsl:with-param name="display" select="'informationRecipient'"/>
       <xsl:with-param name="reference" select="concat('#Organization/', informationRecipient/intendedRecipient/receivedOrganization/id/@root)" />
     </xsl:call-template>
      <xsl:call-template name="compositionSection">
      <xsl:with-param name="title" select="'ДАННЫЕ О ЛИЦЕ, ПРИДАВШЕМ ЮРИДИЧЕСКУЮ СИЛУ ДОКУМЕНТУ'"/>
       <xsl:with-param name="display" select="'legalAuthenticator'"/>
       <xsl:with-param name="reference" select="concat('#Practitioner/', legalAuthenticator/assignedEntity/id[@root!='1.2.643.100.3']/@extension)" />
     </xsl:call-template>      
      <xsl:call-template name="compositionSection">
      <xsl:with-param name="title" select="'СВЕДЕНИЯ ОБ ИСТОЧНИКЕ ОПЛАТЫ'"/>
       <xsl:with-param name="display" select="'participantInd'"/>
       <xsl:with-param name="reference" select="concat('#Coverage/', '1')" />
     </xsl:call-template>     
      <xsl:call-template name="compositionSection">
      <xsl:with-param name="title" select="'СВЕДЕНИЯ О НАПРАВИВШЕМ ЛИЦЕ И ОРГАНИЗАЦИИ'"/>
       <xsl:with-param name="display" select="'participantRef'"/>
       <xsl:with-param name="reference" select="concat('#Practitioner/', participant[@typeCode='REF']/associatedEntity/id[@root!='1.2.643.100.3']/@extension)" />
     </xsl:call-template>
      <xsl:call-template name="compositionSection">
      <xsl:with-param name="title" select="'СВЕДЕНИЯ О НАПРАВЛЕНИИ'"/>
       <xsl:with-param name="display" select="'order'"/>
       <xsl:with-param name="reference" select="concat('#Task/', '1')" />
     </xsl:call-template>
      <xsl:call-template name="compositionSection">
      <xsl:with-param name="title" select="'ТЕЛО ДОКУМЕНТА'"/>
       <xsl:with-param name="display" select="'structuredBody'"/>
       <xsl:with-param name="reference" select="concat('#Task/', '2')" />
     </xsl:call-template>
</xsl:template>     

<xsl:template name="compositionSection">
 <xsl:param name="title" />
 <xsl:param name="display" />
 <xsl:param name="reference" />
     - title: '<xsl:value-of select="$title"/>'
       code: 
        coding: 
         - display: '<xsl:value-of select="$display"/>'
       entry: 
       - reference: '<xsl:value-of select="$reference"/>'  
</xsl:template>     

<xsl:template name="organizations">
 <xsl:call-template name="organization" >
     <xsl:with-param name="OrgNode" select="recordTarget/patientRole/providerOrganization"/>
 </xsl:call-template>
 <xsl:call-template name="organization" >
     <xsl:with-param name="OrgNode" select="informationRecipient/intendedRecipient/receivedOrganization"/>
 </xsl:call-template>
 <xsl:call-template name="organization" >
     <xsl:with-param name="OrgNode" select="custodian/assignedCustodian/representedCustodianOrganization"/>
 </xsl:call-template>
 <xsl:call-template name="organization" >
     <xsl:with-param name="OrgNode" select="legalAuthenticator/assignedEntity/representedOrganization"/>
 </xsl:call-template> 
 <xsl:for-each select="participant/associatedEntity/scopingOrganization" >
  <xsl:call-template name="organization" >
    <xsl:with-param name="OrgNode" select="."/>
  </xsl:call-template>  
 </xsl:for-each>
 <xsl:for-each select="documentationOf/serviceEvent/performer/assignedEntity/representedOrganization" > 
  <xsl:call-template name="organization" >
     <xsl:with-param name="OrgNode" select="."/>
  </xsl:call-template>
 </xsl:for-each>
 <xsl:for-each select="component/structuredBody/component/section/entry/organizer/component/procedure/performer/assignedEntity/representedOrganization" >
  <xsl:call-template name="organization" >
   <xsl:with-param name="OrgNode" select="."/>
  </xsl:call-template>
 </xsl:for-each>
 <xsl:call-template name="organization" >
  <xsl:with-param name="OrgNode" select="recordTarget/patientRole/providerOrganization"/>
 </xsl:call-template>     
</xsl:template>     

<xsl:template name="organization">
<xsl:param name="OrgNode" />
<xsl:variable name="OffId">
 <xsl:value-of select="$OrgNode/id[@root!='1.2.643.5.1.13.2.1.1.1504.101']/@root" />
</xsl:variable>
<xsl:variable name="SecId">
 <xsl:value-of select="$OrgNode/id[@root!='1.2.643.5.1.13.2.1.1.1504.101']/@extension" />
</xsl:variable>
 - resource: 
    resourceType: 'Organization'
    identifier: 
     - value: 'urn:oid:<xsl:value-of select="$OffId" />'
       system: 'urn:ru:frmo:oid'
       use: 'official'
       type: 
        text: 'ОИД организации'
        coding: 
         - system: 'http://terminology.hl7.org/CodeSystem/v2-0203'
           code: 'PRN'
           display: 'Provider number'
    <xsl:if test="$SecId!=''">
     - value: 'urn:oid:<xsl:value-of select="$SecId" />'
       system: 'urn:ru:frmo:oid'
       use: 'secondary'
       type: 
        text: 'ОИД организации'
        coding: 
         - system: 'http://terminology.hl7.org/CodeSystem/v2-0203'
           code: 'PRN'
           display: 'Provider number'
    </xsl:if> 
    <xsl:if test="$OrgNode/id[@root='1.2.643.5.1.13.2.1.1.1504.101']/@extension">
     - value: '<xsl:value-of select="$OrgNode/id[@root='1.2.643.5.1.13.2.1.1.1504.101']/@extension" />'
       system: 'urn:oid:1.2.643.5.1.13.2.1.1.1504.101'
       assigner: 
        display: '<xsl:value-of select="$OrgNode/id[@root='1.2.643.5.1.13.2.1.1.1504.101']/@assigningAuthorityName" />'
       type: 
        text: 'Лицензия организации'
        coding: 
         - system: 'http://terminology.hl7.org/CodeSystem/v2-0203'
           code: 'SL'
           display: 'State license'
    </xsl:if> 
    <xsl:if test="$OrgNode/identity:Props/identity:Ogrn">
     - value: '<xsl:value-of select="$OrgNode/identity:Props/identity:Ogrn" />'
       system: 'urn:ru:id:ogrn'
    </xsl:if>
    <xsl:if test="$OrgNode/identity:Props/identity:Okato">
     - value: '<xsl:value-of select="$OrgNode/identity:Props/identity:Okato" />'
       system: 'urn:ru:id:okato'
    </xsl:if>
    name: '<xsl:value-of select="$OrgNode/name" />'
   <xsl:call-template name="addresses" >
     <xsl:with-param name="ParNode" select="$OrgNode"/>
   </xsl:call-template>
   <xsl:call-template name="contacts" >
     <xsl:with-param name="ParNode" select="$OrgNode"/>
	 <xsl:with-param name="ContNodeName" select="'contact'"/>
   </xsl:call-template>
 </xsl:template>

<xsl:template name="encounter">
 - resource: 
    resourceType: 'Encounter'
    id: 'Encounter/1'
    class: 
     - system: 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
    period: 
     start: '<xsl:call-template name="FormatDate">
      <xsl:with-param name="DateTime" select="componentOf/encompassingEncounter/effectiveTime/low/@value"/>
     </xsl:call-template>'
     end: '<xsl:call-template name="FormatDate">
      <xsl:with-param name="DateTime" select="componentOf/encompassingEncounter/effectiveTime/high/@value"/>
     </xsl:call-template>'
    status: 'finished'
    identifier: 
     <xsl:for-each select="componentOf/encompassingEncounter/id">
      <xsl:variable name="idSystem">
       <xsl:value-of select="./@root" />
      </xsl:variable>
      <xsl:variable name="idCode">
       <xsl:value-of select="./@extension" />
      </xsl:variable>

      <xsl:choose>
       <xsl:when test="ends-with($idSystem,'.15')">
     - value: '<xsl:value-of select="./@extension" />'
       system: 'urn:oid:<xsl:value-of select="$idSystem" />'
       type: 
        coding: 
         - system: 'http://terminology.hl7.org/CodeSystem/v2-0203'
           code: 'ACSN'
       </xsl:when>
       <xsl:otherwise>
     - value: '<xsl:value-of select="./@extension" />'
       system: 'urn:oid:<xsl:value-of select="$idSystem" />'
       type: 
        coding: 
         - system: 'urn:oid:<xsl:value-of select="..//medService:DocType/@codeSystem" />'
           code: '<xsl:value-of select="..//medService:DocType/@code" />'
           version: '<xsl:value-of select="..//medService:DocType/@codeSystemVersion" />'
           display: '<xsl:value-of select="..//medService:DocType/@displayName" />'
         - system: 'urn:oid:<xsl:value-of select="..//code/@codeSystem" />'
           code: '<xsl:value-of select="..//code/@code" />'
           version: '<xsl:value-of select="..//code/@codeSystemVersion" />'
           display: '<xsl:value-of select="..//code/@displayName" />'
         - system: 'http://terminology.hl7.org/CodeSystem/v2-0203'
           code: 'MR'
       </xsl:otherwise>
      </xsl:choose>
     </xsl:for-each>
 </xsl:template>
 
<xsl:template name="orderTask"> 
 - resource: 
    resourceType: 'Task'
    id: 'Task/1' 
    status: 'completed'
    intent: 'order'
    identifier: 
     - value: '<xsl:value-of select="inFulfillmentOf/order/id/@extension" />'
       system: 'urn:oid:<xsl:value-of select="inFulfillmentOf/order/id/@root" />'
    code: 
     coding: 
      - system: 'urn:oid:<xsl:value-of select="inFulfillmentOf/order/code/@codeSystem" />'
        code: '<xsl:value-of select="inFulfillmentOf/order/code/@code" />'
        version: '<xsl:value-of select="inFulfillmentOf/order/code/@codeSystemVersion" />'
    requester:
     reference: '#Practitioner/<xsl:value-of select="participant[@typeCode='REF']/associatedEntity/id/@extension" />'
    encounter:
     reference: '#Encounter/1'
    insurance:
     - reference: '#Coverage/1'
    basedOn: 
    <xsl:for-each select="component/structuredBody/component/section/entry/organizer/component/organizer/code/originalText">
     - reference: '#ServiceRequest/<xsl:number value="position()" format="1"/>'
    </xsl:for-each>
 </xsl:template>  
 
<xsl:template name="resultTask"> 
 - resource: 
    resourceType: 'Task'
    id: 'Task/2' 
    status: 'completed'
    intent: 'filler-order'
    basedOn:
     - reference: '#Task/1' 
    priority: '<xsl:call-template name="TaskPriorityCode">
     <xsl:with-param name="Code" select="documentationOf/serviceEvent/medService:serviceForm/@code"/>
    </xsl:call-template>'
    executionPeriod:
     start: '<xsl:call-template name="FormatDate">
      <xsl:with-param name="DateTime" select="documentationOf/serviceEvent/effectiveTime/low/@value"/>
     </xsl:call-template>'
     end: '<xsl:call-template name="FormatDate">
      <xsl:with-param name="DateTime" select="documentationOf/serviceEvent/effectiveTime/high/@value"/>
     </xsl:call-template>'
    <!--http://snomed.info/sct-->
    performerType: 
     - coding: 
       - system: 'urn:oid:<xsl:value-of select="documentationOf/serviceEvent/medService:serviceType/@codeSystem" />'
         code: '<xsl:value-of select="documentationOf/serviceEvent/medService:serviceType/@code" />'
         version: '<xsl:value-of select="documentationOf/serviceEvent/medService:serviceType/@codeSystemVersion" />'
 </xsl:template> 

<xsl:template name="serviceRequests"> 
 <xsl:for-each select="component/structuredBody/component/section/entry/organizer/component/organizer/code/originalText">
 - resource: 
    resourceType: 'ServiceRequest'
    id: 'ServiceRequest/<xsl:number value="position()" format="1"/>'
    status: 'completed'
    intent: 'original-order'
    subject:
     reference: '#Patient/1'
    code: 
     coding: 
      - system: 'urn:oid:1.2.643.5.1.13.13.11.1070'
        display: '<xsl:value-of select="." />'  
 </xsl:for-each> 
</xsl:template>  
  
<xsl:template name="diagnosticReports"> 
 <xsl:variable name="reportDate">
  <xsl:value-of select="component/structuredBody/component/section/entry/act/effectiveTime/@value" />
 </xsl:variable>
 <xsl:for-each select="component/structuredBody/component/section/entry/organizer/component/organizer">
  <xsl:variable name="reportId">
   <xsl:number value="position()" format="1"/>
  </xsl:variable>
 - resource: 
    resourceType: 'DiagnosticReport'
    id: 'DiagnosticReport/<xsl:value-of select="$reportId" />'
    status: 'final'
    effectiveDateTime: '<xsl:call-template name="FormatDate">
     <xsl:with-param name="DateTime" select="$reportDate"/>
    </xsl:call-template>'
   <!--category: 
    - coding: 
      - system: 'urn:oid:1.2.643.5.1.13.13.11.1476'
        display: '<xsl:value-of select="./code/originalText" />'-->
    code: 
     coding: 
      - system: 'urn:oid:1.2.643.5.1.13.13.11.1070'
        display: 'Клинический анализ крови на анализаторе' 
  <xsl:for-each select="component/observation">
   <xsl:variable name="observationId">
    <xsl:number value="position()" format="1"/>
   </xsl:variable>
    result:
     - reference: '#Observation/<xsl:value-of select="concat($reportId, '.', $observationId)" />'
  </xsl:for-each> 
  <xsl:if test="component/observationMedia">
    media:
     - link:
        reference: '#Media/<xsl:value-of select="$reportId" />'
  </xsl:if>  
 </xsl:for-each> 
</xsl:template> 

<xsl:template name="observations"> 
 <xsl:for-each select="component/structuredBody/component/section/entry/organizer/component/organizer">
  <xsl:variable name="reportId">
   <xsl:number value="position()" format="1"/>
  </xsl:variable>
  <xsl:for-each select="component/observation">
   <xsl:variable name="observationId">
    <xsl:number value="position()" format="1"/>
   </xsl:variable>
   <xsl:call-template name="observation" >
    <xsl:with-param name="ObservationNode" select="."/>
    <xsl:with-param name="ObservationId" select="concat($reportId, '.', $observationId)"/>
   </xsl:call-template>   
  </xsl:for-each> 
 </xsl:for-each> 
</xsl:template> 

<xsl:template name="observation"> 
 <xsl:param name="ObservationNode" />
 <xsl:param name="ObservationId" />
 - resource: 
    resourceType: 'Observation'
    id: 'Observation/<xsl:value-of select="$ObservationId" />' 
    status: 'final'
    code: 
     coding: 
      - system: 'urn:oid:<xsl:value-of select="$ObservationNode/code/@codeSystem" />'
        code: '<xsl:value-of select="$ObservationNode/code/@code" />'
        version: '<xsl:value-of select="$ObservationNode/code/@codeSystemVersion" />' 
        display: '<xsl:value-of select="$ObservationNode/code/@displayName" />'
 <xsl:if test="$ObservationNode/effectiveTime/@value">
    effectiveDateTime: '<xsl:call-template name="FormatDate">
     <xsl:with-param name="DateTime" select="$ObservationNode/effectiveTime/@value"/>
    </xsl:call-template>'
 </xsl:if>
 <xsl:if test="$ObservationNode/interpretationCode/@nullFlavor">
    interpretation: 
     - extension: 
       - url: 'http://hl7.org/fhir/StructureDefinition/iso21090-nullFlavor'
         valueCode: '<xsl:value-of select="$ObservationNode/interpretationCode/@nullFlavor" />'
 </xsl:if>
 <xsl:if test="$ObservationNode/interpretationCode/@code">
    interpretation: 
     - coding: 
        - system: 'urn:oid:1.2.643.5.1.13.13.99.2.257'
          code: '<xsl:value-of select="$ObservationNode/interpretationCode/@code" />'
 </xsl:if>
    specimen:
     reference: '#Specimen/<xsl:value-of select="$ObservationNode/specimen/specimenRole/id/@extension" />'
    performer:
 <xsl:for-each select="$ObservationNode/performer/assignedEntity/id">
     - reference: '#Practitioner/<xsl:value-of select="./@extension" />'
 </xsl:for-each> 
 <xsl:variable name="valueType">
  <xsl:value-of select="$ObservationNode/value/@xsi:type" />
 </xsl:variable>
 <xsl:choose>
   <xsl:when test="$valueType='ST'">
    valueString: '<xsl:value-of select="$ObservationNode/value" />'
   </xsl:when>
   <xsl:when test="$valueType='CD'">
    valueCodeableConcept: 
     coding: 
      - system: 'urn:oid:<xsl:value-of select="$ObservationNode/value/@codeSystem" />'
        code: '<xsl:value-of select="$ObservationNode/value/@code" />'
        version: '<xsl:value-of select="$ObservationNode/value/@codeSystemVersion" />' 
        display: '<xsl:value-of select="$ObservationNode/value/@displayName" />'
   </xsl:when>
   <xsl:when test="$valueType='PQ'">
    valueQuantity: 
     system: 'urn:oid:<xsl:value-of select="$ObservationNode/value/translation/@codeSystem" />'
     code: '<xsl:value-of select="$ObservationNode/value/translation/@code" />'
     value: <xsl:value-of select="$ObservationNode/value/translation/@value" />
     unit: '<xsl:value-of select="$ObservationNode/value/translation/@displayName" />'
   </xsl:when>
   <!--IVL_PQ-->
   <xsl:otherwise>
   </xsl:otherwise>
 </xsl:choose>
 <xsl:if test="$ObservationNode/referenceRange/observationRange/text">
   <xsl:call-template name="referenceRange" >
    <xsl:with-param name="RangeNode" select="$ObservationNode/referenceRange/observationRange"/>
   </xsl:call-template >
 </xsl:if> 
 <xsl:if test="$ObservationNode/entryRelationship/act/text"> 
    note: 
     - text: '<xsl:value-of select="$ObservationNode/entryRelationship/act/text" />'
       authorReference: 
        reference: '#Practitioner/<xsl:value-of select="$ObservationNode/entryRelationship/act/author/assignedAuthor/id/@extension" />'
       time: '<xsl:call-template name="FormatDate">
        <xsl:with-param name="DateTime" select="$ObservationNode/entryRelationship/act/author/time/@value"/>
       </xsl:call-template>'
 </xsl:if> 
 <xsl:if test="$ObservationNode/participant[@typeCode='DEV']/participantRole/id/@extension"> 
    device: 
     reference: '#Device/<xsl:value-of select="$ObservationNode/participant[@typeCode='DEV']/participantRole/id/@extension" />'
 </xsl:if> 
 <!--<xsl:if test="$ObservationNode/participant[@typeCode='CSM']/participantRole/id/@extension"> 
    device: 
     reference: '#Substance/<xsl:value-of select="$ObservationNode/participant[@typeCode='CSM']/participantRole/id/@extension" />'
 </xsl:if>-->
</xsl:template> 

<xsl:template name="referenceRange"> 
 <xsl:param name="RangeNode" />
    referenceRange: 
     - text: '<xsl:value-of select="$RangeNode/text" />'
  <xsl:if test="$RangeNode/value/low/translation/@code">
       low: 
        system: 'urn:oid:<xsl:value-of select="$RangeNode/value/low/translation/@codeSystem" />'
        code: '<xsl:value-of select="$RangeNode/value/low/translation/@code" />'
        value: <xsl:value-of select="$RangeNode/value/low/translation/@value" />
        unit: '<xsl:value-of select="$RangeNode/value/low/translation/@displayName" />'
  </xsl:if>     
  <xsl:if test="$RangeNode/value/high/translation/@code">
       low: 
        system: 'urn:oid:<xsl:value-of select="$RangeNode/value/high/translation/@codeSystem" />'
        code: '<xsl:value-of select="$RangeNode/value/high/translation/@code" />'
        value: <xsl:value-of select="$RangeNode/value/high/translation/@value" />
        unit: '<xsl:value-of select="$RangeNode/value/high/translation/@displayName" />'
  </xsl:if>     
       type: 
        coding: 
         - system: 'http://terminology.hl7.org/CodeSystem/referencerange-meaning'
           code: 'normal'
</xsl:template> 

<xsl:template name="specimens"> 
 <xsl:for-each select="//procedure">
 <!--<xsl:for-each select="component/structuredBody/component/section/entry/organizer/component/procedure">-->
  <xsl:variable name="procedureCode">
   <xsl:value-of select="code/@code" />
  </xsl:variable>
  <xsl:variable name="procedureSystem">
   <xsl:value-of select="code/@codeSystem" />
  </xsl:variable>
  <xsl:variable name="procedureVersion">
   <xsl:value-of select="code/@codeSystemVersion" />
  </xsl:variable>
  <xsl:variable name="procedureName">  
   <xsl:choose>
    <xsl:when test="code/@displayName!=''">
     <xsl:value-of select="code/@displayName" />
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="code/originalText" />
    </xsl:otherwise>
   </xsl:choose>
  </xsl:variable>   
  <xsl:variable name="procedureTime">
   <xsl:value-of select="effectiveTime/@value" />
  </xsl:variable>  
  <xsl:variable name="procedureTimeLow">
   <xsl:value-of select="effectiveTime/low/@value" />
  </xsl:variable>  
  <xsl:variable name="procedureTimeHigh">
   <xsl:value-of select="effectiveTime/high/@value" />
  </xsl:variable>  
  <xsl:variable name="pefrormer">
   <xsl:value-of select="performer/assignedEntity/id/@extension" />
  </xsl:variable>     
  
  <xsl:for-each select="specimen/specimenRole">  
   <xsl:call-template name="specimen" >
    <xsl:with-param name="SpecimenNode" select="."/>
     <xsl:with-param name="ProcedureCode" select="$procedureCode"/>
     <xsl:with-param name="ProcedureSystem" select="$procedureSystem"/>
     <xsl:with-param name="ProcedureVersion" select="$procedureVersion"/>
     <xsl:with-param name="ProcedureName" select="$procedureName"/>
     <xsl:with-param name="ProcedureTime" select="$procedureTime"/>
     <xsl:with-param name="ProcedureTimeLow" select="$procedureTimeLow"/>
     <xsl:with-param name="ProcedureTimeHigh" select="$procedureTimeHigh"/>
     <xsl:with-param name="Pefrormer" select="$pefrormer"/>
     
   </xsl:call-template>
   
  </xsl:for-each>    
 </xsl:for-each> 
</xsl:template> 

<xsl:template name="specimen"> 
 <xsl:param name="SpecimenNode" />
 <xsl:param name="ProcedureCode" />
 <xsl:param name="ProcedureSystem" />
 <xsl:param name="ProcedureVersion" />
 <xsl:param name="ProcedureName" />
 <xsl:param name="ProcedureTime" />
 <xsl:param name="ProcedureTimeLow" />
 <xsl:param name="ProcedureTimeHigh" />
 <xsl:param name="Pefrormer" />

 - resource: 
    resourceType: 'Specimen'
    id: 'Specimen/<xsl:value-of select="$SpecimenNode/id/@extension" />'
    type:
     coding:
      - system: 'urn:oid:<xsl:value-of select="$SpecimenNode/specimenPlayingEntity/code/@codeSystem" />'
        code: '<xsl:value-of select="$SpecimenNode/specimenPlayingEntity/code/@code" />'
        version: '<xsl:value-of select="$SpecimenNode/specimenPlayingEntity/code/@codeSystemVersion" />' 
        display: '<xsl:value-of select="$SpecimenNode/specimenPlayingEntity/code/@displayName" />'
    identifier:
     - value: '<xsl:value-of select="$SpecimenNode/id/@extension" />'
       system: 'urn:oid:<xsl:value-of select="$SpecimenNode/id/@root" />'
    collection:
     collector:
      <xsl:if test="$Pefrormer!=''">      
      reference: '#Practitioner/<xsl:value-of select="$Pefrormer" />'
      </xsl:if>
      <xsl:if test="$ProcedureTime!=''">      
     collectedDateTime: '<xsl:call-template name="FormatDate">
        <xsl:with-param name="DateTime" select="$ProcedureTime"/>
       </xsl:call-template>'
      </xsl:if>
      <xsl:if test="$ProcedureTimeLow!=''">      
     collectedPeriod:
      start: '<xsl:call-template name="FormatDate">
        <xsl:with-param name="DateTime" select="$ProcedureTimeLow"/>
       </xsl:call-template>'
      end: '<xsl:call-template name="FormatDate">
        <xsl:with-param name="DateTime" select="$ProcedureTimeHigh"/>
       </xsl:call-template>'
      </xsl:if>
     quantity:
      system: 'urn:oid:<xsl:value-of select="$SpecimenNode/specimenPlayingEntity/quantity/translation/@codeSystem" />'
      code: '<xsl:value-of select="$SpecimenNode/specimenPlayingEntity/quantity/translation/@code" />'
      value: <xsl:value-of select="$SpecimenNode/specimenPlayingEntity/quantity/@value" />
      unit: '<xsl:value-of select="$SpecimenNode/specimenPlayingEntity/quantity/translation/@displayName" />'
     method:
      coding:
       - system: 'urn:oid:<xsl:value-of select="$ProcedureSystem" />'
         <xsl:if test="$ProcedureCode!=''" >
         <!--TODO вывести nullFlavor-->
         code: '<xsl:value-of select="$ProcedureCode" />' 
         </xsl:if>
         <xsl:if test="$ProcedureVersion!=''" >
         version: '<xsl:value-of select="$ProcedureVersion" />'
         </xsl:if>         
         display: '<xsl:value-of select="$ProcedureName" />'       
    container:
     - description: '<xsl:value-of select="$SpecimenNode/specimenPlayingEntity/desc" />'
       identifier:
        - value: '<xsl:value-of select="$SpecimenNode/id/@extension" />'
          system: 'urn:oid:<xsl:value-of select="$SpecimenNode/id/@root" />'
       <!--additiveReference: 
        reference: 'BE9898F6-1184-22C3-8D5A-6D62AED7632B' TODO Нужно взять расходный материал из Observation -->
</xsl:template> 

<xsl:template name="substances"> 
 <xsl:for-each select="component/structuredBody/component/section/entry/organizer/participant[@typeCode='CSM']">
   <xsl:call-template name="substance" >
    <xsl:with-param name="SubstanceNode" select="."/> 
   </xsl:call-template>
 </xsl:for-each> 
</xsl:template> 

<xsl:template name="substance"> 
 <xsl:param name="SubstanceNode" />
 - resource: 
    id: 'Specimen/<xsl:value-of select="$SubstanceNode/participantRole/id/@extension" />' 
    resourceType: 'Substance'
    identifier: 
     - value: '<xsl:value-of select="$SubstanceNode/participantRole/id/@extension" />'
       system: 'urn:oid:<xsl:value-of select="$SubstanceNode/participantRole/id/@root" />'
    description: '<xsl:value-of select="$SubstanceNode/participantRole/playingDevice/manufacturerModelName" />'
    code: 
     coding: 
      - display: '<xsl:value-of select="$SubstanceNode/participantRole/playingDevice/manufacturerModelName" />'
</xsl:template>  

<xsl:template name="devices"> 
 <xsl:for-each select="component/structuredBody/component/section/entry/organizer/participant[@typeCode='CSM']">
   <xsl:call-template name="device" >
    <xsl:with-param name="DeviceNode" select="."/> 
   </xsl:call-template>
 </xsl:for-each> 
</xsl:template> 

<xsl:template name="device"> 
 <xsl:param name="DeviceNode" />
 - resource: 
    id: 'Device/<xsl:value-of select="$DeviceNode/participantRole/id/@extension" />' 
    resourceType: 'Device'
    identifier: 
     - value: '<xsl:value-of select="$DeviceNode/participantRole/id/@extension" />'
       system: 'urn:oid:<xsl:value-of select="$DeviceNode/participantRole/id/@root" />'
    deviceName: 
     - name: '<xsl:value-of select="$DeviceNode/participantRole/playingDevice/manufacturerModelName" />'
       type: 'manufacturer-name' 
</xsl:template>  

<xsl:template name="medias"> 
 <xsl:for-each select="component/structuredBody/component/section/entry/organizer/component/organizer">
  <xsl:variable name="reportId">
   <xsl:number value="position()" format="1"/>
  </xsl:variable>
  <xsl:if test="component/observationMedia">
   <xsl:call-template name="media" >
     <xsl:with-param name="MediaNode" select="component/observationMedia"/>
      <xsl:with-param name="MediaId" select="$reportId"/>
   </xsl:call-template> 
  </xsl:if>
 </xsl:for-each> 
</xsl:template> 

<xsl:template name="media"> 
 <xsl:param name="MediaNode" />
 <xsl:param name="MediaId" />
 - resource: 
    resourceType: 'Media'
    id: 'Media/<xsl:value-of select="$MediaId" />' 
    status: 'completed'
    content: 
     data: '<xsl:value-of select="$MediaNode/value" />'
    createdDateTime: '<xsl:call-template name="FormatDate">
     <xsl:with-param name="DateTime" select="$MediaNode/author/time/@value"/>
    </xsl:call-template>'
    device:
     reference: '#Device/<xsl:value-of select="$MediaNode/participant[@typeCode='DEV']/participantRole/id/@extension" />'
    operator:
     reference: '#Practitioner/<xsl:value-of select="$MediaNode/author/assignedAuthor/id/@extension" />'
</xsl:template> 

<xsl:template name="coverage"> 
 <xsl:for-each select="participant/associatedEntity[@classCode='GUAR']">
  <xsl:variable name="policyStartDate">
   <xsl:value-of select="identity:DocInfo/identity:effectivetime/identity:low/@value" />
  </xsl:variable>
  <xsl:variable name="policyEndDate">
   <xsl:value-of select="identity:DocInfo/identity:effectivetime/identity:high/@value" />
  </xsl:variable>
 - resource: 
    resourceType: 'Coverage'
    id: 'Coverage/1'
    identifier:
     - value: '9876543211234567'
       system: 'http://fhir.ru/core/systems/oms'
       type:
        coding:
         - system: 'urn:oid:<xsl:value-of select="identity:DocInfo/identity:IdentityDocType/@codeSystem" />'
           code: '<xsl:value-of select="identity:DocInfo/identity:IdentityDocType/@code" />'
           version: '<xsl:value-of select="identity:DocInfo/identity:IdentityDocType/@codeSystemVersion" />'
           display: '<xsl:value-of select="identity:DocInfo/identity:IdentityDocType/@displayName" />'
         - system: 'urn:oid:<xsl:value-of select="identity:DocInfo/identity:InsurancePolicyType/@codeSystem" />'
           code: '<xsl:value-of select="identity:DocInfo/identity:InsurancePolicyType/@code" />'
           version: '<xsl:value-of select="identity:DocInfo/identity:InsurancePolicyType/@codeSystemVersion" />'
           display: '<xsl:value-of select="identity:DocInfo/identity:InsurancePolicyType/@displayName" />'
    period:
      start: '<xsl:call-template name="FormatDate">
        <xsl:with-param name="DateTime" select="$policyStartDate"/>
       </xsl:call-template>'
      <xsl:if test="$policyEndDate!=''">
      end: '<xsl:call-template name="FormatDate">
        <xsl:with-param name="DateTime" select="$policyEndDate"/>
       </xsl:call-template>'
      </xsl:if>  
    status: 'active'
    beneficiary:
     reference: '#Patient/1'
    payor:
     - reference: '#Organization/<xsl:value-of select="scopingOrganization/id/@extension" />'
    type:
     coding:
      - system: 'urn:oid:<xsl:value-of select="code/@codeSystem" />'
        code: '<xsl:value-of select="code/@code" />'
        version: '<xsl:value-of select="code/@codeSystemVersion" />'
        display: '<xsl:value-of select="code/@codeSystemName" />'
      - system: "http://hl7.org/fhir/ValueSet/coverage-type"
        code: "MANDPOL"
 </xsl:for-each>
</xsl:template> 

<xsl:template name="patient"> 
 <xsl:variable name="inn">
  <xsl:value-of select="participant/associatedEntity/identity:DocInfo/identity:INN" />
 </xsl:variable>

 <xsl:for-each select="recordTarget/patientRole">
  <xsl:variable name="identityDocDate">
   <xsl:value-of select="identity:IdentityDoc/identity:IssueDate/@value" />
  </xsl:variable>
  <xsl:variable name="policySeries">
   <xsl:value-of select="identity:InsurancePolicy/identity:Series" />
  </xsl:variable> 
  <xsl:variable name="policyNumber">
   <xsl:value-of select="identity:InsurancePolicy/identity:Number" />
  </xsl:variable>
  <xsl:variable name="policyId">  
   <xsl:choose>
    <xsl:when test="$policySeries!=''">
     <xsl:value-of select="$policySeries,$policyNumber" />
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="$policyNumber" />
    </xsl:otherwise>
   </xsl:choose>
  </xsl:variable>  
 - resource: 
    resourceType: 'Patient'
    id: 'Patient/1'
    identifier: 
     - value: '<xsl:value-of select="id[@root!='1.2.643.100.3']/@extension" />'
       system: 'urn:oid:<xsl:value-of select="id[@root!='1.2.643.100.3']/@root" />'
       type: 
        text: 'Номер медицинской карты'
        coding: 
         - system: 'http://terminology.hl7.org/CodeSystem/v2-0203'
           code: 'PI'
           display: 'Patient internal identifier'
     - value: '<xsl:value-of select="id[@root='1.2.643.100.3']/@extension" />'
       system: 'http://fhir.ru/core/systems/snils'
       type: 
        text: 'СНИЛС'
        coding: 
         - system: 'http://terminology.hl7.org/CodeSystem/v2-0203'
           code: 'SB'
           display: 'Social Beneficiary Identifier'
     - value: '<xsl:value-of select="identity:IdentityDoc/identity:Series" />,<xsl:value-of select="identity:IdentityDoc/identity:Number" />'
       system: 'http://fhir.ru/core/systems/passport-rf'
       assigner: 
        identifier: 
         value: '<xsl:value-of select="identity:IdentityDoc/identity:IssueOrgCode" />'
        display: '<xsl:value-of select="identity:IdentityDoc/identity:IssueOrgName" />'
       period: 
        start: '<xsl:call-template name="FormatDate">
        <xsl:with-param name="DateTime" select="$identityDocDate"/>
       </xsl:call-template>'
       type: 
        text: 'Номер паспорта'
        coding: 
         - system: 'http://terminology.hl7.org/CodeSystem/v2-0203'
           code: 'PPN'
           display: 'Passport number'
         - system: 'urn:oid:<xsl:value-of select="identity:IdentityDoc/identity:IdentityCardType/@codeSystem" />'
           code: '<xsl:value-of select="identity:IdentityDoc/identity:IdentityCardType/@code" />'
           version: '<xsl:value-of select="identity:IdentityDoc/identity:IdentityCardType/@codeSystemVersion" />'
           display: '<xsl:value-of select="identity:IdentityDoc/identity:IdentityCardType/@displayName" />'
     - value: '<xsl:value-of select="$inn" />'
       system: 'http://fhir.ru/core/systems/inn'
       type: 
        text: 'ИНН'
        coding: 
         - system: 'http://terminology.hl7.org/CodeSystem/v2-0203'
           code: 'TAX'
           display: 'Tax ID number'
     - value: '<xsl:value-of select="$policyId" />'
       system: 'http://fhir.ru/core/systems/ffoms-erz'
       type: 
        coding: 
         - system: 'http://terminology.hl7.org/CodeSystem/v2-0203'
           code: 'SB'
           display: 'Social Beneficiary Identifier'
         - system: 'urn:oid:<xsl:value-of select="identity:InsurancePolicy/identity:InsurancePolicyType/@codeSystem" />'
           code: '<xsl:value-of select="identity:InsurancePolicy/identity:InsurancePolicyType/@code" />'
           version: '<xsl:value-of select="identity:InsurancePolicy/identity:InsurancePolicyType/@codeSystemVersion" />'
           display: '<xsl:value-of select="identity:InsurancePolicy/identity:InsurancePolicyType/@displayName" />'
    name: 
     - use: 'official'
       family: '<xsl:value-of select="patient/name/family" />'
       given: 
        - '<xsl:value-of select="patient/name/given" />'
        - '<xsl:value-of select="patient/name/identity:Patronymic" />'
    gender: '<xsl:call-template name="GenderCode">
     <xsl:with-param name="Code" select="patient/administrativeGenderCode/@code"/>
    </xsl:call-template>'
    birthDate: '<xsl:call-template name="FormatDate">
     <xsl:with-param name="DateTime" select="patient/birthTime/@value"/>
    </xsl:call-template>'
    <xsl:call-template name="addresses" >
     <xsl:with-param name="ParNode" select="."/>
   </xsl:call-template>
   <xsl:call-template name="contacts" >
     <xsl:with-param name="ParNode" select="."/>
	 <xsl:with-param name="ContNodeName" select="'contact'"/>
   </xsl:call-template>
 <!--<xsl:if test="count(telecom)"> 
    contact:  
  <xsl:for-each select="telecom">
   <xsl:variable name="telecomValue">
    <xsl:value-of select="./@value" />
   </xsl:variable>
   <xsl:variable name="type">
    <xsl:value-of select="substring-before($telecomValue,':')" />
   </xsl:variable>
   <xsl:variable name="contact">
    <xsl:value-of select="substring-after($telecomValue,':')" />
   </xsl:variable>
     - telecom: 
       - value: '<xsl:value-of select="$type" />'
         system: '<xsl:value-of select="normalize-space($contact)" />'
  </xsl:for-each>
 </xsl:if>-->
    extension: 
     - url: 'http://fhir.ru/core/sd/core-ex-gender'
       valueCodeableConcept: 
        coding: 
         - system: '<xsl:value-of select="patient/administrativeGenderCode/@codeSystem" />'
           code: '<xsl:value-of select="patient/administrativeGenderCode/@code" />'
           version: '<xsl:value-of select="patient/administrativeGenderCode/@codeSystemVersion" />'
           display: '<xsl:value-of select="patient/administrativeGenderCode/@displayName" />'

 </xsl:for-each>
</xsl:template>

<xsl:template name="practitioners"> 
 <xsl:call-template name="practitioner" >
     <xsl:with-param name="PractNode" select="author/assignedAuthor"/>
 </xsl:call-template>
 <xsl:call-template name="practitioner" >
     <xsl:with-param name="PractNode" select="legalAuthenticator/assignedEntity"/>
 </xsl:call-template> 
 <xsl:call-template name="practitioner" >
     <xsl:with-param name="PractNode" select="participant[@typeCode='REF']/associatedEntity"/>
 </xsl:call-template>
 <xsl:call-template name="practitioner" >
     <xsl:with-param name="PractNode" select="component/structuredBody/component/section/entry/organizer/component/procedure/performer/assignedEntity"/>
 </xsl:call-template>
 
 <xsl:for-each select="documentationOf/serviceEvent/performer/assignedEntity">
  <xsl:call-template name="practitioner" >
    <xsl:with-param name="PractNode" select="."/>
  </xsl:call-template>
 </xsl:for-each> 
</xsl:template> 
  
<xsl:template name="practitioner"> 
 <xsl:param name="PractNode" />
 <xsl:variable name="practId">
  <xsl:value-of select="$PractNode/id[@root!='1.2.643.100.3']/@extension" />
 </xsl:variable> 
 - resource:
    resourceType: 'Practitioner'
    id: 'Practitioner/<xsl:value-of select="$practId" />'
    identifier: 
     - value: '<xsl:value-of select="$practId" />'
       system: 'urn:oid:<xsl:value-of select="$PractNode/id[@root!='1.2.643.100.3']/@root" />'
       type: 
        text: 'Номер сотрудника в МИС'
        coding: 
         - system: 'http://terminology.hl7.org/CodeSystem/v2-0203'
           code: 'EN'
           display: 'Employer number'
     - value: '<xsl:value-of select="$PractNode/id[@root='1.2.643.100.3']/@extension" />'
       system: 'http://fhir.ru/core/systems/snils'
       type: 
        text: 'СНИЛС'
        coding: 
         - system: 'http://terminology.hl7.org/CodeSystem/v2-0203'
           code: 'NI'
           display: 'National unique individual identifier'
    name: 
     - use: 'official'
  <xsl:if test="$PractNode/assignedPerson/name/family">
       family: '<xsl:value-of select="$PractNode/assignedPerson/name/family" />'
       given: 
        - '<xsl:value-of select="$PractNode/assignedPerson/name/identity:Patronymic" />'
        - '<xsl:value-of select="$PractNode/assignedPerson/name/given" />'
  </xsl:if>
  <xsl:if test="$PractNode/associatedPerson/name/family">
       family: '<xsl:value-of select="$PractNode/associatedPerson/name/family" />'
       given: 
        - '<xsl:value-of select="$PractNode/associatedPerson/name/identity:Patronymic" />'
        - '<xsl:value-of select="$PractNode/associatedPerson/name/given" />' 
  </xsl:if>           
  <xsl:call-template name="addresses" >
    <xsl:with-param name="ParNode" select="$PractNode"/>
  </xsl:call-template>
  <xsl:call-template name="contacts" >
     <xsl:with-param name="ParNode" select="$PractNode"/>
	 <xsl:with-param name="ContNodeName" select="'telecom'"/>
   </xsl:call-template>
    <!--<xsl:if test="$PractNode/telecom">
    telecom: 
     <xsl:for-each select="$PractNode/telecom">
      <xsl:variable name="telecomValue">
       <xsl:value-of select="./@value" />
      </xsl:variable>
      <xsl:variable name="type">
       <xsl:value-of select="substring-before($telecomValue,':')" />
      </xsl:variable>
      <xsl:variable name="contact">
       <xsl:value-of select="substring-after($telecomValue,':')" />
      </xsl:variable>
     - telecom: 
       - value: '<xsl:value-of select="$type" />'
         system: '<xsl:value-of select="normalize-space($contact)" />'
   </xsl:for-each>
  </xsl:if>-->
  <xsl:call-template name="practitionerRole" >
    <xsl:with-param name="PractRoleNode" select="$PractNode"/>
     <xsl:with-param name="PractId" select="$practId"/>
  </xsl:call-template>
</xsl:template> 

<xsl:template name="practitionerRole"> 
 <xsl:param name="PractRoleNode" />
 <xsl:param name="PractId" />
 
 <xsl:variable name="organization">  
  <xsl:choose>
   <xsl:when test="$PractRoleNode/scopingOrganization/id/@root!=''">
    <xsl:value-of select="$PractRoleNode/scopingOrganization/id/@root" />
   </xsl:when>
   <xsl:otherwise>
    <xsl:value-of select="$PractRoleNode/representedOrganization/id/@root" />
   </xsl:otherwise>
  </xsl:choose>
 </xsl:variable>  
 - resource: 
    resourceType: 'PractitionerRole'
    code: 
     - coding: 
       - system: 'urn:oid:<xsl:value-of select="$PractRoleNode/code/@codeSystem" />'
         code: '<xsl:value-of select="$PractRoleNode/code/@code" />'
         version: '<xsl:value-of select="$PractRoleNode/code/@codeSystemVersion" />'
         display: '<xsl:value-of select="$PractRoleNode/code/@displayName" />'
    practitioner: 
     reference: '#Practitioner/<xsl:value-of select="$PractId" />'
    organization: 
     reference: 'urn:uuid:<xsl:value-of select="$organization" />'
</xsl:template> 

<xsl:template name="contacts">
 <xsl:param name="ParNode" />
 <xsl:param name="ContNodeName" />
 <xsl:if test="count($ParNode/telecom)">
 <xsl:choose>	
   <xsl:when test="$ContNodeName='telecom'" >
    telecom: 
   </xsl:when>
   <xsl:otherwise>
    contact:
   </xsl:otherwise>
  </xsl:choose>	
    <xsl:for-each select="$ParNode/telecom">
     <xsl:variable name="telecomValue">
      <xsl:value-of select="@value" />
     </xsl:variable>
     <xsl:variable name="type">
       <xsl:value-of select="substring-before($telecomValue,':')" />
     </xsl:variable>
     <xsl:variable name="contact">
      <xsl:value-of select="substring-after($telecomValue,':')" />
     </xsl:variable>
     - telecom: 
       - value: '<xsl:value-of select="$type" />'
         system: '<xsl:value-of select="normalize-space($contact)" />'
    </xsl:for-each>
  </xsl:if>
</xsl:template>
  
<xsl:template name="addresses">
 <xsl:param name="ParNode" /> 
 <xsl:if test="count($ParNode/addr)" >
    address: 
  <xsl:for-each select="$ParNode/addr">
     - text: '<xsl:value-of select="normalize-space(streetAddressLine)" />'
     <xsl:if test="address:Type/@code">
       use: '<xsl:call-template name="AddressUse">
      <xsl:with-param name="Code" select="address:Type/@code"/>
     </xsl:call-template>'
       _use: 
        extension: 
         - url: 'http://fhir.ru/core/sd/core-ex-address-use'
           valueCodeableConcept: 
            coding: 
             - system: 'urn:oid:<xsl:value-of select="address:Type/@codeSystem" />'
               code: '<xsl:value-of select="address:Type/@code" />'
               version: '<xsl:value-of select="address:Type/@codeSystemVersion" />'
               display: '<xsl:value-of select="address:Type/@displayName" />'
     </xsl:if>

       state: '<xsl:value-of select="address:stateCode/@code" />'
       _state:
        extension: 
         - url: 'http://fhir.ru/core/sd/core-ex-state'
           valueCodeableConcept: 
            coding: 
             - system: 'urn:oid:<xsl:value-of select="address:stateCode/@codeSystem" />'
               code: '<xsl:value-of select="address:stateCode/@code" />'
               version: '<xsl:value-of select="address:stateCode/@codeSystemVersion" />'
               display: '<xsl:value-of select="address:stateCode/@displayName" />'
       postalCode: '<xsl:value-of select="postalCode" />'
       extension: 
        - url: 'http://fhir.ru/core/sd/core-ex-address-fias'
          valueString: '<xsl:value-of select="fias:Address/fias:AOGUID" />'
        - url: 'http://fhir.ru/core/sd/core-ex-address-fias-house'
          valueString: '<xsl:value-of select="fias:Address/fias:HOUSEGUID" />'
  </xsl:for-each>
 </xsl:if>
</xsl:template>

<xsl:template name="GenderCode">
 <xsl:param name="Code" />
 <xsl:choose>
  <xsl:when test="$Code = 1">
   <xsl:text>male</xsl:text>
  </xsl:when>
  <xsl:when test="$Code = 2">
   <xsl:text>female</xsl:text>
  </xsl:when>
  <xsl:when test="$Code = 3">
   <xsl:text>unknown</xsl:text>
  </xsl:when>
 </xsl:choose>
</xsl:template>

<xsl:template name="AddressUse">
 <xsl:param name="Code" />
 <xsl:choose>
  <xsl:when test="$Code = 1">
   <xsl:text>home</xsl:text>
  </xsl:when>
  <xsl:when test="$Code = 2">
   <xsl:text>temp</xsl:text>
  </xsl:when>
  <xsl:when test="$Code = 3">
   <xsl:text>billing</xsl:text>
  </xsl:when>
  <xsl:when test="$Code = 4">
   <xsl:text>work</xsl:text>
  </xsl:when>
 </xsl:choose>
</xsl:template>

<xsl:template name="TaskPriorityCode">
 <xsl:param name="Code" />
 <xsl:choose>
  <xsl:when test="$Code = 1">
   <xsl:text>routine</xsl:text>
  </xsl:when>
  <xsl:when test="$Code = 2">
   <xsl:text>urgent</xsl:text>
  </xsl:when>
  <xsl:when test="$Code = 3">
   <xsl:text>stat</xsl:text>
  </xsl:when>
<!--  <xsl:otherwise>
   <xsl:text>'NI'</xsl:text>
  </xsl:otherwise>-->
 </xsl:choose>
</xsl:template>
 
<xsl:template name="FormatDate">
<xsl:param name="DateTime" />
<!-- from 201812201220+0300 to 2018-12-20T12:20:00 -->
<xsl:variable name="year">
<xsl:value-of select="substring($DateTime,1,4)" />
</xsl:variable>
<xsl:variable name="month">
<xsl:value-of select="substring($DateTime,5,2)" />
</xsl:variable>
<xsl:variable name="day">
<xsl:value-of select="substring($DateTime,7,2)" />
</xsl:variable>
<xsl:variable name="hr">
<xsl:value-of select="substring($DateTime,9,2)" />
</xsl:variable>
<xsl:variable name="minute">
<xsl:value-of select="substring($DateTime,11,2)" />
</xsl:variable>
<xsl:variable name="sec">
<xsl:value-of select="substring($DateTime,13,2)" />
</xsl:variable>
<xsl:value-of select="$year"/>
<xsl:value-of select="'-'"/>
<xsl:value-of select="$month"/>
<xsl:value-of select="'-'"/>
<xsl:value-of select="$day"/>
<xsl:if test="$hr!=''">
 <xsl:value-of select="'T'"/>
 <xsl:value-of select="$hr"/>
 <xsl:value-of select="':'"/>
 <xsl:value-of select="$minute"/>
 <xsl:value-of select="':'"/>
 <xsl:value-of select="concat('00',$sec)"/>
</xsl:if>
</xsl:template>
  
</xsl:stylesheet>