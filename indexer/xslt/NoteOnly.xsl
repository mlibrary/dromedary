<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">
	<xsl:import href="./indexer/xslt/Common.xsl"/>  
   <xsl:output method="html" indent="yes"/>
  
    <xsl:template match="/NOTE">
         <div class="NOTE">
               <xsl:apply-templates/>
        </div>
    </xsl:template>
       
    <!--ignore for now one instance each of NOTE containing XREF/POS, XREF/HI POS and LANG -->
</xsl:stylesheet>
