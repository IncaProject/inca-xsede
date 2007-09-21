<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- tg-menu.xsl:  Drop down menus to select CTSSv4 kits and resources.   -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml">

  <xsl:template name="tg-menu">
    <script type="text/javascript">
      function setResourceAndXml(){
      document.form.xmlFile.value = document.form.suiteName.value + '.xml';
      if (document.form.resource.value == "select"){
      document.form.resourceID.value = document.form.suiteName.value;
      }else{
      document.form.resourceID.value = document.form.resource.value;
      }
      }
    </script>
    <form method="get" action="xslt.jsp" name="form">
      <table cellpadding="2">
        <tr><td><p>KIT:<br/>
          <select name="suiteName">
            <option value="core.teragrid.org-4.0.0">- Select One -</option>
            <option value="core.teragrid.org-4.0.0">Core Integration</option>
            <option value="data-management.teragrid.org-4.0.0">Data Management</option>
            <option value="data-movement.teragrid.org-4.0.0">Data Movement</option>
            <option value="remote-compute.teragrid.org-3.0.0">Remote Compute</option>
            <option value="login.teragrid.org-4.0.0">Remote Login</option>
            <option value="app-support.teragrid.org-4.0.0">Application Development &amp; Runtime Support</option>
            <option value="parallel-app.teragrid.org-4.0.0">Parallel Application Support</option>
            <option value="workflow.teragrid.org-4.0.0">Science Workflow Support</option>
            <option value="vtss.teragrid.org-3.0.0">Vizualization Support</option>
            <option value="wanfs.teragrid.org-4.0.0">Wide Area File System</option>
          </select></p>
        </td>
          <td> <p>RESOURCE:<br/>
            <select name="resource">
              <option value="select">- Select One -</option>
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
            <input type="hidden" name="resourceID" value=""/>
            <input type="hidden" name="xsl" value="ctssv4.xsl"/>
            <input type="hidden" name="markOld" value=""/>
            <input type="submit" name="Submit" value="Submit" onclick="setResourceAndXml()"/></td>
        </tr></table>
    </form>
  </xsl:template>

</xsl:stylesheet>
