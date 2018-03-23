<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

<!--#######################
        Common.xsl
        Currently includes HI, USG, NOTE
        #XXX 
    ########################-->

    <!--need to fix rend stuff but try this for now
    
    85975 <HI REND="B">
 502 <HI REND="I">
 326 <USG TYPE="SYNTAX" REND="NORM">
 238 <HI REND="S">
 166 <HI REND="SUP">
 141 <USG TYPE="DEF" REND="NORM">
  20 <HI REND="b">
  10 <USG REND="NORM">
   4 <HI REND="bold">
   1 <HI REND="i">
    -->
    
    <xsl:template match="HI">
        <xsl:variable name="rendering">
            <xsl:value-of select="@REND"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$rendering = 'B'">
                <strong>
                    <xsl:value-of select="."/>
                </strong>
            </xsl:when>
            <xsl:when test="$rendering = 'I'">
                <em>
                    <xsl:value-of select="."/>
                </em>
            </xsl:when>
            <xsl:when test="$rendering = 'S'">
                <!-- can't find example of this-->
                <strong>
                    <xsl:value-of select="."/>
                </strong>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- XXX TODO:  What do we do here?
        Asked pfs re: attributes being used for anything
    -->
    <xsl:template match="USG">
        <em>
            <xsl:apply-templates/>
        </em>
    </xsl:template>
    <!--XXX notes fix this-->
    <xsl:template match="NOTE|note">
        <H1>THIS IS A NOTE</H1>
        <xsl:apply-templates/>
     </xsl:template>
    
    
</xsl:stylesheet>