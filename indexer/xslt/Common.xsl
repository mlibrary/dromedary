<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">


    <!--#######################
        Common.xsl
        Currently includes HI, USG, NOTE
           ########################-->

    <!--need to fix rend stuff but try this for now
    
    85975 <HI REND="B">
 502 <HI REND="I">
 
 238 <HI REND="S">
 166 <HI REND="SUP">
 20 <HI REND="b">
   4 <HI REND="bold">
   1 <HI REND="i">

USG tags
 326 <USG TYPE="SYNTAX" REND="NORM">
 141 <USG TYPE="DEF" REND="NORM">
  10 <USG REND="NORM">


   XXX Ask pfs if USG types or rend tags are actually used for anything
   if so will need to have code look at USG attributes and do something!
    -->

    <xsl:template match="HI">
        <xsl:variable name="rendering">
            <xsl:value-of select="@REND"/>
        </xsl:variable>
        <span>
            <xsl:attribute name="class">
                <!--XXX replace _ with space for 2 classes later-->
                <xsl:text>HI_</xsl:text>
                <!-- Normalize variants -->
                <xsl:choose>
                    <xsl:when test="$rendering ='S'">
                        <xsl:text>SUP</xsl:text>
                    </xsl:when>
                    <xsl:when test="$rendering='b'">
                        <xsl:text>B</xsl:text>
                    </xsl:when>
                    <xsl:when test="$rendering='bold'">
                        <xsl:text>B</xsl:text>
                    </xsl:when>
                    <xsl:when test="$rendering='i'">
                        <xsl:text>I</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$rendering"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:value-of select="."/>
        </span>
    </xsl:template>

    <!-- XXX TODO:  What do we do here?
        Asked pfs re: attributes being used for anything
        YES
        1) REND tag:
        default rendering = italie
        REND=norm  don't do italic
        2) TYPE tag does not affect rendering, but could be used for faceting
        3) EXPAND tag
    -->
    <xsl:template match="USG">
        <span>
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="@REND = 'NORM'">USG_NORM</xsl:when>
                    <xsl:otherwise>USG</xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>


    <xsl:template match="//DATE|//AUTHOR|//TITLE|//CIT|//SCOPE|//BIBL|//TAX|//NOTE|//EG">
        <span>
            <xsl:attribute name="class">
                <xsl:value-of select="local-name()"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>



</xsl:stylesheet>
