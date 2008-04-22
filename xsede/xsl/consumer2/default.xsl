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
    <xsl:apply-templates select="suites/suite" />
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSuiteInfo                                                       -->
  <!--                                                                      -->
  <!-- Calls printSeriesNamesTable and printSeriesResultsTable              -->
  <!-- ==================================================================== -->
  <xsl:template name="printSuiteInfo" match="suite">
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
    <xsl:call-template name="printSeriesResultsTable">
      <xsl:with-param name="seriesNames" select="$seriesNames"/>
      <xsl:with-param name="resources"
       select="/combo/resources/resource[name]|/combo/suites/suite[matches(name, 
        $name)]/resources/resource[name]"/>
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
            <xsl:variable name="regex" select="concat(name,'.*(',$series,')')"/>
            <xsl:variable name="result" select="$suite/quer:object//rs:reportSummary[
                matches(nickname, $regex)]" />
            <xsl:call-template name="printResourceResultCell">
              <xsl:with-param name="result" select="$result"/>
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
    <xsl:param name="resources"/>
    <xsl:variable name="suite" select="."/>
    <table class="subheader">
      <xsl:for-each select="$seriesNames">
        <xsl:sort/>
        <xsl:if test="position() mod 20 = 1">
          <tr>
            <td class="subheader"/>
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
    <xsl:variable name="instance" select="$result/instanceId" />
    <xsl:variable name="comparitor" select="$result/comparisonResult" />
    <xsl:variable name="foundVersion" select="$result/body/package/version" />
    <xsl:variable name="errMsg" select="$result/errorMessage" />
    <xsl:choose>
      <xsl:when test="count($result)>0">
        <!-- resource is not exempt -->
        <xsl:variable name="normRef" 
            select="concat('../jsp/instance.jsp?xsl=instance.xsl&amp;instanceId=',
            $instance, '&amp;configId=', $result/seriesConfigId,
            '&amp;resourceId=', name)"/>
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
