<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="1.0">
    <xsl:output method="xml" indent="yes"  />
    <!--Extracts headwords and forms for indexing in solr
        Lets create solr docs for now
    -->
    
    <xsl:template match="/MED">
        <xsl:text>
        </xsl:text>
        <add>
            <doc>
                <xsl:text>
                </xsl:text>
                        <xsl:apply-templates select="ENTRYFREE"/>
                  <xsl:text>
                  </xsl:text>
            </doc>
        </add>
    </xsl:template>
    
    <xsl:template match="ENTRYFREE">
        <!-- grab id and seq number --> 
        <field name="ID">
            <xsl:value-of select="@ID"/>
        </field>
        <field name="SEQ">
            <xsl:value-of select="@SEQ"/>
        </field>
        <xsl:apply-templates select="FORM"/>
    </xsl:template>

<xsl:template match="FORM">
    <!-- deal with headwords being all the ORTHS before the POS
         <ORTH>furnais(e</ORTH>-eis<ORTH></ORTH><POS></POS>also<ORTH></ORTH><ORTH></ORTH>
         See 
    -->
   <form> 
    <xsl:for-each select="HDORTH">
        <foo>
            
        </foo>
        <xsl:apply-templates select="HDORTH"/>
    </xsl:for-each>
    
    <xsl:for-each select="ORTH">
        <xsl:apply-templates/>
    </xsl:for-each>
    
    <xsl:apply-templates select="POS"/>
   
   </form>
    </xsl:template>
    <xsl:template match="POS">
        <field name="POS">
            <xsl:value-of select="."/>
        </field>
    </xsl:template>
  
  <!-- test with multiple headwords -->
<xsl:template match="HDORTH">
    <field name="headword">
        <xsl:value-of select="REG"/>
    </field>
</xsl:template>  
    
 <xsl:template match="ORTH">
     <field name="form">
         <xsl:value-of select="REG"/>
     </field>
 </xsl:template>   
    
</xsl:stylesheet>