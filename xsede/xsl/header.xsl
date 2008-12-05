<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- header.xsl:  Prints HTML page header.                                -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml">
  <xsl:param name="url" />

  <xsl:template name="header">
    <head>
      <link href="{concat($url, '/css/nav.css')}" rel="stylesheet" type="text/css"/>
      <link href="{concat($url, '/css/inca.css')}" rel="stylesheet" type="text/css"/>
    </head>

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
                      CTSSv3 and Cross-Site
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
                    <xsl:variable name="other" select="'&amp;resourceIds=repo,real-time,gig,teragrid,teragrid-gridnodes,sdsc-ia64,ALL-RM&amp;suiteNames=tg-mds,real-time,gig,security,usage,sdsc-ops,check-reporter-managers'"/>
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
                    <a href="{concat($url, '/jsp/summaryHistory.jsp?filterResource=true')}">
                      Resource avg pass history
                    </a>
                  </li>
                  <li>
                    <a href="{concat($url, '/jsp/summaryHistory.jsp?filterSuite=true')}">
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
                      CTSSv3 and Cross-Site
                    </a>
                    <ul>
                      <li>
                        <a href="{concat($url, '/html/ctssv3-expanded.html')}">
                          expanded detailed table
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/html/summary.html')}">
                          summary by resource
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
                    <a href="{concat($url, '/jsp/status.jsp?xsl=job.xsl&amp;resourceIds=teragrid-gridnodes&amp;suiteNames=usage')}">
                      Other Test Suites
                    </a>
                    <ul>
                      <li>
                        <a href="{concat($url, '/jsp/status.jsp?xsl=job.xsl&amp;resourceIds=teragrid-gridnodes&amp;suiteNames=usage')}">
                          grid job usage
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/jsp/status.jsp?xml=tg-mds.xml&amp;resourceIds=repo&amp;suiteNames=tg-mds')}">
                          tg wide mds
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/jsp/status.jsp?xsl=swStack.xsl&amp;resourceIds=real-time&amp;suiteNames=real-time&amp;xml=real-time.xml')}">
                          real-time monitoring testbed
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/jsp/status.jsp?xsl=swStack.xsl&amp;resourceIds=gig&amp;suiteNames=gig&amp;xml=gig.xml')}">
                          gig
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/jsp/status.jsp?xsl=default.xsl&amp;resourceIds=teragrid&amp;suiteNames=security')}">
                          security
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/jsp/status.jsp?xsl=default.xsl&amp;resourceIds=sdsc-ia64&amp;suiteNames=sdsc-ops')}">
                          sdsc operations
                        </a>
                      </li>
                      <li>
                        <a href="{concat($url, '/jsp/status.jsp?xsl=default.xsl&amp;resourceIds=ALL-RM&amp;suiteNames=check-reporter-managers')}">
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
