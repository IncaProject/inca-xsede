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

  <xsl:include href="../xsl/inca-common.xsl"/>
  <xsl:include href="../xsl/legend.xsl"/>

  <!-- ==================================================================== -->
  <!-- generateHTML                                                         -->
  <!--                                                                      -->
  <!-- Prints legend and calls printSuiteInfo.                              -->
  <!-- ==================================================================== -->
  <xsl:template name="generateHTML" match="/combo">
    <!-- inca-common.xsl -->
    <xsl:call-template name="printBodyTitle">
      <xsl:with-param name="title" select="''"/>
    </xsl:call-template>
    <!-- legend.xsl -->
    <xsl:call-template name="printLegend"/>
    <!-- printSuiteInfo -->
    <xsl:apply-templates select="suites/suite|queries/query" />
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSuiteInfo                                                       -->
  <!--                                                                      -->
  <!-- Calls printSeriesNamesTable and printSeriesResultsTable              -->
  <!-- ==================================================================== -->
  <xsl:template name="printSuiteInfo" match="suite|query">
    <xsl:variable name="name" select="name"/>
    <xsl:choose>
    <xsl:when test="name[matches(., '^tg-mds$')]">
    <xsl:call-template name="printMdsResultsTable"/>
    </xsl:when>
    <xsl:otherwise>
    <h1><xsl:value-of select="$name"/></h1>
    <xsl:variable name="seriesNames"
         select="distinct-values(quer:object//rs:reportSummary/nickname)"/>
    <!-- inca-common.xsl -->
    <xsl:if test="name[not(matches(., '^(security|sdsc-ops)$'))]">
    <xsl:call-template name="printSeriesNamesTable">
      <xsl:with-param name="seriesNames" select="$seriesNames"/>
    </xsl:call-template>
    </xsl:if>
    <xsl:variable name="summaries" select="quer:object//rs:reportSummary[matches(uri,
     '/summary\.successpct\.performance$')]/body/performance/benchmark/statistics/statistic"/>
    <xsl:variable name="resources" select="/combo/resources/resource |
               /combo/suites/suite[matches(name, $name)]/resources/resource" />
    <xsl:call-template name="printSeriesResultsTable">
      <xsl:with-param name="seriesNames" select="$seriesNames"/>
      <xsl:with-param name="summaries" select="$summaries"/>
      <xsl:with-param name="resources" select="$resources[macros/macro[name='__equivalent__' and value='true']]"/>
    </xsl:call-template>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printMdsResultsTable                                                 -->
  <!--                                                                      -->
  <!-- Prints a table with mds series results.                              -->
  <!-- ==================================================================== -->
  <xsl:template name="printMdsResultsTable">
    <xsl:variable name="seriesNames" select="/combo/tgwide/services/service"/>
    <xsl:variable name="resources" select="/combo/tgwide/resources/resource"/>
    <xsl:variable name="suite" select="."/>
    <h1><xsl:value-of select="/combo/tgwide/id"/></h1>
    <table class="subheader">
      <tr>
        <td class="subheader"/>
        <!-- inca-common.xsl printResourceNameCell -->
        <xsl:apply-templates select="$resources" mode="name">
          <xsl:sort/>
        </xsl:apply-templates>
      </tr>
      <xsl:for-each select="$seriesNames">
        <tr>
          <td class="clear"><xsl:value-of select="concat(name,' ',port)"/></td>
          <xsl:variable name="series" select="name"/>
          <xsl:for-each select="$resources">
            <xsl:sort/>
            <xsl:variable name="regex" select="concat('^',name,'.*(\(|_)',$series,'(\)|)$')"/>
            <xsl:variable name="result" select="$suite/quer:object//rs:reportSummary[
                matches(nickname, $regex)]"/>
            <xsl:call-template name="printResourceResultCell">
              <xsl:with-param name="result" select="$result"/>
              <xsl:with-param name="bench" 
                select="$result/body/performance/benchmark/statistics/statistic[ID=$series]" />
            </xsl:call-template>
          </xsl:for-each>
        </tr>
      </xsl:for-each>
    </table>
  </xsl:template>
  
  <!-- ==================================================================== -->
  <!-- printSeriesResultsTable                                              -->
  <!--                                                                      -->
  <!-- Prints a table with series results.                                  -->
  <!-- ==================================================================== -->
  <xsl:template name="printSeriesResultsTable">
    <xsl:param name="seriesNames"/>
    <xsl:param name="summaries"/>
    <xsl:param name="resources"/>
    <xsl:variable name="suite" select="."/>
    <table class="subheader">
      <xsl:for-each select="$seriesNames">
        <xsl:sort/>
        <xsl:if test="position() mod 20 = 1">
          <tr>
            <td class="subheader"/>
            <xsl:if test="$summaries"><td class="subheader">SUMMARY</td></xsl:if>
            <!-- inca-common.xsl printResourceNameCell -->
            <xsl:apply-templates select="$resources" mode="name">
              <xsl:sort/>
            </xsl:apply-templates>
          </tr>
        </xsl:if>
        <tr>
          <td class="clear"><a name="{.}">
            <xsl:value-of select="replace(., '^all2all:gridftp_to_', '')" />
          </a></td>
          <xsl:if test="$summaries">
            <xsl:call-template name="printSummaryValue">
              <xsl:with-param name="test" select="."/>
              <xsl:with-param name="summaries" select="$summaries"/>
            </xsl:call-template>
          </xsl:if>
          <xsl:variable name="series" select="."/>
          <xsl:for-each select="$resources">
            <xsl:sort/>
            <xsl:variable name="regexHost" select="concat('^', name, '$|',
               replace(macros/macro[name='__regexp__']/value, ' ','|'))"/>
            <xsl:variable name="result" select="$suite/quer:object//rs:reportSummary[
                 matches(hostname, $regexHost) and nickname=$series]" />
            <xsl:call-template name="printResourceResultCell">
              <xsl:with-param name="result" select="$result"/>
            </xsl:call-template>
          </xsl:for-each>
        </tr>
      </xsl:for-each>
    </table>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printResourceResultCell                                              -->
  <!--                                                                      -->
  <!-- Prints a table cell with resource result.                            -->
  <!-- ==================================================================== -->
  <xsl:template name="printResourceResultCell">
    <xsl:param name="result"/>
    <xsl:param name="bench"/>
    <xsl:variable name="instance" select="$result/instanceId" />
    <xsl:variable name="comparitor" select="$result/comparisonResult" />
    <xsl:variable name="foundVersion" select="$result/body/package/version" />
    <xsl:variable name="errMsg" select="$result/errorMessage" />
    <xsl:choose>
      <xsl:when test="count($result)>0">
        <!-- resource is not exempt -->
        <xsl:variable name="resourceName">
          <xsl:choose>
            <!-- in tg-mds suite -->
            <xsl:when test="name[matches(., '^(info|info1\.dyn|info2\.dyn|mds)\.teragrid\.org$')]">
              <xsl:value-of select="'repo'" />
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="name"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="normRef" select="concat('/inca/jsp/instance.jsp?instanceId=',
            $instance, '&amp;configId=', $result/seriesConfigId)"/>
        <xsl:variable name="href">
          <xsl:call-template name="getLink">
            <xsl:with-param name="errMsg" select="$errMsg"/>
            <xsl:with-param name="normRef" select="$normRef"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="stale">
          <xsl:if test="$result/gmtExpires">
            <!-- inca-common.xsl -->
            <xsl:call-template name="markOld">
              <xsl:with-param name="gmtExpires" select="$result/gmtExpires" as="xs:dateTime"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:variable>
        <xsl:variable name="exit">
          <xsl:choose>
            <xsl:when test="string($stale)!=''">
              <xsl:value-of select="'stale'" />
            </xsl:when>
            <xsl:when test="count($result/body)=0">
              <xsl:value-of select="''" />
            </xsl:when>
            <xsl:when test="$errMsg[matches(., '^DOWNTIME:.*: ')]">
              <xsl:value-of select="'down'" />
            </xsl:when>
            <xsl:when test="$errMsg[matches(., '^NOT_AT_FAULT:')]">
              <xsl:value-of select="'noFault'" />
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
        <xsl:variable name="mapstats" select="$result/body/performance/benchmark/statistics"/>
        <xsl:choose>
          <xsl:when test="$exit!=''">
            <td class="{$exit}">
              <a href="{$href}" title="{$errMsg}">
                <xsl:choose>
                  <xsl:when test="string($foundVersion)='' or string($stale)!=''">
                    <xsl:choose>
                      <xsl:when test="string($bench)!=''">
                        <xsl:value-of select="concat($bench/value,' ',$bench/units)"/>
                      </xsl:when>
                      <xsl:when test="string($mapstats/statistic[ID='errorCommunityUser'])">
                        <xsl:variable name="ecu" select="$mapstats/statistic[ID='errorCommunityUser']/value"/>
                        <xsl:if test="$ecu>0"><xsl:value-of select="concat('community_user:_',$ecu)"/><br/></xsl:if>
                        <xsl:variable name="ef" select="$mapstats/statistic[ID='errorFormat']/value"/>
                        <xsl:if test="$ef>0"><xsl:value-of select="concat('format:_',$ef)"/><br/></xsl:if>
                        <xsl:variable name="egt" select="$mapstats/statistic[ID='errorLocalGT4ized']/value"/>
                        <xsl:if test="$egt>0"><xsl:value-of select="concat('local_gt4:_',$egt)"/><br/></xsl:if>
                        <xsl:variable name="emu" select="$mapstats/statistic[ID='errorMultipleUsernames']/value"/>
                        <xsl:if test="$emu>0"><xsl:value-of select="concat('multiple_usernames:_',$emu)"/><br/></xsl:if>
                        <xsl:variable name="enm" select="$mapstats/statistic[ID='errorNotMapped']/value"/>
                        <xsl:if test="$enm>0"><xsl:value-of select="concat('not_mapped:_',$enm)"/><br/></xsl:if>
                        <xsl:variable name="eog" select="$mapstats/statistic[ID='errorOnlyInGridmap']/value"/>
                        <xsl:if test="$eog>0"><xsl:value-of select="concat('only_in_gridmap:_',$eog)"/><br/></xsl:if>
                        <xsl:variable name="epm" select="$mapstats/statistic[ID='errorPartiallyMapped']/value"/>
                        <xsl:if test="$epm>0"><xsl:value-of select="concat('partially_mapped:_',$epm)"/><br/></xsl:if>
                        <xsl:variable name="erm" select="$mapstats/statistic[ID='errorRedundantMappings']/value"/>
                        <xsl:if test="$erm>0"><xsl:value-of select="concat('redundant_mappings:_',$erm)"/><br/></xsl:if>
                        <xsl:value-of select="$exit"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$exit"/>
                      </xsl:otherwise>
                    </xsl:choose>
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
