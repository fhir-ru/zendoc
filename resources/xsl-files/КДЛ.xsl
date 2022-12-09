<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet version='2.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
<xsl:output method='text'/>

<xsl:template match="/ClinicalDocument">
resourceType: Bundle
type: 'document'
language: 'ru-RU'
identifier:
  system: <xsl:value-of select="id/@root" />
  value: <xsl:value-of select="id/@extension" />
 meta:
  versionId: '1'  
 - resource:
   resourceType: 'Composition'
   type:
    coding:
      - system: 'http://loinc.org'
        code: '11502-2'
        display: 'Laboratory report'
      - system: <xsl:value-of select="code/@codeSystem" /> 
        code: <xsl:value-of select="code/@code" /> 
        version: <xsl:value-of select="code/@codeSystemVersion" /> 
        display: <xsl:value-of select="code/@displayName" /> 
   author:
    reference: Practitioner/<xsl:value-of select="author/assignedAuthor/id/@extension" />
   status: 'final'
   date: <xsl:call-template name="FormatDate">
<xsl:with-param name="DateTime" select="effectiveTime/@value"/>
</xsl:call-template>
   confidentiality: 'N'
  <!--<xsl:call-template name="author"/>-->
  

</xsl:template>
  
 <xsl:template match="author" name="author">
   a1: <xsl:value-of select="time/@nullFlavor" />
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
