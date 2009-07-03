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
        document.form.xml.value = document.form.suiteNames.value + '.xml';
        if (document.form.suiteNames.value.match(/,/)){
          document.form.xml.value = "core.teragrid.org-4.0.0.xml,core.teragrid.org-4.2.0.xml,data-management.teragrid.org-4.0.0.xml,data-movement.teragrid.org-4.1.2.xml,data-movement-clients.teragrid.org-4.2.0.xml,data-movement-servers.teragrid.org-4.2.0.xml,remote-compute.teragrid.org-4.0.2.xml,remote-compute.teragrid.org-4.2.0.xml,login.teragrid.org-4.0.0.xml,login.teragrid.org-4.0.2.xml,app-support.teragrid.org-4.0.0.xml,app-support.teragrid.org-4.0.1.xml,app-support.teragrid.org-4.0.2.xml,app-support.teragrid.org-4.0.3.xml,app-support.teragrid.org-4.2.0.xml,parallel-app.teragrid.org-4.0.0.xml,parallel-app.teragrid.org-4.0.1.xml,workflow.teragrid.org-4.0.0.xml,workflow.teragrid.org-4.2.0.xml,vtss.teragrid.org-3.0.0.xml,wan-gpfs.teragrid.org-4.0.0.xml,wan-lustre.teragrid.org-4.0.0.xml,science-gateway.teragrid.org-4.1.0.xml,science-gateway.teragrid.org-4.2.0.xml,coscheduling.teragrid.org-1.0.0.xml,metascheduling.teragrid.org-4.2.0.xml";
        }
        if (document.form.resource.value == "select"){
          document.form.resourceIds.value = document.form.suiteNames.value;
        }else{
          document.form.resourceIds.value = document.form.resource.value;
        }
      }
    </script>
    <form method="get" action="../jsp/status.jsp" name="form">
      <table cellpadding="2">
        <tr><td><p>KIT:<br/>
          <select name="suiteNames">
            <option value="core.teragrid.org-4.0.0,core.teragrid.org-4.2.0,data-management.teragrid.org-4.0.0,data-movement.teragrid.org-4.1.2,data-movement-clients.teragrid.org-4.2.0,data-movement-servers.teragrid.org-4.2.0,remote-compute.teragrid.org-4.0.2,remote-compute.teragrid.org-4.2.0,login.teragrid.org-4.0.0,login.teragrid.org-4.0.2,app-support.teragrid.org-4.0.0,app-support.teragrid.org-4.0.1,app-support.teragrid.org-4.0.2,app-support.teragrid.org-4.0.3,app-support.teragrid.org-4.2.0,parallel-app.teragrid.org-4.0.0,parallel-app.teragrid.org-4.0.1,workflow.teragrid.org-4.0.0,workflow.teragrid.org-4.2.0,vtss.teragrid.org-3.0.0,wan-gpfs.teragrid.org-4.0.0,wan-lustre.teragrid.org-4.0.0,science-gateway.teragrid.org-4.1.0,science-gateway.teragrid.org-4.2.0,coscheduling.teragrid.org-1.0.0,metascheduling.teragrid.org-4.2.0">- Select One -</option>
            <option value="core.teragrid.org-4.0.0,core.teragrid.org-4.2.0,data-management.teragrid.org-4.0.0,data-movement.teragrid.org-4.1.2,data-movement-clients.teragrid.org-4.2.0,data-movement-servers.teragrid.org-4.2.0,remote-compute.teragrid.org-4.0.2,remote-compute.teragrid.org-4.2.0,login.teragrid.org-4.0.0,login.teragrid.org-4.0.2,app-support.teragrid.org-4.0.0,app-support.teragrid.org-4.0.1,app-support.teragrid.org-4.0.2,app-support.teragrid.org-4.0.3,app-support.teragrid.org-4.2.0,parallel-app.teragrid.org-4.0.0,parallel-app.teragrid.org-4.0.1,workflow.teragrid.org-4.0.0,workflow.teragrid.org-4.2.0,vtss.teragrid.org-3.0.0,wan-gpfs.teragrid.org-4.0.0,wan-lustre.teragrid.org-4.0.0,science-gateway.teragrid.org-4.1.0,science-gateway.teragrid.org-4.2.0,coscheduling.teragrid.org-1.0.0,metascheduling.teragrid.org-4.2.0">ALL KITS</option>
            <option value="app-support.teragrid.org-4.0.0">Application Development &amp; Runtime Support 4.0.0</option>
            <option value="app-support.teragrid.org-4.0.1">Application Development &amp; Runtime Support 4.0.1</option>
            <option value="app-support.teragrid.org-4.0.2">Application Development &amp; Runtime Support 4.0.2</option>
            <option value="app-support.teragrid.org-4.0.3">Application Development &amp; Runtime Support 4.0.3</option>
            <option value="app-support.teragrid.org-4.2.0">Application Development &amp; Runtime Support 4.2.0</option>
            <option value="core.teragrid.org-4.0.0">Core Integration 4.0.0</option>
            <option value="core.teragrid.org-4.2.0">Core Integration 4.2.0</option>
            <option value="coscheduling.teragrid.org-1.0.0">Co-Scheduling 1.0.0</option>
            <option value="data-management.teragrid.org-4.0.0">Data Management 4.0.0</option>
            <option value="data-movement.teragrid.org-4.1.2">Data Movement 4.1.2</option>
            <option value="data-movement-clients.teragrid.org-4.2.0">Data Movement Clients 4.2.0</option>
            <option value="data-movement-servers.teragrid.org-4.2.0">Data Movement Servers 4.2.0</option>
            <option value="metascheduling.teragrid.org-4.2.0">Metascheduling 4.2.0</option>
            <option value="parallel-app.teragrid.org-4.0.0">Parallel Application Support 4.0.0</option>
            <option value="parallel-app.teragrid.org-4.0.1">Parallel Application Support 4.0.1</option>
            <option value="remote-compute.teragrid.org-4.0.2">Remote Compute 4.0.2</option>
            <option value="remote-compute.teragrid.org-4.2.0">Remote Compute 4.2.0</option>
            <option value="login.teragrid.org-4.0.0">Remote Login 4.0.0</option>
            <option value="login.teragrid.org-4.0.2">Remote Login 4.0.2</option>
            <option value="science-gateway.teragrid.org-4.1.0">Science Gateway 4.1.0</option>
            <option value="science-gateway.teragrid.org-4.2.0">Science Gateway 4.2.0</option>
            <option value="workflow.teragrid.org-4.0.0">Science Workflow Support 4.0.0</option>
            <option value="workflow.teragrid.org-4.2.0">Science Workflow Support 4.2.0</option>
            <option value="vtss.teragrid.org-3.0.0">Vizualization Support 3.0.0</option>
            <option value="wan-gpfs.teragrid.org-4.0.0">WAN GPFS 4.0.0</option>
            <option value="wan-lustre.teragrid.org-4.0.0">WAN Lustre 4.0.0</option>
          </select></p>
        </td>
          <td> <p>RESOURCE:<br/>
            <select name="resource">
              <option value="select">- Select One -</option>
              <option value="teragrid-login">TeraGrid</option>
              <xsl:for-each select="/combo/resources/resource[name]">
                <xsl:sort select="." />
                <xsl:variable name="name" select="name" />
                <option value="{$name}"><xsl:value-of select="name"/></option>
              </xsl:for-each>
              <option value="ANL-login">ANL</option>
              <option value="Indiana">Indiana</option>
              <option value="LONI">LONI</option>
              <option value="NCAR">NCAR</option>
              <option value="NCSA">NCSA</option>
              <option value="NICS">NICS</option>
              <option value="ORNL">ORNL</option>
              <option value="PSC">PSC</option>
              <option value="Purdue-login">Purdue</option>
              <option value="SDSC">SDSC</option>
              <option value="TACC">TACC</option>
            </select>
          </p>
          </td>
          <td>
            <input type="hidden" name="xml" value="core.teragrid.org-4.0.0.xml"/>
            <input type="hidden" name="xsl" value="swStack.xsl"/>
            <input type="hidden" name="noCategoryHeaders" value=""/>
            <input type="hidden" name="resourceIds" value=""/>
            <input type="submit" name="Submit" value="Submit" onclick="setResourceAndXml()"/></td>
        </tr></table>
    </form>
  </xsl:template>

</xsl:stylesheet>
