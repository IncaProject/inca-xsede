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

  <h1>Reports</h1>
                        <table cellpadding="6" class="subheader" border="0">
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/jsp/summary.jsp">Past week: ave pass rate by resource/suite </a></td>
                            <td class="clear">Bar graphs of the average test series pass rate by resource and by suite for the past week as compared to the week before last. </td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/jsp/status.jsp?xsl=seriesSummary.xsl&xml=weekSummary.xml&queryNames=incaQueryStatus">Past 10 weeks: series error summary </a> </td>
                            <td class="clear">A summary of test series errors by time period and the change between the total number of errors in the most recent period and the total number of errors in the period.</td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/jsp/summaryHistory.jsp?filterResource=true">Resource ave pass history </a> </td>
                            <td class="clear">XY plot of the average series pass rate over time by resource. </td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/jsp/summaryHistory.jsp?filterSuite=true">Suite ave pass history </a></td>
                            <td class="clear">XY plot of the average series pass rate over time by test suite. </td>
                          </tr>
                          <tr valign="top">
                            <td class="clear"><a href="http://cuzco.sdsc.edu:8085/cgi-bin/lead.cgi">LEAD Testbed</a> </td>
                            <td class="clear">Detailed tabular summary of pass/fail results by resource (column) and software category/package (row) for the services that <a href="http://www.teragridforum.org/mediawiki/index.php?title=LEAD">LEAD</a> uses. </td>
                          </tr>
                        </table>
                        <p><br/>
                          <h1>Coordinated TeraGrid Software and Services Version 4 (CTSSv4)</h1>                        </p>
                        <table cellpadding="6" class="subheader" border="0"><tr valign="top">
        <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/html/ctssv4.html">expanded detailed table</a> </td>
        <td class="clear">Detailed tabular summary  of kit pass/fail results by resource (column) and software category/package (row). </td>
      </tr>
      <tr valign="top">
        <td class="clear"><a href="http://sapa.sdsc.edu:8080/inca/html/ctssv4-map.html">google map</a> </td>
        <td class="clear">Google map summary of pass/fail results by resource. Click on resource markers for pass/fail detail links. </td>
      </tr></table>
                        <br/>
                        <h1><br>
                        Cross-Site and CTSSv3 tests not in CTSSv4 (CTSSv3 and Cross-Site) </h1>
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
                          </tr></table>
                        <br/>
                          <h1><br>
                          Other Test Suites </h1>
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
                        </table>


  



<c:if test="${empty param.noFooter}">
  <inca:executeXslTemplate name="footer"/>
</c:if>
</body>
</html>
