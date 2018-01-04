<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="1.0">
    <xsl:output method="html" indent="yes"/>

    <xsl:variable name="quoteMode">compact</xsl:variable>
    <!-- orig|new -->
    <xsl:variable name="formMode">new</xsl:variable>
    <xsl:template match="/MED/ENTRYFREE">

        <html>
            <head> </head>
            <body>
                <!-- do we need foreach? -->
                <xsl:apply-templates select="FORM"/>
                <xsl:apply-templates select="ETYM"/>
                <xsl:for-each select="SENSE">
                    <xsl:apply-templates select="."/>
                </xsl:for-each>
                <div>
                    <em>
                        <xsl:text>
                            Supplement
                        </xsl:text>
                    <xsl:attribute name="class">supp</xsl:attribute>
                <xsl:apply-templates select="supplement"/>
                    </em>
                </div>
            </body>
        </html>
    </xsl:template>


    <xsl:template match="TITLE">
        <em>
            <xsl:value-of select="."/>
        </em>
    </xsl:template>
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

    <xsl:template match="LANG">
        <!--XXX need mouseover stuff here-->
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="FORM">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="ETYM">
        <blockquote>
            <p align="right">
                <xsl:apply-templates/>
            </p>
        </blockquote>
    </xsl:template>

    <xsl:template match="SENSE">
        <p>
            <font face="Times OE" color="#ff0000">
                <strong>
                    <xsl:value-of select="@N"/>
                </strong>
            </font>
        </p>
        <xsl:apply-templates select="DEF"/>

        <xsl:apply-templates select="EG"/>

    </xsl:template>
    <xsl:template match="EG|eg">
       
        <blockquote>
            <xsl:if test="@N">
            <font color="#ff0000">
                <strong>
                    <xsl:text>(</xsl:text>
                    <xsl:value-of select="@N"/>
                    <xsl:text>)</xsl:text>
                </strong>
            </font>
            </xsl:if>
            
            <xsl:choose>
                <xsl:when test="$quoteMode = 'open'">
                    <xsl:apply-templates select="CIT|cit" mode="open"/>
                </xsl:when>
                <xsl:when test="$quoteMode = 'compact'">
                    <xsl:apply-templates select="CIT|cit" mode="compact"/>
                </xsl:when>
                <xsl:otherwise>
                    <!--don't show quotations -->
                    <!--  <xsl:text>value of quotemode is
                                </xsl:text>
                <xsl:value-of select="$quoteMode"/> -->
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="NOTE|note"/>
        </blockquote>
    </xsl:template>

    <xsl:template match="DEF">
        <p>
            <xsl:apply-templates/>
        </p>
        <!--  <xsl:value-of select="."/>-->
    </xsl:template>


    <xsl:template match="CIT|cit" mode="open">
        <p>
            <xsl:apply-templates select="BIBL|bibl"/>
            <xsl:apply-templates select="Q|q"/>
        </p>
    </xsl:template>

    <xsl:template match="CIT|cit" mode="compact">
        <xsl:apply-templates select="BIBL|bibl"/>
        <xsl:apply-templates select="Q|q"/>
    </xsl:template>
    <!-- 
    
    
    -->
    <xsl:template match="BIBL|bibl">
        <xsl:apply-templates select="STNCL|stncl"/>

        <xsl:value-of select="text()"/>
        <xsl:text>: </xsl:text>
    </xsl:template>

    <xsl:template match="STNCL|stncl">
        <xsl:variable name="RsomethingID">
            <xsl:value-of select="@RID"/>
        </xsl:variable>
        <xsl:element name="a">
            <xsl:attribute name="href">
                <xsl:text>cgi/m/mec/hyp-idx?type=id&amp;id=</xsl:text>
                <xsl:value-of select="$RsomethingID"/>
            </xsl:attribute>
            <b>
                <xsl:value-of select="DATE|date"/>
                <i>
                    <xsl:value-of select="TITLE|title"/>
                </i>
                <xsl:text>(</xsl:text>
                <xsl:value-of select="MS|ms"/>
                <xsl:text>)</xsl:text>
            </b>
        </xsl:element>
    </xsl:template>

    <xsl:template match="Q|q">
        <xsl:value-of select="."/>
        <xsl:text>  </xsl:text>
    </xsl:template>





    <xsl:template match="HDORTH">
        <span>
            <xsl:attribute name="class">headword</xsl:attribute>
            <strong>
                <xsl:call-template name="ORIG_OR_REG"/>
            </strong>
        </span>
    </xsl:template>

    <xsl:template match="ORTH">
        <span>
            <xsl:attribute name="class">form</xsl:attribute>
            <strong>
                <xsl:call-template name="ORIG_OR_REG"/>
            </strong>
        </span>
    </xsl:template>

    <xsl:template name="ORIG_OR_REG">
        <xsl:choose>
            <xsl:when test="$formMode = 'orig'">
                <xsl:apply-templates select="ORIG"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="DO_REG"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="ORIG">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template name="DO_REG">
        <!-- put comma after reg unless it is the last one-->
        <xsl:for-each select="REG">
            <xsl:value-of select="."/>
            <xsl:if test="not(position() = last())">
                <xsl:text>, </xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>



    <xsl:template match="POS">

        <xsl:text>( </xsl:text>
        <xsl:value-of select="."/>
        <xsl:text> )</xsl:text>

    </xsl:template>
    <xsl:template match="supplement">
        <xsl:apply-templates select="eg"/>
    </xsl:template>
    
    <xsl:template match="NOTE|note">
        <div>
            <str>
            <xsl:attribute name="class">note</xsl:attribute>
        <xsl:value-of select="."/>
            </str>
        </div>
    </xsl:template>
</xsl:stylesheet>
