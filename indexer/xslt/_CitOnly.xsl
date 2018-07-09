<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">
  <xsl:param name="biburl"/>


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
        <xsl:when test="$biburl != ''">
          <xsl:element name="a">
            <xsl:attribute name="href">
              <xsl:value-of select="$biburl"/>
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
  </xsl:template>


  <xsl:template match="//CIT">
    <span class="CIT">
    <xsl:choose>
      <xsl:when test="@TYPE = 'B'">
      [ <xsl:apply-templates/> ]
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
    </span>
  </xsl:template>

  <xsl:template match="Q">
    <xsl:text>: </xsl:text>
    <span class="Q">
      <xsl:value-of select="."/>
      <xsl:text> </xsl:text>
    </span>
  </xsl:template>

  <!-- do we need to handle NOTE -->


</xsl:stylesheet>
