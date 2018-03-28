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
            <xsl:value-of select="$rendering"/>
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
          <span class="USG">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <!--XXX notes fix this-->
    <xsl:template match="NOTE|note">
        <H1>THIS IS A NOTE</H1>
        <xsl:apply-templates/>
     </xsl:template>
    
    
</xsl:stylesheet>