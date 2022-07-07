<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- header.xsl:  Prints HTML page header.                                -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
		xmlns:sdf="java.text.SimpleDateFormat"
		xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xsl:param name="url" />

  <xsl:template name="header">
    <xsl:variable name="httpurl" select="replace(replace($url, 'https', 'http'), '8443', '8080')"/>
    <table width="100%" class="subheader">
      <tr>
        <td><b><a href="http://inca.xsede.org/">
          <img src="{concat($url, '/img/xsede-header.jpg')}" alt="XSEDE Inca Status Pages" border="0"/>
        </a></b></td>
        <td>
          <div id="menu">
            <ul>
              <li><h2>Info</h2>
                <ul>
                  <li>
                    <a href="{concat($url, '/jsp/index.jsp')}">
                      Description of Status Pages
                    </a>
                  </li>
                  <li>
                    <a href="{concat($url, '/jsp/config.jsp')}">
                      List Running Tests
                    </a>
                  </li>
                  <li>
                    <a href="{concat($url, '/jsp/seriesConfig.jsp')}">
                      List Running Tests - Detail
                    </a>
                  </li>
                </ul>
              </li>
            </ul>
<!--
            <ul>
              <li><h2>Reports</h2>
                <ul>
                  <li>
                    <xsl:variable name="three-days" select="xs:dayTimeDuration('P3D')"/>
                    <xsl:variable name="now" select="xs:dateTime(current-date())"/>
                    <xsl:variable name="minus" select="$now - $three-days"/>
                    <xsl:variable name="start">
                      <xsl:variable name="dateformat" select="sdf:new('MMddyy')"/>
                      <xsl:value-of select="sdf:format($dateformat, $minus)"/>
                    </xsl:variable>
                    <a href="{concat($url, '/jsp/report.jsp?xml=infoPerf.xml&amp;startDate=', $start)}">
                      Past 3 days: information services statistics
                    </a>
                  </li>
                  <li>
                    <a href="{concat($url, '/jsp/summary.jsp')}">
                      Past week: avg pass rate by resource/suite
                    </a>
                  </li>
                  <li>
                    <a href="{concat($url, '/jsp/status.jsp?xsl=seriesSummary.xsl&amp;xml=weekSummary.xml&amp;queryNames=incaQueryStatus')}">
                      Past 12 weeks: series error summary
                    </a>
                  </li>
                  <li>
                    <a href="{concat($url, '/html/reports/summaryHistoryByResource/')}">
                      Resource avg pass history
                    </a>
                  </li>
                  <li>
                    <a href="{concat($url, '/html/reports/summaryHistoryBySuite/')}">
                      Suite avg pass history
                    </a>
                  </li>
                </ul>
              </li>
            </ul>
-->
            <ul>
              <li><h2>Current Data</h2>
                <ul>
                  <li>
                    <a href="{concat($url, '/view/status/sp')}">
                      SP Service and Software tests
                    </a>
                    <ul>
                      <li>
                        <a href="{concat($url, '/view/status/sp')}">
                          expanded detailed table
                        </a>
                      </li>
                      <li>
                        <a href="{concat($httpurl, '/view/map/sp')}">
                          google map
                        </a>
                      </li>
                    </ul>
                  </li>
                  <li>
                    <a href="{concat($url, '/view/status/sp-cross-site')}">
                      SP Cross-Site Service Tests
                    </a>
                  </li>
                  <li>
                    <a href="{concat($url, '/view/status/central')}">
                      XSEDE Central Services Tests
                    </a>
                  </li>
                  <li>
                    <a href="{concat($url, '/view/status/inca')}">
                      Inca Status
                    </a>
                  </li>
                  <li>
                    <a href="{concat($url, '/view/status/gateway-extras')}">
                      Gateway Tests
                    </a>
                  </li>
                </ul>
              </li>
            </ul>
          </div>
        </td></tr></table>
  </xsl:template>

</xsl:stylesheet>
