<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
		xmlns:sdf="java.text.SimpleDateFormat"
        	xmlns:date="java.util.Date"
		xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes"
		xmlns:xs="http://www.w3.org/2001/XMLSchema">
    
    <xsl:include href="tg-menu.xsl"/>
    <xsl:include href="footer.xsl"/>
    <xsl:param name="url" />

    <xsl:variable name="specificPackage">
	<xsl:analyze-string select="$url" regex="(.*)package=(.[^&amp;]+)(.*)">
    		<xsl:matching-substring>
      			<xsl:value-of select="regex-group(2)"/>
    		</xsl:matching-substring>
    		<xsl:non-matching-substring>
      			<xsl:value-of select="''"/>
    		</xsl:non-matching-substring>
  	</xsl:analyze-string>
    </xsl:variable>
    <xsl:variable name="markOld" select="$url[matches(., 'markOld')]"/>
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
    <!-- format of var below is "P, num days, D, T, num hours, H, num minutes, M" -->
    <xsl:variable name="markAge">
	<xsl:value-of select="'P0DT'" />
	<xsl:value-of select="$markHours" />
	<xsl:value-of select="'H0M'" />
    </xsl:variable>
    <xsl:variable name="matchProd" select="$url[matches(., 'reporterStatus=prod')]"/>
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
                    <xsl:call-template name="printResults" />
                    <xsl:call-template name="footer" />
                </xsl:otherwise>
            </xsl:choose>
        </body>
    </xsl:template>

    <xsl:template name="printResults">
        <table cellpadding="0" width="100%"><tr><td>
	<h1 class="body">
            <xsl:text>CTSSv4 </xsl:text><xsl:value-of select="combo/stack/id" /><xsl:text> Kit</xsl:text>
        </h1>
	<xsl:variable name="datenow" select="date:new()" />
  	<xsl:variable name="dateformat" select="sdf:new('MM-dd-yyyy hh:mm a (z)')" />
	<p class="footer">Page loaded: <xsl:value-of select="sdf:format($dateformat, $datenow)" /></p>
        </td><td align="right">
	<xsl:call-template name="tg-menu" />
	</td></tr></table>
        <xsl:call-template name="printLegend" />
        <xsl:choose>
            <xsl:when test="$specificPackage=''">
                <xsl:if test="count(/combo/stack/category/package)>1">
                    <xsl:call-template name="printPackageListTable" />
                </xsl:if>
                <xsl:call-template name="printAllPackageResults" />
            </xsl:when>
            <xsl:otherwise>
                <table class="subheader">
                    <xsl:call-template name="printPackageRows">
                        <xsl:with-param name="package" select="$specificPackage" />
                    </xsl:call-template>
                </table>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="printLegend">
     <table border="0" cellspacing="8" cellpadding="0">
        <tr valign="top">
          <td><table cellpadding="1" class="subheader">
            <tr valign="top">
              <td class="na"><font color="black">n/a</font></td>
              <td class="clear"><font color="black">does not apply to resource</font></td>
            </tr>
            <tr valign="top">
              <td class="clear"/>          
              <td class="clear"><font color="black">missing (not yet executed)</font></td>
            </tr>
            <tr valign="top">
              <td class="pass"><font color="black">pass</font></td>
              <td class="clear"><font color="black">passed</font></td>
            </tr>
            <tr valign="top">
              <td class="error"><font color="black">error</font></td>
              <td class="clear"><font color="black">error</font></td>
            </tr>
          </table></td>
          <td><table cellpadding="1" class="subheader">
            <tr valign="top">
              <td class="dev"/>          
              <td class="clear"><font color="black">test under development</font></td>
            </tr>
            <tr valign="top">
              <td class="pkgWait"><font color="black">pkgWait</font></td>
              <td class="clear"><font color="black">waiting for package delivery</font></td>
            </tr>
            <tr valign="top">
              <td class="incaWait"><font color="black">incaWait</font></td>
              <td class="clear"><font color="black">waiting for inca test change</font></td>
            </tr>
		<tr valign="top">
              <td class="incaErr"><font color="black">incaErr</font></td>
              <td class="clear"><font color="black">inca framework error</font></td>
            </tr>
          </table></td>
		  <td><table cellpadding="1" class="subheader"> 
            <tr valign="top">
              <td class="tkt"><font color="black">tkt-#</font></td>
              <td class="clear"><font color="black">TeraGrid ticket number </font></td>
            </tr>
            <tr valign="top">
              <td class="timeOut"><font color="black">timeOut</font></td>
              <td class="clear"><font color="black">reporter timed out</font></td>
            </tr>
            <xsl:if test="$markOld!=''">
		<tr valign="top">
              <td class="clear"><font color="black">*</font></td>
              <td class="clear"><font color="black">older than <xsl:value-of select="$markHours"/> hour<xsl:if test="$markHours!='1'">s</xsl:if></font></td>
            </tr>
	    </xsl:if>
          </table></td>
        </tr>
      </table><br/>
  </xsl:template>

    <xsl:template name="printPackageListTable">
        <!-- print table with list of packages in the stack, four packages in a col -->
        <table cellpadding="8">
            <tr valign="top">
                <td>
                    <xsl:for-each select="combo/stack/category/package">
                        <xsl:sort/>
                        <xsl:if test="count(status[.='dev'])!=1 or $prodReportersOnly='false'">
                            <xsl:variable name="anc">
                                <xsl:value-of select="'#'" />
                                <xsl:value-of select="id" />
                            </xsl:variable>
                            <xsl:if test="position() mod 4 = 1">
                                <td />
                            </xsl:if>
                            <li>
                                <a href="{$anc}"><xsl:value-of select="id" /></a>
                            </li>
                        </xsl:if>
                    </xsl:for-each>
                </td>
            </tr>
        </table>
    </xsl:template>

    <xsl:template name="printAllPackageResults">
        <table class="subheader">
            <xsl:for-each select="combo/stack/category">
                <xsl:sort/>
                <xsl:variable name="id" select="id" />
                <xsl:variable name="cats" select="/combo/stack/category" />
                <!-- print category header row only if there is more than 1 category and 
		     if the status of at least one category package should be displayed -->
                <xsl:if test="count($cats)>1 and ((count(package[status='dev'])!=count(package)) or $prodReportersOnly='false')">
                    <xsl:variable name="span" select="count($voResources)+1" />
                    <tr>
                        <td colspan="{$span}" class="header">
                            <xsl:value-of select="upper-case($id)" />
                        </td>
                    </tr>
                </xsl:if>
                <xsl:for-each select="package">
                    <xsl:sort/>
                    <xsl:variable name="packDev" select="count(.[status='dev'])" />
                    <xsl:if test="($prodReportersOnly='true' and $packDev=0) or $prodReportersOnly='false'">
                        <xsl:call-template name="printPackageRows">
                            <xsl:with-param name="package" select="id" />
                        </xsl:call-template>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </table>
    </xsl:template>

    <xsl:template name="printPackageRows">
        <xsl:param name="package" />
        <!-- print subheader row for package with package name and each resource name -->
        <tr>
            <td class="subheader">
                <xsl:element name="a">
                    <xsl:attribute name="name">
                        <xsl:value-of select="$package" />
                    </xsl:attribute>
                </xsl:element>
                <xsl:value-of select="$package" />
            </td>
            <xsl:for-each select="$voResources">
                <xsl:sort/>
                <td class="subheader">
                    <xsl:value-of select="name" />
                </td>
            </xsl:for-each>
        </tr>
        <xsl:variable name="cat" select="/combo/stack/category" />
        <!-- print version test row if package has version test -->
        <xsl:variable name="ver" select="$cat/package[id=$package]/tests/version" />
        <xsl:variable name="numVerDev" select="count($ver[status='dev'])" />
        <xsl:if test="count($ver)>0 and (($prodReportersOnly='true' and $numVerDev=0) or $prodReportersOnly='false')">
            <xsl:call-template name="printVersionResultsRow">
                <xsl:with-param name="package" select="$package" />
            </xsl:call-template>
        </xsl:if>
        <!-- print unit test row(s) if package has unit tests -->
        <xsl:variable name="units" select="$cat/package[id=$package]/tests/unitalias" />
        <xsl:variable name="numtests" select="count($units)" />
        <xsl:variable name="numUnitDev" select="count($units[status='dev'])" />
	<xsl:choose>
        <!-- print a row for each unit test if marking as old -->
	  <xsl:when test="$markOld!=''">
            <xsl:for-each select="$units">
                <xsl:variable name="testStat" select="count(.[status='dev'])"/>
                <xsl:if test="($prodReportersOnly='true' and $testStat=0) or $prodReportersOnly='false'">
                    <xsl:call-template name="printUnitTestResultsRow">
                        <xsl:with-param name="test" select="." />
                	<xsl:with-param name="package" select="$package" />
                    </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
	  </xsl:when>
	<xsl:otherwise>
        <!-- print a row for each unit test if there is only one unit test or if getting results for a specific package -->
	<xsl:if test="$numtests=1 or $specificPackage!=''">
            <xsl:for-each select="$units">
                <xsl:variable name="testStat" select="count(.[status='dev'])"/>
                <xsl:if test="($prodReportersOnly='true' and $testStat=0) or $prodReportersOnly='false'">
                    <xsl:call-template name="printUnitTestResultsRow">
                        <xsl:with-param name="test" select="." />
                	<xsl:with-param name="package" select="$package" />
                    </xsl:call-template>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
        <!-- print a summary row for package unit tests if there is more than one unit test and not a specific package and not marking as old -->
        <xsl:if test="$numtests>1 and $specificPackage=''">
          <xsl:if test="($prodReportersOnly='true' and $numUnitDev!=$numtests) or $prodReportersOnly='false'">
            <xsl:call-template name="printUnitTestSummaryRow">
                <xsl:with-param name="package" select="$package" />
            </xsl:call-template>
          </xsl:if>
        </xsl:if>
	</xsl:otherwise>
	</xsl:choose>
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
    
    <xsl:template name="getClass">
        <xsl:param name="status" />
        <xsl:param name="result" />
        <xsl:choose>
            <xsl:when test="$status!=''">
                <xsl:value-of select="$status" />
            </xsl:when>
            <xsl:when test="$result[matches(., 'tkt-')]">
                <xsl:value-of select="'tkt'" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$result" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="printUnitTestSummaryRow">
        <xsl:param name="package" />
        <xsl:variable name="pack" select="/combo/stack/category/package[id=$package]" />
        <xsl:variable name="set" select="$pack/tests" />
        <xsl:variable name="packWait" select="$pack/packagewait" />
        <xsl:variable name="incaWait" select="$pack/incawait" />
        <xsl:variable name="condition" select="$prodReportersOnly='false'" />
        <xsl:variable name="tests" select="$set/unitalias[not(matches(status, 'dev'))]/id[not($condition)] | $set/unitalias/id[$condition]"/>
        <xsl:variable name="numTests" select="count($tests)" />
        <tr>
            <td class="clear">
                <xsl:value-of select="$numTests" />
                <xsl:value-of select="' tests'" />
            </td>
            <xsl:for-each select="$voResources">
                <xsl:sort/>
                <xsl:variable name="thisResource" select="name" />
                <xsl:variable name="regexHost">
                    <xsl:value-of select="name" />
                    <xsl:value-of select="'|'" />
                    <xsl:value-of select="replace(macros/macro[name='__regexp__']/value, ' ','|')"/>
                </xsl:variable>
                <xsl:variable name="sumMatch" select="/combo/suite/reportSummary[matches(hostname, $regexHost)]/nickname[. = $tests]" />
                <xsl:variable name="testMatches" select="count($sumMatch)" />
                <xsl:variable name="completed" select="$sumMatch/../body" />
                <xsl:variable name="fail" select="count($completed[.=''])" />
                <xsl:variable name="numFail" select="if (number($fail)=number($fail)) then $fail else 0" />
                <xsl:variable name="pass" select="count($completed[.!=''])" />
                <xsl:variable name="numPass" select="if (number($pass)=number($pass)) then $pass else 0" />
                <xsl:variable name="numMiss" select="$numTests - $numFail - $numPass" />
                <xsl:variable name="numDev" select="count($tests[../status='dev'])" />
                <xsl:variable name="testSum">
                    <xsl:choose>
                        <xsl:when test="$testMatches=0">
                            <xsl:value-of select="'n/a'" />
                        </xsl:when>
                        <xsl:when test="$packWait[matches(resource, $thisResource)]">
                            <xsl:value-of select="'pkgWait'" />
                        </xsl:when>
                        <xsl:when test="$incaWait[matches(resource, $thisResource)]">
                            <xsl:value-of select="'incaWait'" />
                        </xsl:when>
                        <xsl:when test="$numPass>0 and $numPass+$numMiss=$numTests">
                            <xsl:value-of select="'pass'" />
                        </xsl:when>
                        <xsl:when test="$numFail>0">
                            <xsl:value-of select="$numFail" />
                            <xsl:value-of select="' error'" />
                            <xsl:if test="$numFail>1">
                                <xsl:value-of select="'s'" />
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="''" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="color">
                    <xsl:choose>
                        <xsl:when test="$testMatches=0">
                            <xsl:value-of select="'na'" />
                        </xsl:when>
                        <xsl:when test="$testSum='pkgWait'">
                            <xsl:value-of select="'pkgWait'" />
                        </xsl:when>
                        <xsl:when test="$testSum='incaWait'">
                            <xsl:value-of select="'incaWait'" />
                        </xsl:when>
                        <xsl:when test="$numDev=$numTests">
                            <xsl:value-of select="'dev'" />
                        </xsl:when>
                        <xsl:when test="$numPass>0 and $numPass+$numMiss=$numTests">
                            <xsl:value-of select="'true'" />
                        </xsl:when>
                        <xsl:when test="$numFail>0">
                            <xsl:value-of select="'false'" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'clear'" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="href">
                    <xsl:value-of select="'xslt.jsp?package='" />
                    <xsl:value-of select="$package" />
                    <xsl:value-of select="'&amp;'" />
                    <xsl:value-of select="$url" />
                </xsl:variable>
                <td class="{$color}">
		  <xsl:choose>
		    <xsl:when test="$testSum!='n/a'">
                      <a href="{$href}"><xsl:value-of select="$testSum" /></a>
		    </xsl:when>
		    <xsl:otherwise>
                        <xsl:value-of select="$testSum" />
		    </xsl:otherwise>
		  </xsl:choose>
                </td>
            </xsl:for-each>
        </tr>
    </xsl:template>

    <xsl:template name="printVersionResultsRow">
        <xsl:param name="package" />
        <xsl:variable name="pack" select="/combo/stack/category/package[id=$package]" />
        <xsl:variable name="packWait" select="$pack/packagewait" />
        <xsl:variable name="incaWait" select="$pack/incawait" />
        <xsl:variable name="printVer" select="$pack/version" />
        <xsl:variable name="regexVer" select="$pack/versionRE" />
        <xsl:variable name="test" select="$pack/tests/version" />
        <xsl:variable name="status" select="$test/status" />
        <xsl:variable name="subpackages" select="$pack/subpackages" />
        <tr>
            <td class="clear">
                <xsl:text>version: </xsl:text>
                <xsl:value-of select="$printVer" />
		<xsl:if test="count($subpackages)>0">
		  <br/><xsl:value-of select="' ('"/>
		  <xsl:value-of select="$subpackages"/>
		  <xsl:value-of select="' subpackages)'"/>
		</xsl:if>
            </td>
            <xsl:for-each select="$voResources">
                <xsl:sort/>
                <xsl:variable name="thisResource" select="name" />
                <xsl:variable name="regexHost">
                    <xsl:value-of select="name" />
                    <xsl:value-of select="'|'" />
                    <xsl:value-of select="replace(macros/macro[name='__regexp__']/value, ' ','|')"/>
                </xsl:variable>
                <xsl:variable name="result" select="/combo/suite/reportSummary[matches(hostname, $regexHost) and nickname=$test/id]" />
                <xsl:variable name="instance" select="$result/instanceId" />
                <xsl:variable name="conf" select="$result/seriesConfigId" />
                <xsl:choose>
                    <xsl:when test="count($result)>0">
                        <!-- resource is not exempt -->
                        <xsl:variable name="href">
                            <xsl:value-of select="'xslt.jsp?xsl=instance.xsl&amp;instanceID='" />
                            <xsl:value-of select="$instance" />
                            <xsl:value-of select="'&amp;configID='" />
                            <xsl:value-of select="$conf" />
                        </xsl:variable>
                        <xsl:variable name="comparitor" select="$result/comparisonResult" />
                        <xsl:variable name="foundVersion" select="$result/body/package/version" />
                        <xsl:variable name="matchVersion">
			  <xsl:choose>
			    <xsl:when test="count($regexVer)=0">
				<xsl:value-of select="''"/>
			    </xsl:when>
			    <xsl:otherwise>
			        <xsl:value-of select="matches($foundVersion, $regexVer)" />
			    </xsl:otherwise>
			  </xsl:choose>
			</xsl:variable>
                        <xsl:variable name="exit">
                            <xsl:choose>
                        	<xsl:when test="$test/tgTickets/ticket[matches(resource, $thisResource)]">
                            	    <xsl:value-of select="'tkt-'" />
                            	    <xsl:value-of select="$test/tgTickets/ticket[matches(resource, $thisResource)]/number" />
                        	</xsl:when>
                        	<xsl:when test="$packWait[matches(resource, $thisResource)]">
                            	    <xsl:value-of select="'pkgWait'" />
                        	</xsl:when>
                        	<xsl:when test="$incaWait[matches(resource, $thisResource)]">
                            	    <xsl:value-of select="'incaWait'" />
                        	</xsl:when>
                                <xsl:when test="string($instance)=''">
                                    <xsl:value-of select="''" />
                                </xsl:when>
                                <xsl:when test="($matchVersion!='' and $matchVersion!='false') or ($comparitor='Success' or count($comparitor)=0)">
                                    <xsl:value-of select="'pass'" />
                                </xsl:when>
                                <xsl:when test="$result[matches(errorMessage, 'Inca error')]">
                                    <xsl:value-of select="'incaErr'" />
                                </xsl:when>
                                <xsl:when test="$result[matches(errorMessage, 'Reporter exceeded usage limits')]">
                                    <xsl:value-of select="'timeOut'" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="'error'" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$exit!=''">
                                <xsl:variable name="class">
                                    <xsl:call-template name="getClass">
                                        <xsl:with-param name="status" select="$status" />
                                        <xsl:with-param name="result" select="$exit" />
                                    </xsl:call-template>
                                </xsl:variable>
                                <td class="{$class}">
                                    <a href="{$href}">
			                <xsl:choose>
			                  <xsl:when test="count($subpackages)>0 or string($foundVersion)='' or $exit='pkgWait' or $exit='incaWait'">
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
    </xsl:template>

    <xsl:template name="printUnitTestResultsRow">
        <xsl:param name="test" />
        <xsl:param name="package" />
        <xsl:variable name="testname" select="$test/id" />
        <xsl:variable name="status" select="$test/status" />
        <xsl:variable name="pack" select="/combo/stack/category/package[id=$package]" />
        <xsl:variable name="packWait" select="$pack/packagewait" />
        <xsl:variable name="incaWait" select="$pack/incawait" />
        <tr>
            <td class="clear">
                <xsl:value-of select="replace($testname, '^all2all:.*_to_', '')" />
            </td>

            <xsl:for-each select="$voResources">
                <xsl:sort/>
                <xsl:variable name="thisResource" select="name" />
                <xsl:variable name="regexHost">
                    <xsl:value-of select="name" />
                    <xsl:value-of select="'|'" />
                    <xsl:value-of select="replace(macros/macro[name='__regexp__']/value, ' ','|')"/>
                </xsl:variable>
                <xsl:variable name="result" select="/combo/suite/reportSummary[matches(hostname, $regexHost) and nickname=$testname]" />
                <xsl:variable name="instance" select="$result/instanceId" />
                <xsl:variable name="conf" select="$result/seriesConfigId" />
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
                        	<xsl:when test="$test/tgTickets/ticket[matches(resource, $thisResource)]">
                            	    <xsl:value-of select="'tkt-'" />
                            	    <xsl:value-of select="$test/tgTickets/ticket[matches(resource, $thisResource)]/number" />
                        	</xsl:when>
                        	<xsl:when test="$packWait[matches(resource, $thisResource)]">
                            	    <xsl:value-of select="'pkgWait'" />
                        	</xsl:when>
                        	<xsl:when test="$incaWait[matches(resource, $thisResource)]">
                            	    <xsl:value-of select="'incaWait'" />
                        	</xsl:when>
                                <xsl:when test="string($instance)=''">
                                    <xsl:value-of select="''" />
                                </xsl:when>
                                <xsl:when test="$completed!=''">
                                    <xsl:value-of select="'pass'" />
                                </xsl:when>
                                <xsl:when test="$result[matches(errorMessage, 'Inca error')]">
                                    <xsl:value-of select="'incaErr'" />
                                </xsl:when>
                                <xsl:when test="$result[matches(errorMessage, 'Reporter exceeded usage limits')]">
                                    <xsl:value-of select="'timeOut'" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="'error'" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$exit!=''">
                                <xsl:variable name="class">
                                    <xsl:call-template name="getClass">
                                        <xsl:with-param name="status" select="$status" />
                                        <xsl:with-param name="result" select="$exit" />
                                    </xsl:call-template>
                                </xsl:variable>
                                <td class="{$class}">
                                    <a href="{$href}"><xsl:value-of select="$exit" /></a>
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
    </xsl:template>

</xsl:stylesheet>
