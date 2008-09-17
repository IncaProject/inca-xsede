<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- job.xsl:  Prints table of DN stats and table of CA stats based on    -->
<!--           results from the usage suite.                              -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:quer="http://inca.sdsc.edu/dataModel/queryResults_2.0"
                xmlns:rs="http://inca.sdsc.edu/queryResult/reportSummary_2.0"
                xmlns="http://www.w3.org/1999/xhtml">
  
  <xsl:template match="/combo">  
    <h1 class="body"><xsl:value-of select="stack/id"/></h1>
    <br/><font class="ptext"><b>
    <xsl:text>Num. jobs per unique user:</xsl:text>
  </b></font><br/>
    <!-- print table with DN stats -->
    <xsl:variable
        name="resources"
        select="resources/resource[name]"/>
    <table class="subheader">
      <!-- print header row -->
      <tr>
        <td class="header"><xsl:text>Machine</xsl:text></td>
        <td class="header"><xsl:text>Reporter Status</xsl:text></td>
        <td class="header"><xsl:text>Start (GMT)</xsl:text></td>
        <td class="header"><xsl:text>End (GMT)</xsl:text></td>
        <td class="header">
          <xsl:text>User's Distinguished Name (DN)</xsl:text>
        </td>
        <td class="header"><xsl:text>Num. Jobs</xsl:text></td>
      </tr>
      <!-- print row for each resource -->
      <xsl:for-each select="$resources">
        <xsl:sort select="."/>
        <tr>
          <xsl:call-template name="getResults">
            <xsl:with-param name="machine" select="name"/>
            <xsl:with-param name="col" select="'6'"/>
            <xsl:with-param name="ca" select="'0'"/>
          </xsl:call-template>
        </tr>
        <tr><td class="midheader" colspan="6"><xsl:text> </xsl:text></td></tr>
      </xsl:for-each>
    </table><br/><br/><br/><br/>
    <!-- print table with CA stats -->
    <font class="ptext"><b><xsl:text>CA stats:</xsl:text></b></font><br/>
    <table class="subheader">
      <!-- print header row -->
      <tr>
        <td class="header"><xsl:text>Machine</xsl:text></td>
        <td class="header"><xsl:text>Reporter Status</xsl:text></td>
        <td class="header"><xsl:text>Start (GMT)</xsl:text></td>
        <td class="header"><xsl:text>End (GMT)</xsl:text></td>
        <td class="header"><xsl:text>Certificate Authority (CA)</xsl:text></td>
        <td class="header"><xsl:text>Total User Jobs</xsl:text></td>
        <td class="header"><xsl:text>Unique User Jobs</xsl:text></td>
      </tr>
      <!-- print row for each resource -->
      <xsl:for-each select="$resources">
        <xsl:sort select="."/>
        <tr>
          <xsl:call-template name="getResults">
            <xsl:with-param name="machine" select="name"/>
            <xsl:with-param name="col" select="'7'"/>
            <xsl:with-param name="ca" select="'1'"/>
          </xsl:call-template>
        </tr>
        <tr><td class="midheader" colspan="7"><xsl:text> </xsl:text></td></tr>
      </xsl:for-each>
    </table>
  </xsl:template>


  <xsl:template name="getResults">
    <xsl:param name="machine"/>
    <xsl:param name="col"/>
    <xsl:param name="ca"/>

    <xsl:variable name="regexHost">
      <xsl:value-of select="'^'" />
      <xsl:value-of select="$machine" />
      <xsl:value-of select="'$|'" />
      <xsl:value-of
          select="replace(macros/macro[name='__regexp__']/value, ' ','|')"/>
    </xsl:variable>
    <xsl:variable name="regexTest">
      <xsl:value-of select="'^.*'"/>
      <xsl:value-of select="'grid.jobs.usage'"/>
      <xsl:value-of select="'$'"/>
    </xsl:variable>
    <xsl:variable name="result" select="//rs:reportSummary[matches(hostname,
    $regexHost) and (matches(uri, $regexTest) or matches(nickname,$regexTest))]"/>
    <xsl:variable name="uri" select="$result/uri"/>
    <xsl:variable name="instance" select="$result/instanceId"/>
    <xsl:variable name="conf" select="$result/seriesConfigId"/>
    <xsl:variable name="completed" select="string($result/body)"/>
    <xsl:variable name="begin" select="$result/body/usage/entry[matches(type,'begin')]"/>
    <xsl:variable name="end" select="$result/body/usage/entry[matches(type,'end')]"/>
    <xsl:variable name="user" select="$result/body/usage//entry[matches(type,'user')]"/>
    <xsl:variable name="org" select="$result/body/usage//entry[matches(type,'org')]"/>

    <xsl:variable name="exit">
      <xsl:choose>
        <xsl:when test="count($result/body)=0">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:when test="$completed!=''">
          <xsl:value-of select="'pass'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'fail'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <td class="clear">
      <xsl:value-of select="$machine"/>
    </td>
    <xsl:choose>
      <xsl:when test="$uri!=''">
        <!-- resource is not exempt -->
        <xsl:variable name="href" select="concat('../jsp/instance.jsp?instanceId=',
            $instance,'&amp;configId=',$conf)"/>
        <xsl:choose>
          <xsl:when test="$exit!=''">
            <td class="{$exit}">
              <a href="{$href}"><xsl:value-of select="$exit"/></a>
            </td>
            <xsl:choose>
              <xsl:when test="$org!=''">
                <td class="clear"><xsl:value-of select="$begin/name"/></td>
                <td class="clear"><xsl:value-of select="$end/name"/></td>
                <xsl:if test="$ca='1'">
                  <xsl:for-each select="$org">
                    <xsl:sort
                        select="statistics/statistic[matches(name,'total')]/value"
                        data-type="number" order="descending"/>
                    <td class="clear"><xsl:value-of select="name"/></td>
                    <td class="clear">
                      <xsl:value-of
                          select="statistics/statistic[matches(name,'total')]/value"/>
                    </td>
                    <td class="clear">
                      <xsl:value-of
                          select="statistics/statistic[matches(name,'unique')]/value"/>
                    </td>
                    <tr/>
                    <td colspan="4"/>
                  </xsl:for-each>
                </xsl:if>
                <xsl:if test="$ca='0'">
                  <xsl:for-each select="$user">
                    <xsl:sort select="statistics/statistic[matches(name,
                    'count')]/value" data-type="number" order="descending"/>
                    <td class="clear"><xsl:value-of select="name"/></td>
                    <td class="clear">
                      <xsl:value-of
                          select="statistics/statistic[matches(name,'count')]/value"/>
                    </td>
                    <tr/>
                    <td colspan="4"/>
                  </xsl:for-each>
                </xsl:if>
              </xsl:when>
              <xsl:otherwise>
                <td class="clear" colspan="{$col}"><xsl:text> </xsl:text></td>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <!-- missing data -->
          <xsl:otherwise>
            <td class="clear" colspan="{$col}"><xsl:text>missing</xsl:text></td>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- resource is exempt -->
      <xsl:otherwise>
        <td class="na" colspan="{$col}"><xsl:text>n/a</xsl:text></td>
      </xsl:otherwise>
    </xsl:choose>
    <td colspan="4"/>
  </xsl:template>

</xsl:stylesheet>
