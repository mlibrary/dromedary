<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="1.0">
  <xsl:import href="./indexer/xslt/bib/Common.xsl"/>
  <xsl:import href="./indexer/xslt/bib/Abbreviation.xsl"/>
  <xsl:output method="html" indent="yes"/>

  <xsl:template match="//VARIANT|//SOURCE">
    <div>
      <xsl:attribute name="class">
        <xsl:value-of select="local-name()"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="shortstencillist">
    <ul class="short-stencil-list">
      <xsl:apply-templates/>
    </ul>
  </xsl:template>

  <xsl:template match="shortstencillist/SHORTSTENCIL">
    <li class="short-stencil">
      <xsl:apply-templates/>
    </li>
  </xsl:template>


</xsl:stylesheet>