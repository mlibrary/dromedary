<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="1.0">
  <xsl:output method="html" indent="yes"/>


  <xsl:strip-space elements="ABBR"/>

  <xsl:template match="//STG/STENCIL/ABBR|//SHORTSTENCIL/ABBR">

    <xsl:variable name="abbr">
      <xsl:value-of select="."/>
    </xsl:variable>


    <xsl:if test="$abbr != ''">
      <xsl:text> (</xsl:text>
      <span class="abbrev">
        <xsl:value-of select="$abbr"/>
      </span>
      <xsl:text>) </xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="//DATE">
    <xsl:variable name="dte">
      <xsl:value-of select="."/>
    </xsl:variable>


    <xsl:if test="$dte != ''">
      <xsl:text> </xsl:text>
      <span class="date">
        <xsl:value-of select="$dte"/>
      </span>
      <xsl:text> </xsl:text>
    </xsl:if>

  </xsl:template>

</xsl:stylesheet>