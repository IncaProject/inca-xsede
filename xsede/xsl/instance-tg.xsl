<?xml version="1.0" encoding="UTF-8"?>

<!-- Author: Kate Ericson, TeraGrid -->

<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns="http://www.w3.org/1999/xhtml" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:sdf="java.text.SimpleDateFormat"
	xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes">
 
    <xsl:param name="url" />
    <xsl:param name="page" />
    <xsl:template match="/">
	<head>
            <link href="css/inca.css" rel="stylesheet" type="text/css"/>
        </head>
        <body>
          <xsl:call-template name="test" />
        </body>
    </xsl:template>

    <xsl:template name="test">
        <xsl:variable name="report" select="/combo/reportDetails/report"/>
        <xsl:variable name="config" select="/combo/reportDetails/seriesConfig"/>
        <xsl:variable name="configId" select="/combo/reportDetails/seriesConfigId"/>
        <xsl:variable name="nickname" select="$config/nickname"/>
        <xsl:variable name="repname" select="$report/name"/>
        <xsl:variable name="host" select="$report/hostname"/>
        <xsl:variable name="repository" select="substring-before($config/series/uri, $repname)"/>
        <xsl:variable name="rep-cgi">
            <xsl:value-of select="$repository"/>
            <xsl:value-of select="'../cgi-bin/reporters.cgi?reporter='"/>
            <xsl:value-of select="$repname"/>
            <xsl:value-of select="'&amp;action=help'"/>
        </xsl:variable>
        <xsl:variable name="exit"  select="$report/exitStatus"/>
	<xsl:variable name="packageVersion" select="$report/body/package/version" />
	<xsl:variable name="subpackageVersion" select="$report/body/package/subpackage/version" />
        <xsl:variable name="complete" select="$exit/completed"/>
        <xsl:variable name="comp" select="/combo/reportDetails/comparisonResult"/>
        <xsl:variable name="resultText">
            <xsl:choose>
                <xsl:when test="count($comp)>0">
                    <xsl:value-of select="$comp"/>
                </xsl:when>
                <xsl:when test="$complete='true'">
                    <xsl:value-of select="'completed'"/>
                </xsl:when>
                <xsl:when test="$complete='false'">
                    <xsl:value-of select="'did not complete'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'unknown'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
	<xsl:variable name="nickName">
		<xsl:choose>
               		<xsl:when test="$nickname!=''">
                        	<xsl:value-of select="$nickname"/>
                        </xsl:when>
                        <xsl:otherwise>
                          	<xsl:value-of select="$report/name"/>
                        </xsl:otherwise>
       		</xsl:choose>
	</xsl:variable>
        <table width="600" cellpadding="4">
            <tr>
                <td colspan="2">
                    <h3><xsl:text>Details for "</xsl:text><xsl:value-of select="$nickName"/><xsl:text>" series</xsl:text></h3>
                </td>
            </tr>
            <tr>
                <td colspan="2" class="header"><xsl:text>Result:</xsl:text></td>
            </tr>
            <tr>
                <td colspan="2">
                    <p><xsl:value-of select="$resultText"/></p>
		    <xsl:if test="$resultText=$comp">
                      <p class="code"><xsl:text>Expecting: </xsl:text><xsl:value-of select="$config/acceptedOutput/comparison"/></p>
		    </xsl:if>
		    <xsl:if test="string($packageVersion)!=''">
                      <p class="code"><xsl:text>Found: </xsl:text><xsl:value-of select="$packageVersion"/></p>
		    </xsl:if>
		    <xsl:if test="string($subpackageVersion)!=''">
                      <p class="code"><xsl:text>Found: </xsl:text>
                        <xsl:for-each select="$report/body/package/subpackage">
                            <xsl:value-of select="ID"/><xsl:text>: </xsl:text><xsl:value-of select="version"/><br/>
                        </xsl:for-each>
		      </p>
		    </xsl:if>
		    <xsl:if test="$resultText='did not complete' or $resultText='unknown' or $resultText=$comp">
		      <xsl:variable name="msg" select="$exit/errorMessage" />
                      <p class="code">
      			<xsl:call-template name="break">
          			<xsl:with-param name="text" select="$msg"/>
      			</xsl:call-template>
		      </p>
		      <xsl:if test="$msg=''">
                      <p class="code">
      			<xsl:call-template name="break">
          			<xsl:with-param name="text" select="//stderr"/>
      			</xsl:call-template>
		      </p>
		    </xsl:if>
		    </xsl:if>
                </td>
            </tr>
            <tr>
                <td colspan="2" class="header"><xsl:text>Reporter details:</xsl:text></td>
            </tr>
            <tr>
                <td><xsl:text>reporter name</xsl:text></td>
                <td>
                    <a href="{$rep-cgi}"><xsl:value-of select="$repname"/></a>
                    <br/>
                    <xsl:text> (click name for more info)</xsl:text>
                </td>
            </tr>
            <tr>
                <td><xsl:text>reporter version</xsl:text></td>
                <td><xsl:value-of select="$config/series/version"/></td>
            </tr>
            <tr>
                <td colspan="2" class="header"><xsl:text>Execution information:</xsl:text></td>
            </tr>
            <tr>
                <td><xsl:text>ran at</xsl:text></td>
                <td>
		    <xsl:variable name="dateformat" select="sdf:new('MM-dd-yyyy hh:mm a (z)')" />
        	    <xsl:variable name="gmt" select="$report/gmt" as="xs:dateTime" />
        	    <xsl:value-of select="sdf:format($dateformat, $gmt)" />
                </td>
            </tr>
            <tr>
                <td><xsl:text>age</xsl:text></td>
        	<xsl:variable name="now" select="current-dateTime()" />
        	<xsl:variable name="gmt" select="$report/gmt" as="xs:dateTime" />
        	<xsl:variable name="age" select="$now - $gmt" />
		<xsl:variable name="age-p" select="replace($age, 'P', '')" />
		<xsl:variable name="age-d" select="replace($age-p, 'D', ' days ')" />
		<xsl:variable name="age-t" select="replace($age-d, 'T', '')" />
		<xsl:variable name="age-h" select="replace($age-t, 'H', ' hours ')" />
		<xsl:variable name="age-m" select="replace($age-h, 'M.*', ' minutes')" />
                <td><xsl:value-of select="$age-m"/></td>
            </tr>
            <tr>
                <td><xsl:text>cron</xsl:text></td>
                <td>
                    <xsl:for-each select="$config/schedule/cron/*[not(self::suspended) and not(self::numOccurs)]">
                       <xsl:value-of select="."/><xsl:text> </xsl:text>
                    </xsl:for-each>
                </td>
            </tr>
            <tr>
                <td><xsl:text>ran on (hostname)</xsl:text></td>
                <td><xsl:value-of select="$host"/></td>
            </tr>
            <xsl:variable name="used" select="/combo/reportDetails/sysusage"/>
            <tr>
                <td><xsl:text>memory usage (MB)</xsl:text></td>
                <td><xsl:value-of select="$used/memory"/></td>
            </tr>
            <tr>
                <td><xsl:text>cpu time (secs)</xsl:text></td>
                <td><xsl:value-of select="$used/cpuTime"/></td>
            </tr>
            <tr>
                <td><xsl:text>wall clock time (secs)</xsl:text></td>
                <td><xsl:value-of select="$used/wallClockTime"/></td>
            </tr>
            <tr>
                <td colspan="2" class="header"><xsl:text>Input parameters:</xsl:text></td>
            </tr>
            <xsl:for-each select="$config/series/args//arg">
	        <xsl:sort/>
                <tr><td><xsl:value-of select="name"/></td>
                    <td><xsl:value-of select="value"/></td></tr>
	    </xsl:for-each>
            <tr>
                <td colspan="2" class="header"><xsl:text>Command used to execute the reporter:</xsl:text></td>
            </tr>
            <tr>
                <td colspan="2">
		    <xsl:variable name="context" select="$config/series/context"/>
		    <xsl:variable name="seriesName" select="$config/series/name"/>
		    <xsl:variable name="repPath" select="$report/reporterPath"/>
		    <xsl:variable name="exe" select="replace($context, $seriesName, $repPath)" />
                    <p class="code"> <xsl:text>% </xsl:text><xsl:value-of select="$exe"/> </p>
                </td>
            </tr>
	    <xsl:variable name="log" select="$report/log" />
            <xsl:if test="count($log//system//message)>0">
            <tr>
                <td colspan="2" class="header"><xsl:text>System commands executed by the reporter:</xsl:text></td>
            </tr>
                <tr>
                    <td colspan="2"><xsl:text>Note that the reporter may execute other actions in
                        between system commands (e.g., change directories).</xsl:text>
                        <xsl:for-each select="$report/log/system">
                            <p class="code"><xsl:text>% </xsl:text><xsl:value-of select="message"/></p>
                        </xsl:for-each>
                    </td>
                </tr>
            </xsl:if>
            <xsl:if test="count($log//info//message)>0 or count($log//debug//message)>0">
                <tr>
                    <td colspan="2"><xsl:text>Debug or informational output:</xsl:text>
                        <xsl:for-each select="$log/info">
                            <p class="code"><xsl:value-of select="message"/></p>
                        </xsl:for-each>
                        <xsl:for-each select="$log/debug">
                            <p class="code"><xsl:value-of select="message"/></p>
                        </xsl:for-each>
                    </td>
                </tr>
            </xsl:if>
	    <tr>
                <td colspan="2" class="header"><xsl:text>Run now command (system admins only):</xsl:text></td>
            </tr>
            <tr>
                <td colspan="2">
                    <xsl:variable name="repPath" select="$report/reporterPath"/>
                    <xsl:variable name="incaloc" select="replace($report/reporterPath, '/var/reporter-packages/bin/.*', '')" />
                    <p class="code"> <xsl:text>% cd </xsl:text>
                        <xsl:value-of select="$incaloc"/>
                        <xsl:text>; ./bin/teragrid-run-now </xsl:text>
                        <xsl:value-of select="$nickName"/></p>
                </td>
            </tr>
            <xsl:variable name="addComment" select="$url[not(matches(., 'noComment'))]"/>
	    <xsl:if test="$addComment">
	    <tr>
               <td colspan="2" class="header"><xsl:text>Comments:</xsl:text></td>
            </tr>
	        <tr><td colspan="2">
    	        <xsl:choose>
                    <xsl:when test="count(/combo/comments/row)>0">
                        <xsl:for-each select="/combo/comments/row">
		                    <xsl:sort select="date" data-type="text" order="descending"/>
			                <p class="code"><xsl:value-of select="comment"/>
			                <br/> (<xsl:value-of select="author"/>, <xsl:value-of select="date"/>)</p>
                        </xsl:for-each>
	        	<hr/>
                    </xsl:when>
                    <xsl:otherwise>
		                <p>No comments for this series.</p>
                    </xsl:otherwise>
                </xsl:choose>
		<xsl:variable name="https" select="replace($page, 'http://', 'http://')" />
		<xsl:variable name="jsp" select="replace($https, 'xslt-tg.jsp', 'comments.jsp')" />
		<br/>
		<form method="post" action="{$jsp}">
		       	<input type="hidden" name="series" value="{$configId}"/>
                    	<input type="hidden" name="host" value="{$host}"/>
                    	<input type="hidden" name="nickname" value="{$nickname}"/>
                    	<input type="hidden" name="login" value=""/>
                    	<input type="hidden" name="comment" value=""/>
                    	<input type="hidden" name="author" value=""/>
                    	<input type="submit" name="Submit" value="add a comment"/>
                </form>
	        </td></tr>
		</xsl:if>
        </table>
    </xsl:template>

  <xsl:template name="break">
    <xsl:param name="text" select="."/>
    <xsl:choose>
      <xsl:when test="contains($text, '&#xa;')">
        <xsl:value-of select="substring-before($text, '&#xa;')"/> <br/>
        <xsl:call-template name="break">
          <xsl:with-param name="text" select="substring-after($text, '&#xa;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
