<?xml version="1.0" encoding="UTF-8"?>

<!-- Author: Kate Ericson, TeraGrid -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml">

<xsl:template name="tg-menu">
  <form method="post" action="xslt.jsp">
	<table cellpadding="2">
	<tr><td><p>KIT:<br/>
                <select name="xmlFile">
                  <option value="ctssv4-core.xml">core</option>
		  <option value="ant">ant</option>
         	  <option value="blas">blas</option>
 		</select></p>
        </td>
        <td> <p>RESOURCE:<br/>
              <select name="resourceID">
                  <option value="teragrid-login"><xsl:value-of select="'TeraGrid'"/></option>
                <xsl:for-each select="/combo/resourceConfig/resources/resource[name]">
                  <xsl:sort select="." />
                  <xsl:variable name="name" select="name" />
                  <option value="{$name}"><xsl:value-of select="name"/></option>
                </xsl:for-each>
                  <option value="ANL-login"><xsl:value-of select="'ANL'"/></option>
                  <option value="Indiana"><xsl:value-of select="'Indiana'"/></option>
                  <option value="NCAR"><xsl:value-of select="'NCAR'"/></option>
                  <option value="NCSA"><xsl:value-of select="'NCSA'"/></option>
                  <option value="ORNL"><xsl:value-of select="'ORNL'"/></option>
                  <option value="PSC"><xsl:value-of select="'PSC'"/></option>
                  <option value="Purdue-login"><xsl:value-of select="'Purdue'"/></option>
                  <option value="SDSC"><xsl:value-of select="'SDSC'"/></option>
                  <option value="TACC"><xsl:value-of select="'TACC'"/></option>
              </select>
            </p>
	</td>
              <td><input type="hidden" name="suiteName" value="ctss-v3"/>
                <input type="hidden" name="xsl" value="ctssv4.xsl"/>
              <input type="submit" name="Submit" value="Submit"/></td>
          </tr></table>
	</form>
</xsl:template>

</xsl:stylesheet>
