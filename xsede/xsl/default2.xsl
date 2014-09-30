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
        <xsl:with-param name="title" select="'Inca reporter results'"/>
      </xsl:call-template>
      <p>Inca test results, version information, or performance results are shown below
         in one or more tables.  Each table displays related test results where the
         rows of the table will display the name of an Inca test, software version, or
         performance measurement.  The columns of the table display the resource where the
         test was executed.  Click on selected
         icons (described in the <a href="javascript:window.open('/inca/jsp/legend.jsp','incalegend','width=400,height=325,resizable=yes')">legend</a>) for more details about the
         collected Inca report.</p>
    </xsl:if>

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

    <xsl:variable name="defaultconfig" select="document('../xml/default.xml')/default"/>

    <!-- get all series names; we don't want cross-site names that aren't all2all series
         and don't want summary reporters -->
    <xsl:variable name="seriesNames"
         select="distinct-values(quer:object//rs:reportSummary[starts-with(nickname, 'all2all:') or ( not(contains(nickname, '_to_')) and not(matches(uri, '/summary\.successpct\.performance$')) )]/nickname)"/> 
    <xsl:variable name="csSeriesNamesString">
      <!-- needs to be crunched on one line to take out newlines in string -->
      <xsl:for-each select="quer:object//rs:reportSummary[not(ends-with(uri,'summary.successpct.performance'))]/nickname[not(starts-with(., 'all2all:')) and contains(., '_to_')]"><xsl:value-of select="substring-before(., '_to_')"/><xsl:if test="position() != last()">,</xsl:if></xsl:for-each>
    </xsl:variable>
    <xsl:variable name="csSeriesNames" select="distinct-values(tokenize($csSeriesNamesString,','))"/>

    <!-- Uncomment below if want to print a list of tests in the below table with links
    <xsl:call-template name="printSeriesNamesTable">
      <xsl:with-param name="seriesNames" select="$seriesNames"/>
    </xsl:call-template>
    -->
    <xsl:variable name="summaries" select="quer:object//rs:reportSummary[matches(uri,
     '/summary\.successpct\.performance$')]/body/performance/benchmark/statistics/statistic"/>
    <xsl:variable name="resources" select="/combo/resources/resource |
               /combo/suites/suite[matches(name, $name)]/resources/resource" />
    <table><tr>
      <td><h1><xsl:value-of select="$name"/></h1></td>
      <xsl:variable name="focusurl">/inca/jsp/status.jsp?suiteNames=<xsl:value-of select="$name"/></xsl:variable>
      <td align="right" valign="middle"> <a href="{$focusurl}"><img src="/inca/img/eye.png" width="25" style="vertical-align: bottom"/></a></td><td align="left" valign="middle">(<a href="javascript:window.open('/inca/jsp/legend.jsp','incalegend','width=400,height=325,resizable=yes')">view legend</a>)</td>
    </tr><tr><td colspan="3">
      <xsl:call-template name="printSeriesResultsTable">
        <xsl:with-param name="seriesNames" 
                        select="distinct-values(insert-before($seriesNames,0,$csSeriesNames))"/>
        <xsl:with-param name="summaries" select="$summaries"/>
        <xsl:with-param name="resources" select="$resources[macros/macro[name='__equivalent__' and value='true']]"/>
        <xsl:with-param name="defaultconfig" select="$defaultconfig"/>
        <xsl:with-param name="localdefaultconfig" select="default"/>
      </xsl:call-template>
    </td></tr></table>
    <br/>
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
    <xsl:param name="defaultconfig"/>
    <xsl:param name="localdefaultconfig"/>
    <xsl:variable name="suite" select="."/>

    <xsl:variable name="groupregex">
      <xsl:choose><xsl:when test="$localdefaultconfig/group"><xsl:value-of select="string-join($localdefaultconfig/group/@regex, '|')"/></xsl:when><xsl:when test="$defaultconfig/group"><xsl:value-of select="string-join($defaultconfig/group/@regex, '|')"/></xsl:when><xsl:otherwise>^$</xsl:otherwise></xsl:choose>
    </xsl:variable>

    <xsl:variable name="groupedseries" select="$seriesNames[matches(.,$groupregex)]"/>
    <xsl:variable name="ungroupedseries" select="$seriesNames[not(matches(.,$groupregex))]"/>

    <table class="subheader">
      <xsl:for-each select="$localdefaultconfig/group | $defaultconfig/group">
        <xsl:variable name="regex" select="@regex"/>
        <xsl:variable name="strip" select="@strip"/>
        <xsl:variable name="missing" select="@missing"/>
        <xsl:if test="count($groupedseries[matches(.,$regex)])>0 or $missing">
        <tr>
          <td class="subheader"><xsl:value-of select="@name"/></td>
          <xsl:if test="$summaries"><td class="subheader">SUMMARY</td></xsl:if>
          <!-- inca-common.xsl printResourceNameCell -->
          <xsl:apply-templates select="$resources" mode="name">
            <xsl:sort/>
          </xsl:apply-templates>
        </tr>
        </xsl:if>
        <xsl:if test="count($groupedseries[matches(.,$regex)])=0 and $missing">
        <xsl:variable name="numResources" select="count($resources)+1"/>
        <tr><td class="clear" colspan="{$numResources}"><xsl:value-of select="$missing"/></td></tr>
        </xsl:if>
        <xsl:for-each select="$groupedseries[matches(.,$regex)]">
          <xsl:sort select="replace(., '\d', '')" />
          <xsl:sort select="replace(.,'[^\d]', '')" data-type="number"/>

          <xsl:variable name="seriesName" select="."/>
          <xsl:variable name="printSeriesName">
            <xsl:choose><xsl:when test="$strip">
              <xsl:value-of select="replace(.,$strip,'')"/>
            </xsl:when><xsl:otherwise>
              <xsl:value-of select="."/>
            </xsl:otherwise></xsl:choose>
          </xsl:variable>  
          <xsl:call-template name="printSeriesResultsRow">
            <xsl:with-param name="resources" select="$resources"/>
            <xsl:with-param name="seriesName" select="$seriesName"/>
            <xsl:with-param name="printSeriesName" select="$printSeriesName"/>
            <xsl:with-param name="suite" select="$suite"/>
            <xsl:with-param name="summaries" select="$summaries"/>
            <xsl:with-param name="defaultconfig" select="$defaultconfig"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:for-each>
      <xsl:for-each select="$ungroupedseries">
        <!-- do text number sort -->
        <xsl:sort select="replace(., '\d', '')" />
        <xsl:sort select="replace(.,'[^\d]', '')" data-type="number"/>

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
        <xsl:variable name="seriesName" select="."/>
        <xsl:call-template name="printSeriesResultsRow">
          <xsl:with-param name="resources" select="$resources"/>
          <xsl:with-param name="seriesName" select="$seriesName"/>
          <xsl:with-param name="printSeriesName" select="$seriesName"/>
          <xsl:with-param name="suite" select="$suite"/>
          <xsl:with-param name="summaries" select="$summaries"/>
          <xsl:with-param name="defaultconfig" select="$defaultconfig"/>
        </xsl:call-template>
      </xsl:for-each>
    </table>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSeriesResultsRow -->
  <!--                                                                      -->
  <!-- Prints a row of series results    .                                  -->
  <!-- ==================================================================== -->
  <xsl:template name="printSeriesResultsRow">
    <xsl:param name="resources"/>
    <xsl:param name="seriesName"/>
    <xsl:param name="printSeriesName"/>
    <xsl:param name="suite"/>
    <xsl:param name="summaries"/>
    <xsl:param name="defaultconfig"/>
    <tr>
      <td class="clear"><a name="{$seriesName}">
        <xsl:value-of select="$printSeriesName" />
      </a></td>
      <xsl:if test="$summaries">
        <xsl:call-template name="printSummaryValue">
          <xsl:with-param name="test" select="$seriesName"/>
          <xsl:with-param name="summaries" select="$summaries"/>
          <xsl:with-param name="states" select="$defaultconfig/incaResult"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:for-each select="$resources">
        <xsl:sort/>

        <xsl:variable name="regexHost" select="concat(name, '$|',
          replace(macros/macro[name='__regexp__']/value, ' ','|'))"/>
        <xsl:variable name="csSeriesName" select="concat('^', encode-for-uri($seriesName),'_to_(', $regexHost, ')' )"/>
        <xsl:variable name="reports" select="$suite/quer:object//rs:reportSummary[nickname=$seriesName or matches(nickname, $csSeriesName)]"/>
        <xsl:choose><xsl:when test="count($reports[matches(targetHostname,$regexHost)])=1">
          <xsl:call-template name="printResourceResultCell">
            <xsl:with-param name="result" select="$reports[matches(targetHostname,$regexHost)]"/>
            <xsl:with-param name="defaultconfig" select="$defaultconfig"/>
          </xsl:call-template>
        </xsl:when><xsl:otherwise>
          <xsl:call-template name="printResourceResultCell">
            <xsl:with-param name="result" select="$reports[matches(hostname,$regexHost)]"/>
            <xsl:with-param name="defaultconfig" select="$defaultconfig"/>
          </xsl:call-template>
        </xsl:otherwise></xsl:choose>

      </xsl:for-each>
    </tr>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printResourceResultCell                                              -->
  <!--                                                                      -->
  <!-- Prints a table cell with resource result.                            -->
  <!-- ==================================================================== -->
  <xsl:template name="printResourceResultCell">
    <xsl:param name="result"/>
    <xsl:param name="defaultconfig"/>
    <xsl:variable name="instance" select="$result/instanceId" />
    <xsl:variable name="foundVersion" select="$result/body/package/version|$result/body/package/subpackage"/>
    <xsl:variable name="errMsg" select="$result/errorMessage" />

    <xsl:choose><xsl:when test="count($result)=1">
        <!-- resource is not exempt -->
      <xsl:variable name="normRef">
        <xsl:choose><xsl:when test="$result/gmt">
          <xsl:value-of select="concat('/inca/jsp/instance.jsp?nickname=', encode-for-uri($result/nickname), '&amp;resource=', $result/hostname, '&amp;target=', $result/targetHostname, '&amp;collected=', $result/gmt)"/>
        </xsl:when><xsl:otherwise>
          <xsl:value-of select="concat('/inca/jsp/runNow.jsp?configId=', $result/seriesConfigId)"/>
        </xsl:otherwise></xsl:choose>
     </xsl:variable>
       <xsl:variable name="href"><xsl:call-template name="getLink">
           <xsl:with-param name="errMsg" select="$errMsg"/>
           <xsl:with-param name="normRef" select="$normRef"/>
           <xsl:with-param name="downtimeUrl" select="$defaultconfig/downtimeUrl"/>
       </xsl:call-template></xsl:variable>

       <!-- inca-common.xsl:  returns string of bgcolor|img.png -->
       <xsl:variable name="state"><xsl:call-template name="getStatus">
           <xsl:with-param name="result" select="$result"/>
           <xsl:with-param name="states" select="$defaultconfig/incaResult"/>
       </xsl:call-template></xsl:variable>

       <xsl:if test="$state!=''">
         <xsl:variable name="bgcolor" select="tokenize($state,'\|')[1]"/>
         <xsl:variable name="img" select="tokenize($state,'\|')[2]"/>
         <xsl:variable name="text" select="tokenize($state,'\|')[3]"/>
         <td bgcolor="{$bgcolor}" align="center">
           <a href="{$href}" title="{$errMsg}" id="statuscell" >
             <xsl:if test="$img!='' and (not(contains($state, 'pass')) or not($foundVersion))">
               <img src="{concat('/inca/img/', $img)}"/>
               <xsl:if test="$href != $normRef">
                 <a style="text-decoration:none; text-size: tiny" href="{$normRef}">*</a>
               </xsl:if>
               <br/>
             </xsl:if>
             <xsl:value-of select="$text"/>
             <xsl:choose>
               <xsl:when test="$result/body//statistics">
                 <table bgcolor="{$bgcolor}">
                 <xsl:call-template name="printBodyStats">
                   <xsl:with-param name="report" select="$result"/>
                 </xsl:call-template>
                 </table>
               </xsl:when>
               <xsl:when test="count($foundVersion)>1">
                 <xsl:for-each select="$result/body/package/subpackage">
                 <xsl:value-of select="ID"/>: <xsl:value-of select="version"/><br/>
                 </xsl:for-each>
               </xsl:when>
               <xsl:when test="string($foundVersion)!=''">
                 <xsl:value-of select="$foundVersion" />
               </xsl:when>
             </xsl:choose>
           </a>
         </td>
       </xsl:if>
     </xsl:when><xsl:otherwise>
	<!-- resource is exempt -->
       <xsl:variable name="naConfig" select="$defaultconfig/incaResult/secondaryState[@name='na']"/>
       <td bgcolor="{$naConfig/@bgcolor}" align="center"><xsl:value-of select="$naConfig/@text"/></td>
     </xsl:otherwise></xsl:choose>
  </xsl:template>

</xsl:stylesheet>
