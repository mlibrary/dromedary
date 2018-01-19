require 'semantic_logger'
module Dromedary
  class Entry
    module Constants



      SemanticLogger.add_appender(io: STDERR, level: :info)
      LOGGER = SemanticLogger['Entry']


      UGS = %w[
agr
alch
anat
arch
arith
arm
astrol
astron
bibl
bot
chess
cook
cost
eccl
geom
gram
hawk
her
hunt
law
liturg
math
med
mil
mus
naut
palm
pathol
phil
phys
physiol
surg
theol

biol
bot
canon law
cosmol
divination
ethics
fish
game
geog
geomancy
lapid
lit
logic
met
myth
pharm
poet
psych
scot
      ]


      XSLSS = <<-EOXSL
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:param name="indent-increment" select="'   '"/>
  <xsl:template name="newline">
    <xsl:text disable-output-escaping="yes">
</xsl:text>
  </xsl:template>
  <xsl:template match="comment() | processing-instruction()">
    <xsl:param name="indent" select="''"/>
    <xsl:call-template name="newline"/>
    <xsl:value-of select="$indent"/>
    <xsl:copy />
  </xsl:template>
  <xsl:template match="text()">
    <xsl:param name="indent" select="''"/>
    <xsl:call-template name="newline"/>
    <xsl:value-of select="$indent"/>
    <xsl:value-of select="normalize-space(.)"/>
  </xsl:template>
  <xsl:template match="text()[normalize-space(.)='']"/>
  <xsl:template match="*">
    <xsl:param name="indent" select="''"/>
    <xsl:call-template name="newline"/>
    <xsl:value-of select="$indent"/>
      <xsl:choose>
       <xsl:when test="count(child::*) > 0">
        <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates select="*|text()">
           <xsl:with-param name="indent" select="concat ($indent, $indent-increment)"/>
         </xsl:apply-templates>
         <xsl:call-template name="newline"/>
         <xsl:value-of select="$indent"/>
        </xsl:copy>
       </xsl:when>
       <xsl:otherwise>
        <xsl:copy-of select="."/>
       </xsl:otherwise>
     </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
      EOXSL

      XSL = Nokogiri::XSLT(XSLSS)

    end
  end
end

