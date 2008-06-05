<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="inca" tagdir="/WEB-INF/tags/inca" %>


<html>

<head> 
  <inca:getUrl var="url" />
  <c:if test="${empty param.noHeader}">
    <inca:executeXslTemplate name="header" url="${url}"/>
  </c:if>
</head> 

<body>
<table xmlns:sdf="java.text.SimpleDateFormat" xmlns:date="java.util.Date" xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes" width="100%" border="0"><tr align="left"><td><h1 class="body">Description of Status Pages </h1></td></tr></table>

                        <p>These status pages show TeraGrid's health as monitored using <a href="http://inca.sdsc.edu/">Inca</a>.  Pages are also linked from the drop down menu at the top right of the page. </p><br/>
                        <strong class="ptext">Coordinated TeraGrid Software and Services Version 4 (CTSSv4)</strong>
                        <table cellpadding="6" class="subheader" border="0"><tr valign="top">
        <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/html/ctssv4.html">expanded detailed table</a> </td>
        <td class="clear">Detailed tabular summary  of kit pass/fail results by resource (column) and software category/package (row). </td>
      </tr>
      <tr valign="top">
        <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/html/ctssv4-map.html">google map</a> </td>
        <td class="clear">Google map summary of pass/fail results by resource. Click on resource markers for pass/fail detail links. </td>
      </tr>
      <tr valign="top">
        <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/html/ctssv4-graph.html">graph</a></td>
        <td class="clear">Form to select tests from CTSSv4 to generate historical graphs. </td>
      </tr></table>
                        <br/>
                        <strong class="ptext"><br>
                        Cross-Site and CTSSv3 tests not in CTSSv4 (CTSSv3 and Cross-Site) </strong>
                        <table cellpadding="6" class="subheader" border="0">
                         
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/html/ctssv3-expanded.html">expanded detailed table</a> </td>
                            <td class="clear">Detailed tabular summary of pass/fail results by resource (column) and software category/package (row). </td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/html/summary.html">summary by resource </a></td>
                            <td class="clear">Summary of failures by resource with links to test details. </td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/html/ctssv3-map.html">google map</a> </td>
                            <td class="clear">Google map summary of pass/fail results by resource. Click on resource markers for pass/fail detail links. </td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/html/ctssv3-graph.html">graph</a></td>
                            <td class="clear">Form to select tests from CTSSv3 and Cross-Site to generate historical graphs. </td>
                          </tr></table><br/>
                          <strong class="ptext"><br>
                          Other Test Suites </strong>
                          <table cellpadding="6" class="subheader" border="0">
                          
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/jsp/status.jsp?xsl=job.xsl&resourceIds=teragrid-gridnodes&suiteNames=usage">grid job usage </a></td>
                            <td class="clear">Prints table of DN stats and table of CA stats based on  results from the usage test suite. </td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/jsp/status.jsp?xml=tg-mds.xml&resourceIds=repo&suiteNames=tg-mds">tg wide information services </a></td>
                            <td class="clear">Detailed tabular summary of pass/fail results by resource (column) and tg wide service (row). </td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/jsp/status.jsp?xsl=swStack.xsl&resourceIds=real-time&suiteNames=real-time&xml=real-time.xml">real-time monitoring testbed</a> </td>
                            <td class="clear">Detailed tabular summary of pass/fail results for tests running at high frequency.</td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/jsp/status.jsp?xsl=default.xsl&resourceIds=teragrid&suiteNames=security">security</a></td>
                            <td class="clear">Detailed tabular summary of pass/fail results for security related tests. </td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/jsp/status.jsp?xsl=default.xsl&resourceIds=sdsc-ia64&suiteNames=sdsc-ops">sdsc operations </a></td>
                            <td class="clear">Detailed tabular summary of pass/fail results for SDSC operations related tests. </td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/jsp/status.jsp?xsl=default.xsl&resourceIds=ALL-RM&suiteNames=check-reporter-managers">inca self check </a></td>
                            <td class="clear">Detailed tabular summary of pass/fail results for inca reporter manager client related tests. </td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/jsp/status.jsp?xsl=graph.xsl&resourceIds=repo,real-time,teragrid,teragrid-gridnodes,sdsc-ia64,ALL-RM&suiteNames=tg-mds,real-time,security,usage,sdsc-ops,check-reporter-managers">graph</a></td>
                            <td class="clear">Form to select  grid job, tg wide info services, real-time, security, sdsc-ops or inca self tests to generate historical graphs. </td>
                          </tr>
                        </table>

<c:if test="${empty param.noFooter}">
  <inca:executeXslTemplate name="footer"/>
</c:if>
</body>
</html>
