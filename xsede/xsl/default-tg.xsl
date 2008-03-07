<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- default-tg.xsl:  Prints table of suite(s) results.  Results are      -->
<!--                  customized for the security/globus-mds-auth suites. -->
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
      <xsl:with-param name="title" select="''" />
    </xsl:call-template>
    <!-- legend.xsl -->
    <xsl:call-template name="printLegend"/>
    <!-- printSuiteInfo -->
    <xsl:apply-templates select="suiteResults/suite" />
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSuiteInfo                                                       -->
  <!--                                                                      -->
  <!-- Calls printSeriesNamesTable and printSeriesResultsTable              -->
  <!-- ==================================================================== -->
  <xsl:template name="printSuiteInfo" match="suite">
    <h1 class="body"><xsl:value-of select="name"/></h1>
    <xsl:variable name="seriesNames"
                  select="distinct-values(reportSummary/nickname)"/>
    <!-- inca-common.xsl -->
    <xsl:if test="name[not(matches(., '^(tg-mds|security|globus-mds-auth|sdsc-ops)$'))]">
      <xsl:call-template name="printSeriesNamesTable">
        <xsl:with-param name="seriesNames" select="$seriesNames"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="count(/combo/resourceConfig)=1">
        <xsl:call-template name="printSeriesResultsTable">
          <xsl:with-param name="seriesNames" select="$seriesNames"/>
          <xsl:with-param
              name="resources"
              select="/combo/resourceConfig/resources/resource[name]"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="printSeriesResultsTable">
          <xsl:with-param name="seriesNames" select="$seriesNames"/>
          <xsl:with-param name="resources"
                          select="../resourceConfig/resources/resource[name]"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSeriesResultsTable                                              -->
  <!--                                                                      -->
  <!-- Prints a table with series results.                                  -->
  <!-- ==================================================================== -->
  <xsl:template name="printSeriesResultsTable">
    <xsl:param name="seriesNames"/>
    <xsl:param name="resources"/>
    <xsl:variable name="suite" select="."/>
    <xsl:for-each select="$seriesNames[.='mds.teragrid.org:8448']">
      <table class="subheader">
        <tr>
          <td class="subheader"/>
          <!-- inca-common.xsl printResourceNameCell -->
          <xsl:apply-templates select="$resources" mode="name">
            <xsl:sort/>
          </xsl:apply-templates>
        </tr>
        <tr>
          <td class="clear">
            <a name="{.}"><xsl:value-of select="."/></a>
          </td>
          <!-- printResourceResultCell -->
          <xsl:apply-templates select="$resources" mode="result">
            <xsl:sort/>
            <xsl:with-param name="testname" select="."/>
            <xsl:with-param name="suite" select="$suite"/>
          </xsl:apply-templates>
        </tr>
      </table><br/>
    </xsl:for-each>
    <table class="subheader">
      <xsl:for-each select="$seriesNames[.!='mds.teragrid.org:8448']">
        <xsl:sort/>
        <xsl:if test="position() mod 25 = 1">
          <tr>
            <td class="subheader"/>
            <!-- inca-common.xsl printResourceNameCell -->
            <xsl:apply-templates select="$resources" mode="name">
              <xsl:sort/>
            </xsl:apply-templates>
          </tr>
        </xsl:if>
        <tr>
          <td class="clear">
            <a name="{.}"><xsl:value-of select="replace(., '^all2all:gridftp_to_', '')" /></a>
          </td>
          <!-- printResourceResultCell -->
          <xsl:apply-templates select="$resources" mode="result">
            <xsl:sort/>
            <xsl:with-param name="testname" select="."/>
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
    <xsl:variable name="regexHost" select="concat('^', name, '$|',
        replace(macros/macro[name='__regexp__']/value, ' ','|'))"/>
    <xsl:variable name="result"
                  select="$suite/reportSummary[matches(hostname, $regexHost)
                  and nickname=$testname]" />
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
                  '&amp;resourceName=', name)"/>
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
               and string($comparitor)='')">
              <xsl:value-of select="'pass'" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'error'" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
                <xsl:variable
                    name="stats"
                    select="$result/body/performance/benchmark/statistics" />
        <xsl:choose>
          <xsl:when test="$exit!=''">
            <td class="{$exit}">
              <a href="{$href}" title="{$errMsg}">
                <xsl:variable
                    name="depth"
                    select="$stats/statistic[matches(., 'depth')]/value" />
                <xsl:variable
                    name="mdshost"
                    select="$stats/statistic[matches(., 'hostname')]/value" />
                <xsl:choose>
                  <xsl:when test="string($depth)!=''">
                    <xsl:value-of select="$depth"/>
                  </xsl:when>
                  <xsl:when test="string($mdshost)!=''">
                    <xsl:value-of select="$mdshost"/>
                  </xsl:when>
                  <xsl:when test="string($foundVersion)=''">
                    <xsl:value-of select="$exit"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$foundVersion" />
                  </xsl:otherwise>
                </xsl:choose>
              </a>
                <xsl:variable
                    name="env"
                    select="$stats/statistic[matches(., 'env')]/value" />
              <xsl:if test="string($env)!=''">
                <br/><br/><table><tr><td class="clear"><pre><xsl:value-of select="$env"/></pre></td></tr></table>
              </xsl:if>
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
