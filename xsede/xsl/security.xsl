<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
		xmlns:sdf="java.text.SimpleDateFormat"
        	xmlns:date="java.util.Date"
		xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes"
		xmlns:xs="http://www.w3.org/2001/XMLSchema">
    
    <xsl:include href="footer.xsl"/>
    <xsl:param name="url" />

    <xsl:variable name="markOld" select="$url[matches(., 'markOld')]"/>
    <!-- format of var below is "P, num days, D, T, num hours, H, num minutes, M" -->
    <xsl:variable name="markHours">
        <xsl:analyze-string select="$url" regex="(.*)arkOld=([0-9]+)(.*)">
                <xsl:matching-substring>
                        <xsl:value-of select="regex-group(2)"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                        <xsl:value-of select="'24'"/>
                </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:variable>
    <xsl:variable name="markAge">
        <xsl:value-of select="'P0DT'" />
        <xsl:value-of select="$markHours" />
        <xsl:value-of select="'H0M'" />
    </xsl:variable>
    <xsl:variable name="voResources" select="/combo/resourceConfig/resources/resource[name]"/>

    <xsl:template match="/">
        <head>
            <link href="css/inca.css" rel="stylesheet" type="text/css" />
        </head>
        <body>
            <xsl:choose>
                <xsl:when test="count(/combo/error)&gt;0">
                    <i>The following error occured:</i>
                    <xsl:for-each select="/combo/error">
                        <h3>
                            <xsl:value-of select="." />
                        </h3>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <h1 class="body"><xsl:text>Inca Results for </xsl:text><xsl:value-of select="/combo/suite/name"/></h1>
	            <xsl:variable name="datenow" select="date:new()" />
  	            <xsl:variable name="dateformat" select="sdf:new('MM-dd-yyyy hh:mm a (z)')" />
	            <p class="footer">Page loaded: <xsl:value-of select="sdf:format($dateformat, $datenow)" /></p>
                    <xsl:call-template name="printLegend"/>
                    <xsl:call-template name="printJumpTable"/>
                    <xsl:call-template name="printResultsTable"/>
                    <xsl:call-template name="footer"/>
                </xsl:otherwise>
            </xsl:choose>
        </body>
    </xsl:template>

    <xsl:template name="printLegend">
        <table cellpadding="1" class="subheader">
            <tr valign="top">
                <td class="na">
                	<font color="black">n/a</font>
                 </td>
                <td class="clear">
                	<font color="black">does not apply to resource</font>
                </td>
            </tr>
            <tr valign="top">
                <td class="clear"/>
                <td class="clear">
                	<font color="black">missing (not yet executed)</font>
                </td>
            </tr>
            <tr valign="top">
                <td class="pass">
                	<font color="black">pass</font>
                </td>
                <td class="clear">
                	<font color="black">passed</font>
                </td>
            </tr>
            <tr valign="top">
                <td class="error">
                	<font color="black">error</font>
                </td>
                <td class="clear">
                	<font color="black">error</font>
                </td>
            </tr>
	    <xsl:if test="$markOld!=''">
                <tr valign="top">
              <td class="clear"><font color="black">*</font></td>
              <td class="clear"><font color="black">older than <xsl:value-of select="$markHours"/> hour<xsl:if test="$markHours!='1'">s</xsl:if></font></td>
            </tr>
            </xsl:if>
        </table><br/>
    </xsl:template>

    <xsl:template name="printJumpTable">
        <!-- print table with list of series in the suite, four series in a col -->
        <table cellpadding="8">
            <tr valign="top">
                <td>
                    <xsl:for-each select="distinct-values(combo/suite/reportSummary/nickname)">
                        <xsl:sort/>
                        <xsl:variable name="anc">
                            <xsl:value-of select="'#'" />
                            <xsl:value-of select="." />
                        </xsl:variable>
                        <xsl:if test="position() mod 4 = 1">
                            <td />
                        </xsl:if>
                        <li>
                            <a href="{$anc}"><xsl:value-of select="." /></a>
                        </li>
                    </xsl:for-each>
                </td>
            </tr>
        </table>
    </xsl:template>

    <xsl:template name="printResultsTable">
      <table class="subheader">
      <xsl:for-each select="distinct-values(combo/suite/reportSummary/nickname)">
        <xsl:sort/>
        <xsl:if test="position() mod 4 = 1">
        <tr>
            <td class="subheader"/>
            <xsl:for-each select="$voResources">
                <xsl:sort/>
                <td class="subheader">
                    <xsl:value-of select="name" />
                </td>
            </xsl:for-each>
        </tr>
        </xsl:if>
        <!-- print row with series name and result for each resource -->
        <xsl:variable name="testname" select="." />
        <tr>
            <td class="clear">
                <xsl:element name="a">
                    <xsl:attribute name="name">
                        <xsl:value-of select="$testname" />
                    </xsl:attribute>
                </xsl:element>
                <xsl:value-of select="$testname" />
            </td>
            <xsl:for-each select="$voResources">
                <xsl:sort/>
                <xsl:variable name="regexHost">
                    <xsl:value-of select="name" />
                    <xsl:value-of select="'|'" />
                    <xsl:value-of select="replace(macros/macro[name='__regexp__']/value, ' ','|')"/>
                </xsl:variable>
                <xsl:variable name="result" select="/combo/suite/reportSummary[matches(hostname, $regexHost) and nickname=$testname]" />
                <xsl:variable name="instance" select="$result/instanceId" />
                <xsl:variable name="conf" select="$result/seriesConfigId" />
		<xsl:variable name="comparitor" select="$result/comparisonResult" />
		<xsl:variable name="foundVersion" select="$result/body/package/version" />
		<xsl:variable name="depth" select="$result/body/performance/benchmark/statistics/statistic[matches(., 'depth')]/value" />
                <xsl:variable name="completed" select="string($result/body)" />
                <xsl:choose>
                    <xsl:when test="count($result)>0">
                        <!-- resource is not exempt -->
                        <xsl:variable name="href">
                            <xsl:value-of select="'xslt.jsp?xsl=instance.xsl&amp;instanceID='" />
                            <xsl:value-of select="$instance" />
                            <xsl:value-of select="'&amp;configID='" />
                            <xsl:value-of select="$conf" />
                        </xsl:variable>
                        <xsl:variable name="exit">
                            <xsl:choose>
                                <xsl:when test="string($instance)=''">
                                    <xsl:value-of select="''" />
                                </xsl:when>
                                <xsl:when test="$completed!='' and ($comparitor='Success' or count($comparitor)=0)">
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
                                    <a href="{$href}">
					<xsl:choose>
                                          <xsl:when test="string($depth)!=''">
                                            <xsl:value-of select="$depth"/>
                                          </xsl:when>
                                          <xsl:when test="string($foundVersion)=''">
                                            <xsl:value-of select="$exit"/>
                                          </xsl:when>
                                        <xsl:otherwise>
                                          <xsl:value-of select="$foundVersion" />
                                        </xsl:otherwise>
                                      </xsl:choose>
				    </a>
                                    <xsl:if test="$markOld!=''">
                                        <xsl:call-template name="markOldData">
                                                <xsl:with-param name="gmt" select="$result/gmt" as="xs:dateTime"/>
                                        </xsl:call-template>
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
            </xsl:for-each>
        </tr>
      </xsl:for-each>
      </table>
    </xsl:template>

    <xsl:template name="markOldData">   
        <xsl:param name="gmt" />        
        <xsl:variable name="now" select="current-dateTime()" />
        <xsl:variable name="acceptedAge" select="xdt:dayTimeDuration($markAge)" />
        <!-- mark with * if older than acceptedAge -->
        <xsl:if test="$gmt le ($now - $acceptedAge)">
                <xsl:value-of select="' *'" />
        </xsl:if>                       
    </xsl:template>  

</xsl:stylesheet>
