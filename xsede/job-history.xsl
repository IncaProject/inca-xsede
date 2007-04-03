<?xml version="1.0" encoding="UTF-8"?>

<!-- Author: Kate Ericson, TeraGrid -->

<xsl:stylesheet version="1.0" 
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
        xmlns="http://www.w3.org/1999/xhtml" 
        xmlns:xs="http://www.w3.org/2001/XMLSchema"
        xmlns:sdf="java.text.SimpleDateFormat"
        xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes">

    <xsl:param name="type"/>
    <xsl:param name="xsl"/>
    <xsl:variable name="jsp">
        <xsl:value-of select="'xslt.jsp?xsl=instance.xsl'"/>
        <xsl:value-of select="'&amp;instanceID='"/>
    </xsl:variable>

    <xsl:template match="/">
        <head>
            <link href="css/inca.css" rel="stylesheet" type="text/css"/>
        </head>
        <body>
          <h1 class="body"><xsl:value-of select="series/reportDetails/seriesConfig/series/name"/></h1>
	  <br/><font class="ptext"><b><xsl:text>Num. jobs per unique user:</xsl:text></b></font><br/>
         <table class="subheader">
	  <xsl:for-each select="series/reportDetails">
            <xsl:variable name="details" select="."/>
	    <xsl:if test="position() = 1"> 
                <!-- print DN stats header row -->
                <tr>
                    <td class="header"><xsl:text>Machine</xsl:text></td>
                    <td class="header"><xsl:text>Reporter Status</xsl:text></td>
                    <td class="header"><xsl:text>Reporter Ran (GMT)</xsl:text></td>
                    <td class="header"><xsl:text>Start/End Time Arg (GMT)</xsl:text></td>
                    <td class="header"><xsl:text>User's Distinguished Name (DN)</xsl:text></td>
                    <td class="header"><xsl:text>Num. Jobs</xsl:text></td>
                </tr>
            </xsl:if>
	        <!-- print DN stats -->
                <xsl:call-template name="getResults">
                   <xsl:with-param name="details" select="$details"/>
                   <xsl:with-param name="col" select="'5'"/>
                   <xsl:with-param name="ca" select="'0'"/>
                </xsl:call-template>
	  </xsl:for-each>
	 </table>
	 <br/><br/><br/><br/>
	 <font class="ptext"><b><xsl:text>CA stats:</xsl:text></b></font><br/>
         <table class="subheader">
	  <xsl:for-each select="series/reportDetails">
            <xsl:sort select="report/gmt" order="descending"/>
            <xsl:variable name="details" select="."/>
	    <xsl:if test="position() = 1"> 
	        <!-- print CA stats header row -->
                <tr>
                    <td class="header"><xsl:text>Machine</xsl:text></td>
                    <td class="header"><xsl:text>Reporter Status</xsl:text></td>
                    <td class="header"><xsl:text>Reporter Ran (GMT)</xsl:text></td>
                    <td class="header"><xsl:text>Start/End Time Arg (GMT)</xsl:text></td>
                    <td class="header"><xsl:text>Certificate Authority (CA)</xsl:text></td>
                    <td class="header"><xsl:text>Total User Jobs</xsl:text></td>
                    <td class="header"><xsl:text>Unique User Jobs</xsl:text></td>
                </tr>
            </xsl:if>
	        <!-- print CA stats -->
                <xsl:call-template name="getResults">
                   <xsl:with-param name="details" select="$details"/>
                   <xsl:with-param name="col" select="'4'"/>
                   <xsl:with-param name="ca" select="'1'"/>
                </xsl:call-template>
	  </xsl:for-each>
	 </table>
        </body>
    </xsl:template>


    <xsl:template name="getResults">
        <xsl:param name="details"/>
	<xsl:param name="col"/>
	<xsl:param name="ca"/>

            <xsl:variable name="uri" select="$details/seriesConfig/series/uri"/>
            <xsl:variable name="instance" select="$details/instanceId"/>
            <xsl:variable name="conf" select="$details/seriesConfigId"/>
            <xsl:variable name="ran" select="$details/report/gmt"/>
            <xsl:variable name="completed" select="$details/report/body"/>
            <xsl:variable name="host" select="$details/seriesConfig/resourceHostname"/>
            <xsl:variable name="usage" select="$details/report/body/usage"/>
            <xsl:variable name="begin" select="$usage/entry[matches(type, 'begin')]"/>
            <xsl:variable name="end" select="$usage/entry[matches(type, 'end')]"/>
            <xsl:variable name="user" select="$usage//entry[matches(type, 'user')]"/>
            <xsl:variable name="org" select="$usage//entry[matches(type, 'org')]"/>

            <xsl:variable name="exit">
                <xsl:choose>
                    <xsl:when test="$instance=''">
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
            <tr> 
 		<xsl:choose>
                <xsl:when test="$uri!=''">
                    <!-- resource is not exempt -->
                    <xsl:variable name="href">
                        <xsl:value-of select="$jsp"/>
                        <xsl:value-of select="$instance"/>
                        <xsl:value-of select="'&amp;configID='"/>
                        <xsl:value-of select="$conf"/>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$exit!=''">
                       	    <xsl:choose>
                       	    <xsl:when test="$org!=''">
                       	    	<xsl:if test="$ca='1'">
                    		<xsl:for-each select="$org">
                    			<xsl:sort select="statistics/statistic[matches(name, 'total')]/value" data-type="number" order="descending"/>
					<td class="clear"><xsl:value-of select="$host"/></td>
                            		<td class="{$exit}"> <a href="{$href}"><xsl:value-of select="$exit"/></a> </td>
					<td class="clear"><xsl:value-of select="$ran"/></td>
					<td class="clear"><xsl:value-of select="$begin/name"/> <xsl:value-of select="' to '"/><br/><xsl:value-of select="$end/name"/></td>
					<td class="clear"><xsl:value-of select="name"/></td>
					<td class="clear"><xsl:value-of select="statistics/statistic[matches(name, 'total')]/value"/></td>
					<td class="clear"><xsl:value-of select="statistics/statistic[matches(name, 'unique')]/value"/></td>
					<tr/>
                            	</xsl:for-each>
                            	</xsl:if>
                       	    	<xsl:if test="$ca='0'">
                    		<xsl:for-each select="$user">
                    			<xsl:sort select="statistics/statistic[matches(name, 'count')]/value" data-type="number" order="descending"/>
					<td class="clear"><xsl:value-of select="$host"/></td>
                            		<td class="{$exit}"> <a href="{$href}"><xsl:value-of select="$exit"/></a> </td>
					<td class="clear"><xsl:value-of select="$ran"/></td>
					<td class="clear"><xsl:value-of select="$begin/name"/> <xsl:value-of select="' to '"/><br/><xsl:value-of select="$end/name"/></td>
					<td class="clear"><xsl:value-of select="name"/></td>
					<td class="clear"><xsl:value-of select="statistics/statistic[matches(name, 'count')]/value"/></td>
					<tr/>
                            	</xsl:for-each>
                            	</xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
				<xsl:variable name="span" select="$col - 1"/>
                    		<td class="clear" colspan="{$span}"><xsl:text> </xsl:text></td>
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
		    <td class="clear"><xsl:value-of select="$host"/></td>
                    <td class="na" colspan="{$col}"><xsl:text>n/a</xsl:text></td>
                </xsl:otherwise>
            </xsl:choose>
	    <td colspan="3"/>
            </tr>
    </xsl:template>



</xsl:stylesheet>
