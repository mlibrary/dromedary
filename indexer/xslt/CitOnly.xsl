<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">
    <xsl:import href="Common.xsl"/>
    
    <xsl:template match="/CIT|cit" >
        
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
        
        <div class="CIT">
            <xsl:apply-templates select="BIBL|bibl"/>
            <xsl:apply-templates select="Q|q"/>
        </div>
    </xsl:template>
    
  
    <xsl:template match="BIBL">
        <xsl:apply-templates select="STNCL"/>
        <xsl:text>  </xsl:text>
        <xsl:value-of select="SCOPE"/>
        <xsl:value-of select="normalize-space(text())"/>
        <xsl:text>: </xsl:text>
    </xsl:template>
    
    <xsl:template match="STNCL">
        <xsl:variable name="RsomethingID">
            <xsl:value-of select="@RID"/>
        </xsl:variable>
        <!--#########################################################
           XXX issues with hyperlinkg
           1 all these links will need to go to the new hyperbib app
           2 can we pass along a parameter besides the ID of the Hyperbib entry.  
           i.e. we actually know which STNCL within that entry the user clicked on, can't we highlight it?
           
           #########################################################-->
        <xsl:element name="a">
            <xsl:attribute name="href">
                <xsl:text>cgi/m/mec/hyp-idx?type=id&amp;id=</xsl:text>
                <xsl:value-of select="$RsomethingID"/>
            </xsl:attribute>
            <span class="STNCL">
                <xsl:value-of select="DATE"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="AUTHOR"/>
                <xsl:text> </xsl:text>
                <span class="STNCL_TITLE">
                    <xsl:value-of select="TITLE"/>
                </span>
                <xsl:text> (</xsl:text>
                <xsl:value-of select="MS"/>
                <xsl:text>)</xsl:text>
            </span>
        </xsl:element>
     </xsl:template>
    
    <xsl:template match="Q">
        <xsl:value-of select="."/>
        <xsl:text>  </xsl:text>
    </xsl:template>
    
    <!-- do we need to handle NOTE -->
    
    
</xsl:stylesheet>