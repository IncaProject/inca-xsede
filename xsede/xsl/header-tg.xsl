<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- header.xsl:  Prints HTML page header.                                -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml">

  <xsl:template name="header">
    <head>
      <link href="css/nav.css" rel="stylesheet" type="text/css"/>
      <link href="css/inca.css" rel="stylesheet" type="text/css"/>
    </head>

    <table width="100%" class="subheader">
      <tr>
        <td><b><a href="http://www.teragrid.org/">
          <img src="img/tgheader.gif" alt="TeraGrid Inca Status Pages" border="0"/>
        </a></b></td>
        <td>
          <div id="menu">
            <ul>
              <li><h2>Info</h2>
                <ul>
                  <li>
                    <a href="config.jsp?xsl=config.xsl">
                      List Running Tests
                    </a>
                  </li>
                </ul>
              </li>
            </ul>
            <ul>
              <li><h2>Historical Data</h2>
                <ul>
                  <li>
                    <a href="ctssv4-graph.html">
                      CTSSv4 Graph
                    </a>
                  </li>
                  <li>
                    <a href="ctssv3-graph.html">
                      CTSSv3 and Cross-Site Graph
                    </a>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=graph.xsl&amp;resourceID=repo&amp;suiteName=tg-mds,globus-mds-auth">
                      MDS Graph
                    </a>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=graph.xsl&amp;resourceID=SDSC,teragrid,teragrid-gridnodes&amp;suiteName=real-time,security,usage&amp;xmlFile=jobs.xml">
                      Other Test Suites Graph
                    </a>
                  </li>
                </ul>
              </li>
            </ul>
            <ul>
              <li><h2>Current Data</h2>
                <ul>
                  <li>
                    <a href="ctssv4.html">
                      CTSSv4
                    </a>
                    <ul>
                      <li>
                        <a href="ctssv4.html">
                          expanded detailed table
                        </a>
                      </li>
                      <li>
                        <a href="ctssv4-map.html">
                          google map
                        </a>
                      </li>
                    </ul>
                  </li>
                  <li>
                    <a href="ctssv3-expanded.html">
                      CTSSv3 and Cross-Site
                    </a>
                    <ul>
                      <li>
                        <a href="ctssv3-expanded.html">
                          expanded detailed table
                        </a>
                      </li>
                      <li>
                        <a href="summary.html">
                          summary by resource
                        </a>
                      </li>
                      <li>
                        <a href="ctssv3-map.html">
                          google map
                        </a>
                      </li>
                    </ul>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=tg-mds.xsl&amp;xmlFile=tg-mds.xml&amp;resourceID=repo&amp;suiteName=tg-mds&amp;markOld=1">
                      MDS
                    </a>
                    <ul>
                      <li>
                        <a href="xslt.jsp?xsl=tg-mds.xsl&amp;xmlFile=tg-mds.xml&amp;resourceID=repo&amp;suiteName=tg-mds&amp;markOld=1">
                          tg wide information services
                        </a>
                      </li>
                      <li>
                        <a href="xslt.jsp?xsl=default.xsl&amp;resourceID=repo&amp;suiteName=globus-mds-auth&amp;markOld=1">
                          globus-mds-auth service
                        </a>
                      </li>
                    </ul>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=job.xsl&amp;resourceID=teragrid-gridnodes&amp;suiteName=usage&amp;xmlFile=jobs.xml">
                      Other Test Suites
                    </a>
                    <ul>
                      <li>
                        <a href="xslt.jsp?xsl=job.xsl&amp;resourceID=teragrid-gridnodes&amp;suiteName=usage&amp;xmlFile=jobs.xml">
                          grid job usage
                        </a>
                      </li>
                      <li>
                        <a href="xslt.jsp?xsl=swStack.xsl&amp;resourceID=SDSC&amp;suiteName=real-time&amp;xmlFile=real-time.xml">
                          real-time monitoring testbed
                        </a>
                      </li>
                      <li>
                        <a href="xslt.jsp?markOld&amp;xsl=default.xsl&amp;resourceID=teragrid&amp;suiteName=security">
                          security
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
