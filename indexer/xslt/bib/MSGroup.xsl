  <?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="1.0">
  <xsl:import href="./indexer/xslt/bib/Common.xsl"/>
  <xsl:output method="html" indent="yes"/>


  <xsl:strip-space elements="ABBR"/>

  <xsl:template match="//MSGROUP">
    <div class="MSGROUP">
      <xsl:apply-templates/>
    </div>
  </xsl:template>


  <xsl:template match="//stglist">
    <xsl:variable name="variants"><xsl:value-of select="ancestor::*[name()='MSGROUP'][1]/@VAR"/></xsl:variable>
    <ul class="stg-list">
      <xsl:apply-templates/>
      <xsl:if test="$variants = 'Y'">
        <li class="stg">See also Variants below.</li>
      </xsl:if>
    </ul>
  </xsl:template>

  <xsl:template match="stglist/STG" name="stg">
    <li class="stg">
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <xsl:template match="//STG/STENCIL/ABBR">

    <xsl:variable name="abbr"><xsl:value-of select="."/></xsl:variable>


    <xsl:if test="$abbr != ''">
      <xsl:text> </xsl:text>
      <span class="abbrev"><xsl:value-of select="$abbr"/></span>
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
