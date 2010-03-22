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
    <tr><td colspan="2" class="header">
      <xsl:text>Test Configuration Comments:</xsl:text>
    </td></tr>
    <tr><td colspan="2">
      <xsl:choose>
        <xsl:when test="count(/instance/comments/row)>0">
          <xsl:apply-templates select="/instance/comments/row">
            <xsl:sort select="date" data-type="text" order="descending"/>
          </xsl:apply-templates>
          <hr/>
        </xsl:when>
        <xsl:otherwise>
          <p>No comments for this series.</p>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="confid" select="../seriesConfigId" /><br/>
      <form method="get" action="addDbCommentsForm.jsp">
        <input type="hidden" name="series" value="{$confid}"/>
        <input type="hidden" name="host" value="{hostname}"/>
        <input type="hidden" name="nickname" value="{$config/nickname}"/>
        <input type="hidden" name="login" value=""/>
        <input type="hidden" name="comment" value=""/>
        <input type="hidden" name="author" value=""/>
        <input type="submit" name="Submit" value="add a comment"/>
      </form>
    </td></tr>
  </xsl:template>

  <xsl:template name="knowledgeBase">
    <xsl:param name="nickName"/>
    <xsl:param name="reporterName"/>
    <xsl:param name="errMsg"/>
    
    <tr><td>
    <form method="get" action="https://www.teragrid.org/web/user-support/kb?p_p_id=knowledgebase_WAR_knowledgebaseportlet">
      <input type="hidden" name="p_p_id" value="knowledgebase_WAR_knowledgebaseportlet"/>
      <input type="hidden" name="p_p_lifecycle" value="0"/>
      <input type="hidden" name="p_p_state" value="normal"/>
      <input type="hidden" name="p_p_mode" value="view"/>
      <input type="hidden" name="p_p_col_id" value="column-1"/>
      <input type="hidden" name="p_p_col_pos" value="1"/>
      <input type="hidden" name="p_p_col_count" value="2"/>
      <input type="hidden" name="_knowledgebase_WAR_knowledgebaseportlet_docid" value="aycv#tabletop"/>
      <input type="hidden" name="terms" 
             value="{concat($errMsg,' or ',$nickName,' or ',$reporterName,' or Common Inca Errors')}"/>
      <input type="submit" value="search knowledge base"/>
    </form></td><td>
    <form method="get" action="addKnowledgeBase.jsp">
      <input type="hidden" name="nickname" value="{$nickName}"/>
      <input type="hidden" name="reporter" value="{$reporterName}"/>
      <input type="hidden" name="error" value="{$errMsg}"/>
      <input type="submit" value="add to knowledge base"/>
    </form></td></tr>
  </xsl:template>

</xsl:stylesheet>
