<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- instance-extra.xsl:  Prints instance rows with run-now and comments  -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:sdf="java.text.SimpleDateFormat"
                xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes">

  <!-- ==================================================================== -->
  <!-- Main template                                                        -->
  <!-- ==================================================================== -->
  <xsl:template name="instanceExtra">
    <xsl:param name="nickName"/>
    <xsl:param name="config"/>
    <tr>
      <td colspan="2" class="header">
        <xsl:text>Run now command (system admins only):</xsl:text>
      </td>
    </tr>
    <tr>
      <td colspan="2"><p class="code">
        <xsl:value-of select="concat('% cd ', replace(reporterPath,
          '/var/reporter-packages/bin/.*', ''), '; ./bin/teragrid-run-now ',
          $nickName, ' -L DEBUG')"/>
      </p></td>
    </tr>
    <xsl:if test="$url[not(matches(., 'noComment'))]">
      <tr><td colspan="2" class="header">
        <xsl:text>Comments:</xsl:text>
      </td></tr>
      <tr><td colspan="2">
        <xsl:choose>
          <xsl:when test="count(../../comments/row)>0">
            <xsl:apply-templates select="../../comments/row">
              <xsl:sort select="date" data-type="text" order="descending"/>
            </xsl:apply-templates>
            <hr/>
          </xsl:when>
          <xsl:otherwise>
            <p>No comments for this series.</p>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:variable name="confid" select="../seriesConfigId" /><br/>
        <form method="post" action="{replace(replace(replace($page, ':8080/',
          ':8443/'), 'http://', 'https://'), 'xslt.jsp', 'addDbCommentsForm.jsp')}">
          <input type="hidden" name="series" value="{$confid}"/>
          <input type="hidden" name="host" value="{hostname}"/>
          <input type="hidden" name="nickname" value="{$config/nickname}"/>
          <input type="hidden" name="login" value=""/>
          <input type="hidden" name="comment" value=""/>
          <input type="hidden" name="author" value=""/>
          <input type="submit" name="Submit" value="add a comment"/>
        </form>
      </td></tr>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
