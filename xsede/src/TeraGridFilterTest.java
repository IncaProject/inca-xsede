import junit.framework.TestCase;
import org.apache.log4j.Logger;

/**
 * Test TeraGridFilter class
 *
 * @author Kate Kaya &lt;kate@sdsc.edu&gt;
 * @author Shava Smallen &lt;ssmallen@sdsc.edu&gt;
 *
 */

/**
 * Test the class used to filter TeraGrid reports
 */
public class TeraGridFilterTest extends TestCase {
  private static Logger logger = Logger.getLogger( TeraGridFilterTest.class );

  public void testDNS() throws Exception {
    String pingSuccess = "<?xml version='1.0'?>\n" +
      "<rep:report xmlns:rep='http://inca.sdsc.edu/dataModel/report_2.1'>\n" +
      "  <gmt>2011-08-19T17:11:58Z</gmt>\n" +
      "  <hostname>client65-138.sdsc.edu</hostname>\n" +
      "  <name>network.ping.unit</name>\n" +
      "  <version>13970</version>\n" +
      " <workingDir>/Users/ssmallen/inca-trunk/devel/reporters</workingDir>\n" +
      "  <reporterPath>bin/network.ping.unit</reporterPath>\n" +
      "  <args>\n" +
      "    <arg>\n" +
      "      <name>count</name>\n" +
      "      <value>5</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>help</name>\n" +
      "      <value>no</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>host</name>\n" +
      "      <value>capac.sdsc.edu</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>log</name>\n" +
      "      <value>0</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>timeout</name>\n" +
      "      <value>60</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>verbose</name>\n" +
      "      <value>1</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>version</name>\n" +
      "      <value>no</value>\n" +
      "    </arg>\n" +
      "  </args>\n" +
      "  <body>\n" +
      "    <unitTest>\n" +
      "      <ID>ping</ID>\n" +
      "    </unitTest>\n" +
      "  </body>\n" +
      "  <exitStatus>\n" +
      "    <completed>true</completed>\n" +
      "  </exitStatus>\n" +
      "</rep:report>";
    TeraGridFilter filter = new TeraGridFilter();
    filter.setStdout( pingSuccess );
    assertEquals( "output is untouched", pingSuccess, filter.getStdout() );

    String pingError = "<?xml version='1.0'?>\n" +
      "<rep:report xmlns:rep='http://inca.sdsc.edu/dataModel/report_2.1'>\n" +
      "  <gmt>2011-08-19T18:08:44Z</gmt>\n" +
      "  <hostname>client65-138.sdsc.edu</hostname>\n" +
      "  <name>network.ping.unit</name>\n" +
      "  <version>13970</version>\n" +
      " <workingDir>/Users/ssmallen/inca-trunk/devel/reporters</workingDir>\n" +
      "  <reporterPath>bin/network.ping.unit</reporterPath>\n" +
      "  <args>\n" +
      "    <arg>\n" +
      "      <name>count</name>\n" +
      "      <value>5</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>help</name>\n" +
      "      <value>no</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>host</name>\n" +
      "      <value>info.sdsc.edu</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>log</name>\n" +
      "      <value>0</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>timeout</name>\n" +
      "      <value>60</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>verbose</name>\n" +
      "      <value>1</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>version</name>\n" +
      "      <value>no</value>\n" +
      "    </arg>\n" +
      "  </args>\n" +
      "  <body/>\n" +
      "  <exitStatus>\n" +
      "    <completed>false</completed>\n" +
      "    <errorMessage>Command 'ping -c 5 -q info.sdsc.edu' failed: ping: cannot resolve info.sdsc.edu: Unknown host\n" +
      "     </errorMessage>\n" +
      "  </exitStatus>\n" +
      "</rep:report>";
    filter.setStdout(pingError);
    assertTrue( "DNS prefix added", filter.getStdout().matches("(?s)^.*DNS ERROR.*$"));

    String dnsReport = "<rep:report xmlns:rep='http://inca.sdsc.edu/dataModel/report_2.1'>\n" +
      "  <gmt>2011-08-19T18:35:25Z</gmt>\n" +
      "  <hostname>client65-138.sdsc.edu</hostname>\n" +
      "  <name>network.dnslookup.unit</name>\n" +
      "  <version>3</version>\n" +
      " <workingDir>/Users/ssmallen/inca-trunk/devel/reporters</workingDir>\n" +
      "  <reporterPath>bin/network.dnslookup.unit</reporterPath>\n" +
      "  <args>\n" +
      "    <arg>\n" +
      "      <name>help</name>\n" +
      "      <value>no</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>host</name>\n" +
      "      <value>infox.teragrid.org</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>log</name>\n" +
      "      <value>0</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>verbose</name>\n" +
      "      <value>1</value>\n" +
      "    </arg>\n" +
      "    <arg>\n" +
      "      <name>version</name>\n" +
      "      <value>no</value>\n" +
      "    </arg>\n" +
      "  </args>\n" +
      "  <body/>\n" +
      "  <exitStatus>\n" +
      "    <completed>false</completed>\n" +
      "    <errorMessage>no host found</errorMessage>\n" +
      "  </exitStatus>\n" +
      "</rep:report>";
    filter.setStdout(dnsReport);
    assertFalse( "DNS prefix not added",
      filter.getStdout().matches("(?s)^.*DNS ERROR.*$"));
  }

}
