<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- swStack.xsl:  Prints table of suite(s) results.  Uses XML file       -->
<!--               to format table rows by software categories and        -->
<!--               packages.                                              -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:sdf="java.text.SimpleDateFormat"
                xmlns:date="java.util.Date"
                xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes"
                xmlns:quer="http://inca.sdsc.edu/dataModel/queryResults_2.0"
                xmlns:rs="http://inca.sdsc.edu/queryResult/reportSummary_2.0"
                xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xsl:include href="../xsl/inca-common.xsl"/>
  <xsl:include href="../xsl/tg-legend.xsl"/>
  <xsl:include href="../xsl/tg-menu.xsl"/>
  <xsl:include href="../xsl/sw-menu.xsl"/>
  <xsl:param name="queryStr" />

  <xsl:variable name="matchProd"
                select="$queryStr[matches(., 'reporterStatus=prod')]"/>

  <xsl:variable name="prodReportersOnly">
    <xsl:choose>
      <xsl:when test="$matchProd!=''">
        <xsl:value-of select="'true'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'false'" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- ==================================================================== -->
  <!-- generateHTML                                                         -->
  <!--                                                                      -->
  <!-- Prints an html header with a page title and a legend.                -->
  <!-- ==================================================================== -->
  <xsl:template name="generateHTML" match="/combo">
    <!-- inca-common.xsl -->
    <xsl:call-template name="printBodyTitle">
      <xsl:with-param name="title" select="''"/>
    </xsl:call-template>
    <table><tr><td>
    <!-- tg-legend.xsl -->
    <xsl:call-template name="printLegend"/>
    </td><td align="right">
    <!-- sw-menu.xsl or tg-menu.xsl -->
    <xsl:if test="$queryStr[matches(., 'suiteNames=ctss')]">
      <xsl:call-template name="sw-menu"/>
    </xsl:if>
    <xsl:if test="$queryStr[matches(., 'suiteNames=.*\.teragrid.org-.*')]">
      <xsl:call-template name="tg-menu"/>
    </xsl:if>
    </td></tr></table>
    <xsl:for-each select="suites/suite|queries/query">
      <xsl:variable name="testResources" 
                  select="string(/combo/stack/testing|stack/testing)"/>
      <xsl:variable name="matchResources">
        <xsl:choose>
          <xsl:when test="$testResources!=''">
            <xsl:value-of select="$testResources"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="' '"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="$queryStr[matches(., 'supportLevel=testing')]">
          <xsl:variable name="resources" 
               select="/combo/resources/resource[matches(name, $matchResources)]
                       |resources/resource[matches(name, $matchResources)]"/>
          <xsl:call-template name="printAllPackages">
            <xsl:with-param name="resources"
              select="$resources[macros/macro[name='__equivalent__' and value='true']]"/>
            <xsl:with-param name="cats" 
                select="/combo/stack/category|stack/category" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="resources" 
               select="/combo/resources/resource[not(matches(name, $matchResources))]
                       |resources/resource[not(matches(name, $matchResources))]"/>
          <xsl:call-template name="printAllPackages">
            <xsl:with-param name="resources"
              select="$resources[macros/macro[name='__equivalent__' and value='true']]"/>
            <xsl:with-param name="cats" 
                select="/combo/stack/category|stack/category" />
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printAllPackages                                                     -->
  <!--                                                                      -->
  <!-- Print table with list of packages and table with all package results -->
  <!-- ==================================================================== -->
  <xsl:template name="printAllPackages">
    <xsl:param name="resources"/>
    <xsl:param name="cats"/>
    <xsl:variable name="suite" select="."/>
    <h1 class="body"><xsl:value-of select="$cats/../id"/></h1>
    <!-- inca-common.xsl -->
    <xsl:call-template name="printSeriesNamesTable">
      <xsl:with-param name="seriesNames" select="$cats/package/id"/>
    </xsl:call-template>
    <table class="subheader">
      <!-- resultsAllPackages -->
      <xsl:apply-templates select="$cats">
        <xsl:sort/>
        <xsl:with-param name="resources" select="$resources"/>
        <xsl:with-param name="suite" select="$suite" />
      </xsl:apply-templates>
    </table>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- resultsAllPackages                                                   -->
  <!--                                                                      -->
  <!-- Prints category header row and calls template to print its packages  -->
  <!-- ==================================================================== -->
  <xsl:template name="resultsAllPackages" match="category">
    <xsl:param name="resources"/>
    <xsl:param name="suite"/>
    <xsl:variable name="summaries"
     select="$suite/quer:object//rs:reportSummary[matches(uri,
     '/summary\.successpct\.performance$')]/body/performance/benchmark/statistics/statistic"/>
    <xsl:variable name="span">
      <xsl:choose>
        <xsl:when test="$summaries">
          <xsl:value-of select="count($resources)+2" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="count($resources)+1" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$queryStr[not(matches(., 'noCategoryHeaders'))]">
    <tr><td colspan="{$span}" class="header">
      <xsl:value-of select="upper-case(id)"/>
    </td></tr>
    </xsl:if>
    <!-- printPackage -->
    <xsl:apply-templates select="package">
      <xsl:sort/>
      <xsl:with-param name="resources" select="$resources"/>
      <xsl:with-param name="suite" select="$suite" />
      <xsl:with-param name="summaries" select="$summaries" />
    </xsl:apply-templates>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printPackage                                                         -->
  <!--                                                                      -->
  <!-- Prints packages results for a set of resources                       -->
  <!-- ==================================================================== -->
  <xsl:template name="printPackage" match="package">
    <xsl:param name="resources"/>
    <xsl:param name="suite"/>
    <xsl:param name="summaries"/>
    <xsl:variable name="package" select="id"/>
    <!-- print subheader row for package with package name
    and each resource name -->
    <tr>
      <td class="subheader"><a name="{$package}">
        <xsl:value-of select="$package"/>
      </a></td>
      <xsl:if test="$summaries">
        <td>SUMMARY</td> 
      </xsl:if>
      <!-- inca-common.xsl printResourceNameCell -->
      <xsl:apply-templates select="$resources" mode="name">
        <xsl:sort/>
      </xsl:apply-templates>
    </tr>
    <!-- printResultsRow -->
    <xsl:apply-templates select="tests/unitalias|tests/version">
      <xsl:with-param name="resources" select="$resources"/>
      <xsl:with-param name="suite" select="$suite" />
      <xsl:with-param name="summaries" select="$summaries" />
    </xsl:apply-templates>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printResultsRow                                                      -->
  <!--                                                                      -->
  <!-- Prints results of test for resource set                              -->
  <!-- ==================================================================== -->
  <xsl:template name="printResultsRow" match="unitalias|version">
    <xsl:param name="resources"/>
    <xsl:param name="suite"/>
    <xsl:param name="summaries"/>
    <xsl:variable name="testname" select="." />
    <xsl:variable name="package" select="../.." />
    <xsl:variable name="rowlabel">
      <xsl:choose>
        <xsl:when test="$package/tests[version=$testname]">
          <xsl:value-of select="concat('version: ' , $package/version)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$testname"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="($prodReportersOnly='true' and count(status[.='dev'])=0)
    or $prodReportersOnly='false'">
      <tr>
        <td class="clear">
          <xsl:value-of select="replace($rowlabel, '^all2all:.*_to_', '')" />
        </td>
        <xsl:if test="$summaries">
          <xsl:call-template name="printSummaryValue">
            <xsl:with-param name="test" select="$testname"/>
            <xsl:with-param name="summaries" select="$summaries"/>
          </xsl:call-template>
        </xsl:if>
        <!-- printResourceResultCell -->
        <xsl:apply-templates select="$resources" mode="result">
          <xsl:sort/>
          <xsl:with-param name="testname" select="$testname"/>
          <xsl:with-param name="package" select="$package"/>
          <xsl:with-param name="suite" select="$suite"/>
        </xsl:apply-templates>
      </tr>
    </xsl:if>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printResourceResultCell                                              -->
  <!--                                                                      -->
  <!-- Prints a table cell with resource result.                            -->
  <!-- ==================================================================== -->
  <xsl:template name="printResourceResultCell" match="resource" mode="result">
    <xsl:param name="testname"/>
    <xsl:param name="package"/>
    <xsl:param name="suite"/>
    <xsl:variable name="thisResource" select="concat('^', name, '$')"/>
    <xsl:variable name="thisMacros" 
         select="replace(macros/macro[name='__regexp__']/value, ' ','|')"/>
    <xsl:variable name="regexHost" select="concat($thisResource, '|', $thisMacros)"/>
    <xsl:variable name="endpoint" select="$testname/../../../../endpoint[
         matches(nickname, $thisResource)]/regex"/>
    <xsl:variable name="testClean" select="replace($testname,'\+','.')"/>
    <xsl:variable name="regexTest" select="concat('^',$testClean,'_',$endpoint,'$')"/>
    <xsl:variable name="result" select="$suite/quer:object//rs:reportSummary[
         (matches(hostname, $regexHost) and nickname=$testname) or 
         (matches(nickname, $regexTest))]" />
    <xsl:variable name="instance" select="$result/instanceId" />
    <xsl:variable name="comparitor" select="$result/comparisonResult" />
    <xsl:variable name="foundVersion" select="$result/body/package/version" />
    <xsl:variable name="errMsg" select="$result/errorMessage" />
    <xsl:choose>
      <xsl:when test="count($result)>0">
        <!-- resource is not exempt -->
        <xsl:variable name="normRef" select="concat('/inca/jsp/instance.jsp?nickname=',
            $result/nickname, '&amp;resource=', $result/hostname, '&amp;collected=', $result/gmt)"/>
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
            <xsl:when test="$errMsg[matches(., 'soft-msc: command not found')]">
              <xsl:value-of select="'noSoftenv'" />
            </xsl:when>
            <xsl:when test="$errMsg[matches(., 'Unable to fetch proxy')]">
              <xsl:value-of select="'proxyErr'" />
            </xsl:when>
            <xsl:when test="$errMsg[matches(., 'Inca error')]">
              <xsl:value-of select="'incaErr'" />
            </xsl:when>
            <xsl:when test="$comparitor='Success' or
              (string($result/body)!=''
               and string($errMsg)=''
               and string($comparitor)='' )"> 
              <xsl:value-of select="'pass'" />
            </xsl:when>
            <xsl:when test="$errMsg[matches(.,
            'Reporter exceeded usage limits')]">
              <xsl:value-of select="'timeOut'" />
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
                      <xsl:when test="string($mapstats/@errorCommunityUser)">
                        <xsl:for-each select="$mapstats/@*[.>0 and matches(name(),'^error.*')]">
                          <xsl:sort select="." data-type="number" order="descending"/>
                          <xsl:value-of select="replace(name(), '^error', '')"/>=<xsl:value-of select="."/><br/>
                        </xsl:for-each>
                        <xsl:value-of select="$exit"/>
                      </xsl:when>
                      <xsl:when test="$result/body/stats//warn">
                        <xsl:value-of select="$errMsg" /><br/>
                        <xsl:value-of select="'Near expiration:'" /><br/>
                        <xsl:for-each select="$result/body/stats//warn">
                          &#160;&#160;<xsl:value-of select="." /><br/>
                        </xsl:for-each>
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
              <xsl:variable name="age">
                <xsl:call-template name="formatAge">
                  <xsl:with-param name="age" select="$result/gmt" as="xs:dateTime"/>
                </xsl:call-template>
              </xsl:variable>
              <xsl:if test="$exit='down'">
                <xsl:value-of select="' '" />
                <a href="{$normRef}" title="{$errMsg}">err</a>
              </xsl:if>
              <xsl:if test="$queryStr[matches(., 'suiteNames=real-time')]">
                <xsl:value-of select="concat(' (',$age,' ago)')"/>
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
