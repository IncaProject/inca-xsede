<?xml version="1.0" encoding="UTF-8"?>

<!-- Author: Kate Ericson, TeraGrid -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml">

<xsl:template name="tg-menu">
  <form method="get" action="xslt.jsp">
	<table cellpadding="2">
	<tr><td><p>KIT:<br/>
                <select name="xmlFile">
                  <option value="core.xml">- Select One -</option>
                  <option value="core.xml">Core Integration</option>
                  <option value="login.xml">Remote Login</option>
                  <option value="remote-compute.xml">Remote Compute</option>
                  <option value="data-move.xml">Data Movement</option>
                  <option value="data-manage.xml">Data Management</option>
                  <option value="wan-fs.xml">Wide Area Parallel File Systems</option>
                  <option value="apps.xml">Application Development &amp; Runtime Support</option>
                  <option value="sws.xml">Science Workflow Support</option>
                  <option value="parallel.xml">Parallel Application Support</option>
                  <option value="dist-para-apps.xml">Distributed Parallel Application Support</option>
 		</select></p>
        </td>
        <td> <p>RESOURCE:<br/>
              <select name="resourceID">
                  <option value="teragrid-login">- Select One -</option>
                  <option value="teragrid-login">TeraGrid</option>
                <xsl:for-each select="/combo/resourceConfig/resources/resource[name]">
                  <xsl:sort select="." />
                  <xsl:variable name="name" select="name" />
                  <option value="{$name}"><xsl:value-of select="name"/></option>
                </xsl:for-each>
                  <option value="ANL-login">ANL</option>
                  <option value="Indiana">Indiana</option>
                  <option value="NCAR">NCAR</option>
                  <option value="NCSA">NCSA</option>
                  <option value="ORNL">ORNL</option>
                  <option value="PSC">PSC</option>
                  <option value="Purdue-login">Purdue</option>
                  <option value="SDSC">SDSC</option>
                  <option value="TACC">TACC</option>
              </select>
            </p>
	</td>
              <td><input type="hidden" name="suiteName" value="ctss-v3"/>
                <input type="hidden" name="xsl" value="ctssv4.xsl"/>
                <input type="hidden" name="markOld" value=""/>
              <input type="submit" name="Submit" value="Submit"/></td>
          </tr></table>
	</form>
</xsl:template>

</xsl:stylesheet>
