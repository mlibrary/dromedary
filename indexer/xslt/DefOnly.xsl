<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="1.0">
    
    <xsl:import href="./indexer/xslt/Common.xsl"/>
    <xsl:output method="html" indent="yes"/>

    <xsl:template match="/DEF">
        <!--XXX temporary css for debugging -->
        <style type="text/css">
            .HI_B {font-weight:bold}
            .HI_I {font-style:italic}
            .USG {font-style:italic}
            .STNCL {font-weight:bold}
            .STNCL_TITLE {font-style:italic}
            .ORTH {font-weight:bold}
            .HDORTH {font-weight:bold}
        </style>
        <!--End temporary css for debugging -->
       
        <div class="DEF">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

</xsl:stylesheet>
