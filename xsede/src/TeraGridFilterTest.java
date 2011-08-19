import junit.framework.TestCase;
import org.apache.log4j.Logger;
import java.util.regex.Pattern;
import java.io.File;
import java.io.Writer;
import java.io.BufferedWriter;
import java.io.FileWriter;

/**
 * Test TeraGridFilter class
 *
 * @author Kate Ericson &lt;kericson@sdsc.edu&gt;
 */

/**
 * Test the class used to filter TeraGrid reports
 */
public class TeraGridFilterTest extends TestCase {
  private static Logger logger = Logger.getLogger( TeraGridFilterTest.class );
  private static File downProp = new File( "etc/downtime.properties" );
  private static File filterProp = new File( "etc/filter.properties" );

  /**
   * Delete any pre-existing files.  Create default properties files and set
   * cache refresh to one minute.
   */
  public void setUp() throws Exception  {
    if ( downProp.exists() ) downProp.delete();
    downProp.createNewFile();
    if ( filterProp.exists() ) filterProp.delete();
    filterProp.createNewFile();
    System.setProperty("inca.depot.downtimeRefresh", "1");
    System.setProperty("inca.depot.filterRefresh", "1");
  }

  /**
   * Create a basic TeraGridFilter
   */
  public TeraGridFilter getFilter(){
    TeraGridFilter filter = new TeraGridFilter();
    filter.setContext("orig context");
    filter.setResource("orig-resource");
    filter.setStdout("<errorMessage>orig stdout");
    return filter;
  }

  /**
   * Test filter
   *
   * @throws Exception
   */
  public void testFilter() throws Exception {

    // original context, nothing in downtime or filter files
    String out = getFilter().getStdout();
    logger.debug( "stdout: "+ out );
    assertTrue( "returns original stdout", Pattern.matches(
        "^<errorMessage>orig stdout$", out) );

    // set a resource as down
    Writer writeDowntime = new BufferedWriter(new FileWriter(downProp));
    writeDowntime.write("orig-resource=123\n");
    writeDowntime.close();
    logger.debug( "Sleeping 65 seconds" );
    Thread.sleep(65000);
    String out2 = getFilter().getStdout();
    logger.debug( "stdout: "+ out2);
    assertTrue( "down orig resource", Pattern.matches(
        "^<errorMessage>DOWNTIME:123: orig stdout$", out2) );

    // set a context resource as down
    Writer writeDowntime2 = new BufferedWriter(new FileWriter(downProp));
    writeDowntime2.write("orig-resource=123\ncontext-resource=456");
    writeDowntime2.close();
    Writer writeFilter = new BufferedWriter(new FileWriter(filterProp));
    writeFilter.write("context-resource=(orig context)");
    writeFilter.close();
    logger.debug( "Sleeping 60 seconds" );
    Thread.sleep(60000);
    String out3 = getFilter().getStdout();
    logger.debug( "stdout: "+ out3 );
    assertTrue( "down context resource", Pattern.matches(
        "^<errorMessage>DOWNTIME:456: orig stdout$", out3) );

    // remove context matching but keep context and orig resource down
    Writer writeDowntime3 = new BufferedWriter(new FileWriter(downProp));
    writeDowntime3.write("orig-resource=123\ncontext-resource=456");
    writeDowntime3.close();
    Writer writeFilter2 = new BufferedWriter(new FileWriter(filterProp));
    writeFilter2.write("context-resource=(doesn't match)");
    writeFilter2.close();
    logger.debug( "Sleeping 60 seconds" );
    Thread.sleep(60000);
    String out4 = getFilter().getStdout();
    logger.debug( "stdout: "+ out4 );
    assertTrue( "context resource down but no match", Pattern.matches(
        "^<errorMessage>DOWNTIME:123: orig stdout$", out4) );

    // clear files, back to original output
    downProp.delete();
    downProp.createNewFile();
    filterProp.delete();
    filterProp.createNewFile();
    logger.debug( "Sleeping 60 seconds" );
    Thread.sleep(60000);
    String out5 = getFilter().getStdout();
    logger.debug( "stdout: "+ out5 );
    assertTrue( "returns original stdout", Pattern.matches(
        "^<errorMessage>orig stdout$",  out5) );
  }

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
