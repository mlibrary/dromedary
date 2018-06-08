<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="1.0">
  <xsl:import href="./indexer/xslt/bib/Common.xsl"/>
  <xsl:output method="html" indent="yes"/>


  <xsl:template match="//BIBL|//STNCL">
    <span>
      <xsl:attribute name="class">
        <xsl:value-of select="local-name()"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="//MS">
  <xsl:variable name="ms">
    <xsl:value-of select="."/>
  </xsl:variable>


  <xsl:if test="$ms != ''">
    <xsl:text> (</xsl:text>
    <span class="ms">
      <xsl:value-of select="$ms"/>
    </span>
    <xsl:text>) </xsl:text>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>