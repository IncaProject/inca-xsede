<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- reqs2config.xsl:  Converts CTSS kit definition into incat config.     -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:iis="http://www.xsede.org/iis"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml" >

  <xsl:output method="xml" indent="yes"/>
  <xsl:preserve-space elements="* iis:*"/>
  <!-- ==================================================================== -->
  <!-- Main template                                                        -->
  <!-- ==================================================================== -->
  <xsl:template name="generateXML" match="/config">
    <inca:inca xmlns:inca="http://inca.sdsc.edu/dataModel/inca_2.0">
      <repositories>
      <xsl:copy-of select="properties/repository"/>
      </repositories>
    </inca:inca>

  </xsl:template>

</xsl:stylesheet>


