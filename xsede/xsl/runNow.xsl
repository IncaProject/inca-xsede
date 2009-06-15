<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- instance.xsl:  HTML table with report details.                       -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" >

  <xsl:include href="../xsl/inca-common.xsl"/>

  <xsl:param name="refreshPeriod"/>

  <!-- ==================================================================== -->
  <!-- Main template                                                        -->
  <!-- ==================================================================== -->
  <xsl:template match="/">
     <xsl:if test="error">
       <p><b>Error</b>: Unable to process run now request: 
          <xsl:value-of select="error"/>.  Please contact your Inca administrator.</p>
     </xsl:if>
     <xsl:variable name="nickname" select="runNowResult/nickname"/> 
     <xsl:variable name="reporter" select="runNowResult/reporter"/> 
     <xsl:if test="runNowResult/success">
       <h1 style="title">Request submitted</h1>
       <p>Run now request successfully submitted for <b><xsl:value-of
       select="runNowResult/nickname"/></b> series.  New results may take up to <xsl:value-of select="$refreshPeriod"/> minutes to propagate to these web pages.</p>
     </xsl:if>
      <form method="POST" action="Javascript:history.go(-1)">
        <input type="submit" value="Go Back" name="Back"/>
      </form>
     <h1 style="title">Search or share troubleshooting information</h1>
     <p>If you are troubleshooting a problem, please click the <b>search knowledge
	base</b> button below to find out more information about this series.  Or
        if you would like to start a new knowledge base article or add to an 
        existing one, click the <b>add to knowledge base</b> button. </p>
    <table><tr><td>
    <form method="get" action="http://www.teragrid.org/cgi-bin/kb.cgi">
      <input type="hidden" name="docid" value="aycv"/>
      <input type="submit" value="search knowledge base"/>
    </form></td><td>
    <form method="get" action="addKnowledgeBase.jsp">
      <input type="hidden" name="nickname" value="{$nickname}"/>
      <input type="hidden" name="reporter" value="{$reporter}"/>
      <input type="hidden" name="error" value=""/>
      <input type="submit" value="add to knowledge base"/>
    </form></td><td>
    </td></tr>
    </table>

  </xsl:template>

</xsl:stylesheet>
