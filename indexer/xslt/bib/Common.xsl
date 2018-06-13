<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="1.0">
  <xsl:output method="html" indent="yes"/>

  <xsl:template match="//EDITION|//WORK|//REF|//TITLE|//AUTHOR|//IPMEP|//JOLLIFFE|//WELLS|//REF|//ED|//REGION|//LALME|//LAEME">
    <span>
      <xsl:attribute name="class">
        <xsl:value-of select="local-name()"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- Kill it dead -->
  <xsl:template match="//E-EDITION/LINK"/>

  <xsl:template match="//VARIANT|//SOURCE|//E-EDITION">
    <div>
      <xsl:attribute name="class">
        <xsl:value-of select="local-name()"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="//I|//B">
    <span>
      <xsl:attribute name="class">HI_<xsl:value-of select="local-name()"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </span>
  </xsl:template>


  <xsl:template match="//STG/STENCIL" name="stencil">
    <span class="bib STENCILGROUP">
      <span class="STENCIL">
        <xsl:attribute name="id">
          <xsl:value-of select="@ID"/>
        </xsl:attribute>
        <xsl:apply-templates/>
      </span>
    </span>
  </xsl:template>


  <xsl:template match="USE">
    <span class="USE">
      <xsl:text> </xsl:text><span class="note-title">Note</span>:
      <xsl:apply-templates/>
    </span>
  </xsl:template>



</xsl:stylesheet>
