<?xml version="1.0" encoding="UTF-8"?>

<!-- Author: Kate Ericson, TeraGrid -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml">

<xsl:template name="tg-menu">
  <form method="get" action="xslt.jsp">
	<table cellpadding="2">
	<tr><td><p>KIT:<br/>
                <select name="suiteName" onchange="this.form.xmlFile.value = this.options[this.selectedIndex].value + '.xml';">
                  <option value="core.teragrid.org-4.0.0">- Select One -</option>
                  <option value="core.teragrid.org-4.0.0">Core Integration</option>
                  <option value="login.teragrid.org-4.0.0">Remote Login</option>
                  <option value="remote-compute.teragrid.org-4.0.0">Remote Compute</option>
                  <option value="data-movement.teragrid.org-4.0.0">Data Movement</option>
                  <option value="data-management.teragrid.org-4.0.0">Data Management</option>
                  <option value="wan-parallel-app.teragrid.org-4.0.0">Wide Area Parallel File Systems</option>
                  <option value="app-support.teragrid.org-4.0.0">Application Development &amp; Runtime Support</option>
                  <option value="workflow.teragrid.org-4.0.0">Science Workflow Support</option>
                  <option value="parallel-app.teragrid.org-4.0.0">Parallel Application Support</option>
                  <option value="dist-para-apps">Distributed Parallel Application Support</option>
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
              <td>
		<input type="hidden" name="xmlFile" value="core.teragrid.org-4.0.0.xml"/>
                <input type="hidden" name="xsl" value="ctssv4.xsl"/>
                <input type="hidden" name="markOld" value=""/>
              	<input type="submit" name="Submit" value="Submit"/></td>
          </tr></table>
	</form>
</xsl:template>

</xsl:stylesheet>
