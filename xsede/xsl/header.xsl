<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- header.xsl:  Prints HTML page header.                                -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml">
  <xsl:param name="url" />

  <xsl:template name="header">
    <xsl:variable name="map" select="'http://sapa.sdsc.edu:8080/inca'"/>
    <table width="100%" class="subheader">
      <tr>
        <td><b><a href="http://www.teragrid.org/">
          <img src="{concat($url, '/img/tgheader.gif')}" alt="TeraGrid Inca Status Pages" border="0"/>
        </a></b></td>
        <td>
          <div id="menu">
            <ul>
              <li><h2>Info</h2>
                <ul>
                  <li>
                    <a href="{$url}">
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
                  <li>
                    <a href="http://news.teragrid.org/">
                      User/System News
                    </a>
                  </li>
                </ul>
              </li>
            </ul>
            <ul>
              <li><h2>Query</h2>
                <ul>
                  <li>
                    <a href="{concat($url, '/html/ctssv4-graph.html')}">
                      CTSSv4
                    </a>
		    <ul>
                      <li>
                        <a href="{concat($url, '/html/ctssv4-graph.html')}">
                          Create historical graph
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/html/ctssv4-query.html')}">
                          Create stored query
                        </a>
                      </li>
		    </ul>
                  </li>
                  <li>
                    <a href="{concat($url, '/html/ctssv3-graph.html')}">
                      Cross-Site
                    </a>
		    <ul>
                      <li>
                        <a href="{concat($url, '/html/ctssv3-graph.html')}">
                          Create historical graph
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/html/ctssv3-query.html')}">
                          Create stored query
                        </a>
                      </li>
		    </ul>
                  </li>
                  <li>
                    <xsl:variable name="other" select="'&amp;resourceIds=repo,real-time,gig,sapa,teragrid-usage,ALL-RM&amp;suiteNames=tg-iis,real-time,gig,security,usage,check-reporter-managers'"/>
                    <a href="{concat($url, '/jsp/status.jsp?xsl=graph.xsl', $other)}">
                      Other test suites
                    </a>
		    <ul>
                      <li>
                        <a href="{concat($url, '/jsp/status.jsp?xsl=graph.xsl', $other)}">
                          Create historical graph
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/jsp/status.jsp?xsl=create-query.xsl', $other)}">
                          Create stored query
                        </a>
                      </li>
		    </ul>
                  </li>
                </ul>
              </li>
            </ul>
            <ul>
              <li><h2>Reports</h2>
                <ul>
                  <li>
                    <a href="http://cuzco.sdsc.edu:8085/cgi-bin/lead.cgi">
                      LEAD Testbed
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
            <ul>
              <li><h2>Current Data</h2>
                <ul>
                  <li>
                    <a href="{concat($url, '/html/ctssv4.html')}">
                      CTSSv4
                    </a>
                    <ul>
                      <li>
                        <a href="{concat($url, '/html/ctssv4.html')}">
                          expanded detailed table
                        </a>
                      </li>
                      <li>
                        <a href="{concat($map, '/html/ctssv4-map.html')}">
                          google map
                        </a>
                      </li>
                    </ul>
                  </li>
                  <li>
                    <a href="{concat($url, '/html/ctssv3-expanded.html')}">
                      Cross-Site
                    </a>
                    <ul>
                      <li>
                        <a href="{concat($url, '/html/ctssv3-expanded.html')}">
                          expanded detailed table
                        </a>
                      </li>
                      <li>
                        <a href="{concat($map, '/html/ctssv3-map.html')}">
                          google map
                        </a>
                      </li>
                    </ul>
                  </li>
                  <li>
                    <a href="{concat($url, '/jsp/status.jsp?xsl=job.xsl&amp;resourceIds=teragrid-usage&amp;suiteNames=usage')}">
                      Other Test Suites
                    </a>
                    <ul>
                      <li>
                        <a href="{concat($url, '/jsp/status.jsp?xsl=job.xsl&amp;resourceIds=teragrid-usage&amp;suiteNames=usage')}">
                          grid job usage
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/jsp/status.jsp?xml=tg-iis.xml&amp;resourceIds=repo&amp;suiteNames=tg-iis')}">
                          tg wide information services
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/jsp/status.jsp?xsl=swStack.xsl&amp;resourceIds=real-time&amp;suiteNames=real-time&amp;xml=real-time.xml')}">
                          real-time monitoring testbed
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/HTML/kit-status-v1/gig/gig')}">
                          grid infrastructure group (gig)
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/HTML/kit-status-v1/tgup/sapa')}">
                          teragrid user portal (tgup)
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/HTML/kit-status-v1/security/sapa')}">
                          security
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/HTML/kit-status-v1/check-reporter-managers/ALL-RM')}">
                          inca self check
                        </a>
                      </li>
                    </ul>
                  </li>
                </ul>
              </li>
            </ul>
          </div>
        </td></tr></table>
  </xsl:template>

</xsl:stylesheet>
