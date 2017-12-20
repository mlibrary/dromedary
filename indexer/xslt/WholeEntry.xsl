<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="1.0">
    <xsl:output method="html" indent="yes"/>
    
    <xsl:variable name="quoteMode">compact</xsl:variable>
    
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
            <xsl:when test="$rendering='B'">
                <strong>
                    <xsl:value-of select="."/>
                </strong>
            </xsl:when>
            <xsl:when test="$rendering='I'">
                <em>
                    <xsl:value-of select="."/>
                </em>
            </xsl:when>
            <xsl:when test="$rendering='S'">
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
        <p><font face="Times OE" color="#ff0000"><strong>
            <xsl:value-of select="@N"/>
        </strong></font></p>
        <xsl:apply-templates select="DEF"/>
        
        <xsl:apply-templates select="EG"/>
        
    </xsl:template>
    <xsl:template match="EG">
        <blockquote>
        <font color="#ff0000"><strong>
        <xsl:text>(</xsl:text> 
                <xsl:value-of select="@N"/>
        <xsl:text>)</xsl:text>
        </strong></font>
            
            <xsl:choose>
            <xsl:when test="$quoteMode='open'">
                <xsl:apply-templates select="CIT" mode="open"/>
            </xsl:when>
            <xsl:when test="$quoteMode='compact'">
                <xsl:apply-templates select="CIT" mode="compact"/>
            </xsl:when>
            <xsl:otherwise>
                <!--don't show quotations -->
              <!--  <xsl:text>value of quotemode is
                                </xsl:text>
                <xsl:value-of select="$quoteMode"/> -->
            </xsl:otherwise>
        </xsl:choose>
        </blockquote>
    </xsl:template>
    
    <xsl:template match="DEF">
        <p>
        <xsl:apply-templates/>
        </p>
            <!--  <xsl:value-of select="."/>-->
    </xsl:template>
    
    
    <xsl:template match="CIT" mode="open" >
        <p>
        <xsl:apply-templates select="BIBL"/>
        <xsl:apply-templates select="Q"/>
        </p>
    </xsl:template>

    <xsl:template match="CIT" mode="compact">
       <xsl:apply-templates select="BIBL"/>
       <xsl:apply-templates select="Q"/>   
    </xsl:template>
    <!-- 
    
    
    -->
    <xsl:template match="BIBL">
        <xsl:apply-templates select="STNCL"/>
        
        <xsl:value-of select="text()"/>
        <xsl:text>: </xsl:text>
    </xsl:template>
    
    <xsl:template match="STNCL">
        <xsl:variable name="RsomethingID">
            <xsl:value-of select="@RID"/>
        </xsl:variable>    
        <xsl:element name="a">
            <xsl:attribute name="href">
                <xsl:text>cgi/m/mec/hyp-idx?type=id&amp;id=</xsl:text>
                <xsl:value-of select="$RsomethingID"/>
            </xsl:attribute>
            <b>
                <xsl:value-of select="DATE"/>
                <i>  <xsl:value-of select="TITLE"/></i>
                <xsl:text>(</xsl:text>
                <xsl:value-of select="MS"/>
                <xsl:text>)</xsl:text>          
            </b>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="Q">
        <xsl:value-of select="."/>
        <xsl:text>  </xsl:text>
    </xsl:template>
   

    <xsl:template match="ORTH">
       <xsl:text>
           
       </xsl:text>
        <strong>
            <xsl:value-of select="."/>
        </strong>
       
    </xsl:template>
    
    <xsl:template match="POS">
       
        <xsl:text>( </xsl:text>
        <xsl:value-of select="."/>
        <xsl:text> )</xsl:text>
       
    </xsl:template>
</xsl:stylesheet>