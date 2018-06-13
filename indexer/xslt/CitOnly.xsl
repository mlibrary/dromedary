<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">
  <xsl:import href="./indexer/xslt/Common.xsl"/>
  <xsl:param name="bibid"/>


  <xsl:output method="html" indent="yes"/>

  <xsl:template match="//DATE|//AUTHOR|//TITLE|//CIT|//SCOPE|//BIBL">
    <span>
      <xsl:attribute name="class">
        <xsl:value-of select="local-name()"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </span>
  </xsl:template>


  <xsl:template match="//STNCL/MS">
    <span clas="MS">
      <xsl:text>(</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>)</xsl:text>
    </span>
  </xsl:template>

  <xsl:template match="STNCL">
    <xsl:variable name="RsomethingID">
      <xsl:value-of select="@RID"/>
    </xsl:variable>
    <span class="STNCL">
      <xsl:element name="a">
        <xsl:attribute name="href">
          <xsl:text>/bibliography/</xsl:text>
          <xsl:value-of select="$bibid"/>
          <xsl:text>?rid=</xsl:text>
          <xsl:value-of select="$RsomethingID"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </xsl:element>
    </span>
    <xsl:text>: </xsl:text>

  </xsl:template>



  <xsl:template match="Q">
    <span class="Q">
      <xsl:value-of select="."/>
      <xsl:text></xsl:text>
    </span>
  </xsl:template>

  <!-- do we need to handle NOTE -->


</xsl:stylesheet>
