<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- tg-mds.xsl:  Prints table of results for tg-mds suite.               -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xsl:include href="inca-common.xsl"/>
  <xsl:include href="header.xsl"/>
  <xsl:include href="legend.xsl"/>
  <xsl:include href="footer.xsl"/>
  <xsl:param name="url" />

  <!-- ==================================================================== -->
  <!-- Main template                                                        -->
  <!-- ==================================================================== -->
  <xsl:template match="/">
    <!-- header.xsl -->
    <xsl:call-template name="header"/>
    <body topMargin="0">
      <xsl:choose>
        <xsl:when test="count(error)>0">
          <!-- inca-common.xsl printErrors -->
          <xsl:apply-templates select="error" />
        </xsl:when>
        <xsl:otherwise>
          <!-- generateHTML -->
          <xsl:apply-templates select="combo" />
        </xsl:otherwise>
      </xsl:choose>
    </body>
    <!-- footer.xsl -->
    <xsl:call-template name="footer"/>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- generateHTML                                                         -->
  <!--                                                                      -->
  <!-- Prints an html header with a page title and a legend.                -->
  <!-- Calls printSuiteInfo.                                                -->
  <!-- ==================================================================== -->
  <xsl:template name="generateHTML" match="combo">
    <!-- inca-common.xsl -->
    <xsl:call-template name="printBodyTitle">
      <xsl:with-param name="title" select="tgwide/id" />
    </xsl:call-template>
    <!-- legend.xsl -->
    <xsl:call-template name="printLegend"/>
    <!-- printSuiteInfo -->
    <xsl:apply-templates select="suiteResults/suite" />
  </xsl:template>
  
  <!-- ==================================================================== -->
  <!-- printSeriesResultsTable                                              -->
  <!--                                                                      -->
  <!-- Prints a table with series results.                                  -->
  <!-- ==================================================================== -->
  <xsl:template name="printSeriesResultsTable" match="suite">
    <xsl:variable name="seriesNames" select="/combo/tgwide/services/service"/>
    <xsl:variable name="resources" select="/combo/tgwide/resources[resource]"/>
    <xsl:variable name="suite" select="."/>
    <table class="subheader">
      <tr>
        <td class="subheader"/>
        <!-- inca-common.xsl printResourceNameCell -->
        <xsl:apply-templates select="$resources" mode="name"/>
      </tr>
      <xsl:for-each select="$seriesNames">
        <tr>
          <td class="clear">
            <xsl:value-of select="concat(name,' ',port)"/>
          </td>
          <!-- printResourceResultCell -->
          <xsl:apply-templates select="$resources" mode="result">
            <xsl:sort/>
            <xsl:with-param name="testname" select="name"/>
            <xsl:with-param name="suite" select="$suite"/>
          </xsl:apply-templates>
        </tr>
      </xsl:for-each>
    </table>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printResourceResultCell                                              -->
  <!--                                                                      -->
  <!-- Prints a table cell with resource result.                            -->
  <!-- ==================================================================== -->
  <xsl:template name="printResourceResultCell" match="resource" mode="result">
    <xsl:param name="testname"/>
    <xsl:param name="suite"/>
    <xsl:variable name="regex" select="concat( name,'.*(',$testname,')' )"/>
    <xsl:variable name="result"
                  select="$suite/reportSummary[matches(nickname, $regex)]" />
    <xsl:variable name="instance" select="$result/instanceId" />
    <xsl:variable name="comparitor" select="$result/comparisonResult" />
    <xsl:variable name="foundVersion" select="$result/body/package/version" />
    <xsl:variable name="errMsg" select="$result/errorMessage" />
    <xsl:choose>
      <xsl:when test="count($result)>0">
        <!-- resource is not exempt -->
        <xsl:variable name="normRef" 
                  select="concat('xslt.jsp?xsl=instance.xsl&amp;instanceID=',
                  $instance, '&amp;configID=', $result/seriesConfigId,
                  '&amp;resourceName=repo')"/>
        <xsl:variable name="href">
        <xsl:call-template name="getLink">
          <xsl:with-param name="errMsg" select="$errMsg"/>
          <xsl:with-param name="normRef" select="$normRef"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="exit">
          <xsl:choose>
            <xsl:when test="count($result/body)=0">
              <xsl:value-of select="''" />
            </xsl:when>
            <xsl:when test="$errMsg[matches(., '^DOWNTIME:.*: ')]">
              <xsl:value-of select="'down'" />
            </xsl:when>
            <xsl:when test="$comparitor='Success' or
              (string($result/body)!=''
               and string($errMsg)=''
               and string($comparitor)='' )">
               <xsl:value-of select="'pass'" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'error'" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$exit!=''">
            <td class="{$exit}">
              <a href="{$href}" title="{$errMsg}">
                <xsl:choose>
                  <xsl:when test="string($foundVersion)=''">
                    <xsl:value-of select="$exit"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$foundVersion" />
                  </xsl:otherwise>
                </xsl:choose>
              </a>
              <xsl:if test="$exit='down'">
                <xsl:value-of select="' '" />
                <a href="{$normRef}" title="{$errMsg}">err</a>
              </xsl:if>
              <!-- inca-common.xsl -->
              <xsl:call-template name="markOld">
                <xsl:with-param name="gmtExpires" select="$result/gmtExpires" as="xs:dateTime"/>
              </xsl:call-template>
            </td>
          </xsl:when>
          <!-- missing data -->
          <xsl:otherwise>
            <td class="clear"><xsl:value-of select="' '" /></td>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <!-- resource is exempt -->
        <td class="na">
          <xsl:text>n/a</xsl:text>
        </td>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
