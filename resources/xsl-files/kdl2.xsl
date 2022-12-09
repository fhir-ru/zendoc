<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet version='2.0'
xpath-default-namespace="urn:hl7-org:v3"
xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
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
 <xsl:call-template name="organizations" />
 <xsl:call-template name="orderTask" />
 <xsl:call-template name="resultTask" />
 <xsl:call-template name="diagnosticReports" />  

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
 <xsl:call-template name="organization" >
     <xsl:with-param name="OrgNode" select="participant/associatedEntity/scopingOrganization"/>
 </xsl:call-template>  
 <xsl:call-template name="organization" >
     <xsl:with-param name="OrgNode" select="documentationOf/serviceEvent/performer/assignedEntity/representedOrganization"/>
 </xsl:call-template>
 <xsl:call-template name="organization" >
  <xsl:with-param name="OrgNode" select="component/structuredBody/component/section/entry/organizer/component/procedure/performer/assignedEntity/representedOrganization"/>
 </xsl:call-template>
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
	   
<xsl:template name="diagnosticReports"> 
 <xsl:variable name="reportDate">
  <xsl:value-of select="component/structuredBody/component/section/entry/act/effectiveTime/@value" />
 </xsl:variable> 
 <xsl:for-each select="component/structuredBody/component/section/entry/organizer/component/organizer">
 - resource: 
    resourceType: 'DiagnosticReport'
    id: 'DiagnosticReport/<xsl:number value="position()" format="1"/>'
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
 </xsl:for-each> 
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
<xsl:value-of select="'T'"/>
<xsl:value-of select="$hr"/>
<xsl:value-of select="':'"/>
<xsl:value-of select="$minute"/>
<xsl:value-of select="':'"/>
<xsl:value-of select="concat('00',$sec)"/>
</xsl:template>
  
</xsl:stylesheet>