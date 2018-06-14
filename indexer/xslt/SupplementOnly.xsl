<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">
  <xsl:import href="./indexer/xslt/Common.xsl"/>
  <xsl:import href="./indexer/xslt/_CitOnly.xsl"/>

  <xsl:output method="html" indent="yes"/>


  <xsl:template match="/SUPPLEMENT | /supplement">
    <div class="SUPPLEMENT">
      <xsl:for-each select="EG">
        <ul>
          <xsl:apply-templates/>
        </ul>
      </xsl:for-each>
      <xsl:apply-templates select="/SUPPLEMENT/NOTE | /supplememt/NOTE"/>
    </div>
  </xsl:template>


  <xsl:template match="SUPPLEMENT/EG/CIT">
    <li><span class="CIT"><xsl:apply-templates/></span></li>
  </xsl:template>


</xsl:stylesheet>
