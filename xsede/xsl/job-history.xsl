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
    <xsl:variable name="div" select="','"/>

    <xsl:template match="/">
<xsl:text>
		
</xsl:text><xsl:value-of select="series/reportDetails/seriesConfig/series/name"/>
<xsl:text>
		
		
</xsl:text><xsl:text>Num. jobs per unique user:</xsl:text>
<xsl:text>
		
</xsl:text>	
	  <xsl:for-each select="series/reportDetails">
	    <xsl:sort select="report/gmt" data-type="text" order="descending"/>
            <xsl:variable name="details" select="."/>
	    <xsl:if test="position() = 1"> 
                <!-- print DN stats header row -->
                    <xsl:text>Machine</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>Reporter Status</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>Reporter Ran (GMT)</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>Start Arg (GMT)</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>End Arg (GMT)</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>User's Distinguished Name (DN)</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>Num. Jobs</xsl:text>
<xsl:text>
</xsl:text>	
            </xsl:if>
	        <!-- print DN stats -->
                <xsl:call-template name="getResults">
                   <xsl:with-param name="details" select="$details"/>
                   <xsl:with-param name="ca" select="'0'"/>
                </xsl:call-template>
	  </xsl:for-each>
<xsl:text>
		
		
		
</xsl:text><xsl:text>CA stats:</xsl:text>
<xsl:text>
		
</xsl:text>	
          <xsl:variable name="details" select="."/>
	  <xsl:for-each select="series/reportDetails">
	    <xsl:sort select="report/gmt" data-type="text" order="descending"/>
            <xsl:variable name="details" select="."/>
	    <xsl:if test="position() = 1"> 
	        <!-- print CA stats header row -->
                    <xsl:text>Machine</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>Reporter Status</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>Reporter Ran (GMT)</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>Start Arg (GMT)</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>End Arg (GMT)</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>Certificate Authority (CA)</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>Total User Jobs</xsl:text><xsl:value-of select="$div"/>
                    <xsl:text>Unique User Jobs</xsl:text>
<xsl:text>
</xsl:text>	
            </xsl:if>
	        <!-- print CA stats -->
                <xsl:call-template name="getResults">
                   <xsl:with-param name="details" select="$details"/>
                   <xsl:with-param name="ca" select="'1'"/>
                </xsl:call-template>
	  </xsl:for-each>
    </xsl:template>
    <xsl:template name="getResults">
        <xsl:param name="details"/>
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
 		<xsl:choose>
                <xsl:when test="$uri!=''">
                    <!-- resource is not exempt -->
                    <xsl:choose>
                        <xsl:when test="$exit!=''">
                       	    <xsl:choose>
                       	    <xsl:when test="$org!=''">
                       	    	<xsl:if test="$ca='1'">
                    		<xsl:for-each select="$org">
                    			<xsl:sort select="statistics/statistic[matches(name, 'total')]/value" data-type="number" order="descending"/>
					<xsl:value-of select="$host"/><xsl:value-of select="$div"/>
                            		<xsl:value-of select="$exit"/><xsl:value-of select="$div"/>
					<xsl:value-of select="$ran"/><xsl:value-of select="$div"/>
					<xsl:value-of select="$begin/name"/><xsl:value-of select="$div"/>
					<xsl:value-of select="$end/name"/><xsl:value-of select="$div"/>
					<xsl:value-of select="name"/><xsl:value-of select="$div"/>
					<xsl:value-of select="statistics/statistic[matches(name, 'total')]/value"/><xsl:value-of select="$div"/>
					<xsl:value-of select="statistics/statistic[matches(name, 'unique')]/value"/>
<xsl:text>
</xsl:text>	
                            	</xsl:for-each>
                            	</xsl:if>
                       	    	<xsl:if test="$ca='0'">
                    		<xsl:for-each select="$user">
                    			<xsl:sort select="statistics/statistic[matches(name, 'count')]/value" data-type="number" order="descending"/>
					<xsl:value-of select="$host"/><xsl:value-of select="$div"/>
                            		<xsl:value-of select="$exit"/><xsl:value-of select="$div"/>
					<xsl:value-of select="$ran"/><xsl:value-of select="$div"/>
					<xsl:value-of select="$begin/name"/><xsl:value-of select="$div"/>
					<xsl:value-of select="$end/name"/><xsl:value-of select="$div"/>
					<xsl:value-of select="name"/><xsl:value-of select="$div"/>
					<xsl:value-of select="statistics/statistic[matches(name, 'count')]/value"/>
<xsl:text>
</xsl:text>	
                            	</xsl:for-each>
                            	</xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
<xsl:text>
</xsl:text>	
                            </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <!-- missing data -->
                        <xsl:otherwise>
                    		<xsl:text>missing</xsl:text><xsl:value-of select="$div"/>
<xsl:text>
</xsl:text>	
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- resource is exempt -->
                <xsl:otherwise>
		    <xsl:value-of select="$host"/><xsl:value-of select="$div"/>
                    <xsl:text>n/a</xsl:text><xsl:value-of select="$div"/>
<xsl:text>
</xsl:text>	
                </xsl:otherwise>
            </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
