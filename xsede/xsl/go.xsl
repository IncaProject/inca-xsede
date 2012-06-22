<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- default.xsl:  Prints table of suite(s) results.                      -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:quer="http://inca.sdsc.edu/dataModel/queryResults_2.0"
                xmlns:rs="http://inca.sdsc.edu/queryResult/reportSummary_2.0"
                xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xsl:include href="../xsl/inca-common26.xsl"/>
  <xsl:param name="queryStr"/>

  <!-- ==================================================================== -->
  <!-- generateHTML                                                         -->
  <!--                                                                      -->
  <!-- Prints legend and calls printSuiteInfo.                              -->
  <!-- ==================================================================== -->
  <xsl:template name="generateHTML" match="/combo">
    <!-- inca-common.xsl -->
    <xsl:if test="not(contains($queryStr,'noDescription=true'))">
      <xsl:call-template name="printBodyTitle">
        <xsl:with-param name="title" select="'Inca GO results'"/>
      </xsl:call-template>
      <p>Each GO transfer test is executed from gw60.quarry.iu.teragrid and
         executes GO commands by gsissh'ing into cli.globusonline.org.
         For each endpoint listed in the rows below, the test does an
         "endpoint-activate -g xsede#*" to get the available list of 
         XSEDE endpoints.  It then randomly selects one of the endpoints
         in the list to be the source endpoint and an attempt is made to
         tranfer a 100MB file to each filesystem of the destination endpoint.
         If the transfer fails or the source endpoint is having problems, 
         another source endpoint is randomly selected from the list.  If
         3 attempts fail, a failure is assumed on the destination endpoint.
      </p><p>
         Click on selected
         icons (described in the <a href="javascript:window.open('/inca/jsp/legend.jsp','incalegend','width=400,height=325,resizable=yes')">legend</a>) for more details about the 
         collected Inca report.</p>
       <p>Click <a href="/inca/jsp/report.jsp?xml=goReport.xml">here for historical report</a>.</p>
    </xsl:if>

    <!-- printSuiteInfo -->
    <xsl:apply-templates select="suites/suite|queries/query" />
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSeriesResultsTable                                              -->
  <!--                                                                      -->
  <!-- Prints a table with series results.                                  -->
  <!-- ==================================================================== -->
  <xsl:template name="printSeriesResultsTable" match="suite|query">
    <xsl:variable name="suite" select="."/>

    <xsl:variable name="defaultconfig" select="document('../xml/default.xml')/default"/>

    <table class="subheader">
      <tr><td><b>Resource</b></td><td align="center"><p><b>Filesystems</b></p></td></tr>
      <xsl:for-each select="$suite/quer:object//rs:reportSummary">
        <xsl:sort select="nickname"/>

        <xsl:variable name="errMsg" select="errorMessage" />
        <xsl:variable name="normRef">
          <xsl:choose><xsl:when test="gmt">
            <xsl:value-of select="concat('/inca/jsp/instance.jsp?nickname=', encode-for-uri(nickname), '&amp;resource=', hostname, '&amp;target=', targetHostname, '&amp;collected=', gmt)"/>
          </xsl:when><xsl:otherwise>
            <xsl:value-of select="concat('/inca/jsp/runNow.jsp?configId=', seriesConfigId)"/>
          </xsl:otherwise></xsl:choose>
        </xsl:variable>
        <xsl:variable name="href"><xsl:call-template name="getLink">
          <xsl:with-param name="errMsg" select="$errMsg"/>
          <xsl:with-param name="normRef" select="$normRef"/>
          <xsl:with-param name="downtimeUrl" select="$defaultconfig/downtimeUrl"/>
        </xsl:call-template></xsl:variable>
        <xsl:variable name="state"><xsl:choose><xsl:when test="not(body/transfers)">
          <xsl:call-template name="getStatus">
            <xsl:with-param name="result" select="."/>
            <xsl:with-param name="states" select="$defaultconfig/incaResult"/>
          </xsl:call-template>
        </xsl:when><xsl:otherwise>
          <xsl:variable name="transferResult"><xsl:choose>
            <xsl:when test="body/transfers/@errors&gt;0">error</xsl:when>
            <xsl:otherwise>pass</xsl:otherwise>
          </xsl:choose></xsl:variable>
          <xsl:variable name="transferWarns">
            <xsl:if test="body/transfers/@warnings&gt;0">warnings</xsl:if>
          </xsl:variable>
          <xsl:value-of select="$defaultconfig/incaResult/primaryState[@name=$transferResult]/@bgcolor"/>|<xsl:value-of select="$defaultconfig/incaResult/primaryState[@name=$transferResult]/@img"/>|<xsl:value-of select="$defaultconfig/incaResult/secondaryState[@name=$transferWarns]/@text"/>
        </xsl:otherwise></xsl:choose>
        </xsl:variable>
        <xsl:variable name="bgcolor" select="tokenize($state,'\|')[1]"/>
        <xsl:variable name="img" select="tokenize($state,'\|')[2]"/>
        <xsl:variable name="text" select="tokenize($state,'\|')[3]"/>
        <xsl:variable name="passImg" select="$defaultconfig/incaResult/primaryState[@name='pass']/@img"/>
        <xsl:variable name="failImg" select="$defaultconfig/incaResult/primaryState[@name='error']/@img"/>

        <tr>
          <td class="clear"><xsl:value-of select="replace(nickname,'go-transfers_to_','')"/></td>
          <td bgcolor="{$bgcolor}" align="center">
            <a href="{$href}" title="{$errMsg}" id="statuscell" >
            <xsl:if test="$img!='' and body=''">
              <img src="{concat('/inca/img/', $img)}"/>
                <xsl:if test="$href != $normRef">
                  <a style="text-decoration:none; text-size: tiny" href="{$normRef}">*</a>
                </xsl:if>
              </xsl:if> 
            </a>
            <xsl:if test="body/transfers">
              <xsl:variable name="numErrors" select="body/transfers/@errors"/>
              <xsl:variable name="numTransfers" select="count(body/transfers/transfer)"/>
              <a href="{$href}" title="{$errMsg}" id="statuscell" >
              <table width="100%">
              <xsl:for-each select="body/transfers/transfer">
                <xsl:variable name="resultImg"><xsl:choose>
                  <xsl:when test="@result=1"><xsl:value-of select="$passImg"/></xsl:when>
                  <xsl:otherwise><xsl:value-of select="$failImg"/></xsl:otherwise>
                </xsl:choose></xsl:variable>
                <tr>
                  <td align="center"><b><xsl:value-of select="@dest"/>/<xsl:value-of select="."/></b></td>
                  <td align="right"><img width="20" src="{concat('/inca/img/', $resultImg)}"/></td>
                </tr>
              </xsl:for-each>
              </table>
              </a>
              <a class="footer" title="from randomly selected host(s)">* from 
              <xsl:choose><xsl:when test="$numErrors=0">
                <span class="footer"><xsl:value-of select="distinct-values(body/transfers/transfer/@source)"/></span>
              </xsl:when><xsl:otherwise>
                <span class="footer"><xsl:value-of select="string-join(body/transfers/source, ', ')"/></span>
              </xsl:otherwise></xsl:choose>
              </a>
            </xsl:if> 
          </td>
        </tr>
      </xsl:for-each>
    </table>
  </xsl:template>

</xsl:stylesheet>
