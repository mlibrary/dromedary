<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="1.0">
    <xsl:import href="Common.xsl"/>
    <xsl:output method="html" indent="yes"/>

   
    <xsl:template match="/">

        <html>
            <head> </head>
            <body>
                <!-- do we need foreach? -->
               <xsl:apply-templates select="DEF"/>
              
            </body>
        </html>
    </xsl:template>
 
    <xsl:template match="DEF">
        <p>
            <xsl:apply-templates/>
        </p>
        <!--  <xsl:value-of select="."/>-->
    </xsl:template>

    
</xsl:stylesheet>