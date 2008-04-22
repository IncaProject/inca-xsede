<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- sw-menu.xsl:  Drop down menus to select resources for swStack-tg.xsl -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml">

  <xsl:template name="sw-menu">
    <xsl:variable name="suiteNames">
      <xsl:analyze-string select="$queryStr" regex="(.*)suiteNames=(.[^&amp;]*)(.*)">
        <xsl:matching-substring>
          <xsl:value-of select="regex-group(2)"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:value-of select="'ctss-v3'"/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:variable name="xml">
      <xsl:analyze-string select="$queryStr" regex="(.*)xml=(.[^&amp;]*)(.*)">
        <xsl:matching-substring>
          <xsl:value-of select="regex-group(2)"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:value-of select="'ctssv3.xml'"/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <form method="get" action="status.jsp" name="form">
      <table cellpadding="2">
        <tr>
          <td> <p>RESOURCE:<br/>
            <select name="resourceIds">
              <option value="select">- Select One -</option>
              <xsl:for-each select="/combo/resourceConfig/resources/resource[name]">
                <xsl:sort select="." />
                <xsl:variable name="name" select="name" />
                <option value="{$name}"><xsl:value-of select="name"/></option>
              </xsl:for-each>
              <option value="teragrid">TeraGrid</option>
              <option value="ANL">ANL</option>
              <option value="Indiana">Indiana</option>
              <option value="LONI">LONI</option>
              <option value="NCAR">NCAR</option>
              <option value="NCSA">NCSA</option>
              <option value="ORNL">ORNL</option>
              <option value="PSC">PSC</option>
              <option value="Purdue">Purdue</option>
              <option value="SDSC">SDSC</option>
              <option value="TACC">TACC</option>
            </select>
          </p>
          </td>
          <td>
            <input type="hidden" name="suiteNames" value="{$suiteNames}"/>
            <input type="hidden" name="xml" value="{$xml}"/>
            <input type="hidden" name="xsl" value="swStack.xsl"/>
            <input type="submit" name="Submit" value="Submit"/></td>
        </tr></table>
    </form>
  </xsl:template>

</xsl:stylesheet>
