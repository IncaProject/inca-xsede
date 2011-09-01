<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- def2config.xsl:  Converts CTSS kit definition into incat config.     -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml" >

  <xsl:template name="generateXML" match="/kits">
    <kits>
    <xsl:apply-templates select="kit" />
    </kits>
  </xsl:template>

  <xsl:template name="convertKit" match="kit">
      <kit>
        <xsl:variable name="kit" select="."/>
        <resource><xsl:value-of select="concat(@name,'-',@version)"/></resource>
        <xsl:for-each select="package">
          <xsl:variable name="package" select="."/>
          <software>
            <macro><xsl:value-of select="concat($kit/@name,$kit/@version,'-',name,'-software')"/></macro>
            <xsl:for-each select="variable">
              <macro><xsl:value-of select="concat($kit/@name,$kit/@version,'-',$package/name,'-',@name)"/></macro>
            </xsl:for-each>
            <xsl:if test="version">
              <macro>
                <name><xsl:value-of select="concat($kit/@name,$kit/@version,'-',$package/name,'-version')"/></name>
                <xsl:choose><xsl:when test="matches(version, '^[&lt;&gt;=].*$')">
                  <value><xsl:value-of select="version"/></value>
                </xsl:when><xsl:otherwise>
                  <value>/<xsl:value-of select="version"/>/</value>
                </xsl:otherwise></xsl:choose>
              </macro>
            </xsl:if>
            <expression>sw[matches(Name,'<xsl:value-of select="name"/>')]</expression>
            <xsl:if test="$kit/@type = 'variable' or type = 'optional'">
              <resource><xsl:value-of select="concat($kit/@name,$kit/@version,'-',name)"/></resource>
            </xsl:if>
          </software>
        </xsl:for-each>
        <xsl:for-each select="service">
          <xsl:variable name="service" select="."/>
          <software>
            <macro><xsl:value-of select="concat($kit/@name,$kit/@version,'-',name,'-software')"/></macro>
            <expression>service[Name = '<xsl:value-of select="name"/>']</expression>
            <xsl:if test="$kit/@type = 'variable' or type = 'optional'">
              <resource><xsl:value-of select="concat($kit/@name,$kit/@version,'-',name)"/></resource>
            </xsl:if>
          </software>
        </xsl:for-each>
      </kit>
  </xsl:template>

</xsl:stylesheet>


