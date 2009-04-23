<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <xsl:output method="xml" omit-xml-declaration="yes"/> 
  
  <xsl:template match="/">
    <xsl:for-each select="//KitRegistration">
      <xsl:sort select="ResourceID"/>
      <xsl:value-of select="ResourceID"/>
<xsl:text>
</xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
