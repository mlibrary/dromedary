<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">
  <xsl:param name="bibid"/>


  <xsl:output method="html" indent="yes"/>


  <xsl:template match="//STNCL/MS">
    <span clas="MS">
      <xsl:text>(</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>)</xsl:text>
    </span>
  </xsl:template>

  <xsl:template match="STNCL">
    <xsl:variable name="rid">
      <xsl:value-of select="current()/@RID"/>
    </xsl:variable>
    <span class="STNCL">
      <xsl:choose>
        <xsl:when test="$rid != ''">
          <xsl:element name="a">
            <xsl:attribute name="href">
              <xsl:text>/bibliography/</xsl:text>
              <xsl:value-of select="$rid"/>
              <xsl:text>?rid=</xsl:text>
              <xsl:value-of select="$rid"/>
            </xsl:attribute>
            <xsl:apply-templates/>
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>

    </span>
    <xsl:text>:</xsl:text>

  </xsl:template>



  <xsl:template match="Q">
    <span class="Q">
      <xsl:value-of select="."/>
      <xsl:text> </xsl:text>
    </span>
  </xsl:template>

  <!-- do we need to handle NOTE -->


</xsl:stylesheet>
