<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="1.0">
    <xsl:import href="Common.xsl"/>
    <xsl:output method="html" indent="yes"/>
    
  
    <!-- orig|new -->
    <xsl:variable name="formMode">orig</xsl:variable>
    <xsl:template match="/FORM">
        
        <html>
            <head> Form Only</head>
            <body>
                <!-- do we need foreach? -->
                <xsl:apply-templates/>
                            </body>
        </html>
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
</xsl:stylesheet>
