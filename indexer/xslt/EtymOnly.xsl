<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="1.0">
    <xsl:import href="Common.xsl"/>
    
    <xsl:output method="html" indent="yes"/>
    
    
    
    
    <!-- orig|new -->
    <xsl:variable name="formMode">orig</xsl:variable>
    
    <xsl:template match="/">
        
        <html>
            <head> </head>
            <body>
               
                <xsl:apply-templates select="ETYM" />
               
            </body>
        </html>
    </xsl:template>
  
    
    <xsl:template match="LANG">
        <!--XXX need mouseover stuff here-->
        <xsl:apply-templates/>
    </xsl:template>
    
</xsl:stylesheet>