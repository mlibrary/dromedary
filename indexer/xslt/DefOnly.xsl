<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="1.0">
    <xsl:import href="./indexer/xslt/Common.xsl"/>
    <xsl:output method="html" indent="yes"/>
 
    <xsl:template match="DEF">
        <span>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
</xsl:stylesheet>
