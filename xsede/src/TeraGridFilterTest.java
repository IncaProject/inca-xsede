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
   * Test filter
   *
   * @throws Exception
   */
  public void testFilter() throws Exception {
    TeraGridFilter filter = new TeraGridFilter();
    filter.setContext("orig context");
    filter.setResource("orig-resource");
    filter.setStdout("<errorMessage>orig stdout");

    // original context, nothing in downtime or filter files
    logger.debug( "stdout: "+ filter.getStdout() );
    assertTrue( "returns original stdout", Pattern.matches(
        "^<errorMessage>orig stdout$", filter.getStdout()) );

    // set a resource as down
    Writer writeDowntime = new BufferedWriter(new FileWriter(downProp));
    writeDowntime.write("orig-resource=123\n");
    writeDowntime.close();
    logger.debug( "Sleeping 60 seconds" );
    Thread.sleep(60000);
    logger.debug( "stdout: "+filter.getStdout() );
    assertTrue( "down orig resource", Pattern.matches(
        "^<errorMessage>DOWNTIME:123: orig stdout$", filter.getStdout()) );

    // set a context resource as down
    Writer writeDowntime2 = new BufferedWriter(new FileWriter(downProp));
    writeDowntime2.write("orig-resource=123\ncontext-resource=456");
    writeDowntime2.close();
    Writer writeFilter = new BufferedWriter(new FileWriter(filterProp));
    writeFilter.write("context-resource=(orig context)");
    writeFilter.close();
    logger.debug( "Sleeping 60 seconds" );
    Thread.sleep(60000);
    logger.debug( "stdout: "+filter.getStdout() );
    assertTrue( "down context resource", Pattern.matches(
        "^<errorMessage>DOWNTIME:456: orig stdout$", filter.getStdout()) );

    // remove context matching but keep context and orig resource down
    Writer writeDowntime3 = new BufferedWriter(new FileWriter(downProp));
    writeDowntime3.write("orig-resource=123\ncontext-resource=456");
    writeDowntime3.close();
    Writer writeFilter2 = new BufferedWriter(new FileWriter(filterProp));
    writeFilter2.write("context-resource=(doesn't match)");
    writeFilter2.close();
    logger.debug( "Sleeping 60 seconds" );
    Thread.sleep(60000);
    logger.debug( "stdout: "+filter.getStdout() );
    assertTrue( "context resource down but no match", Pattern.matches(
        "^<errorMessage>DOWNTIME:123: orig stdout$", filter.getStdout()) );

    // clear files, back to original output
    downProp.delete();
    downProp.createNewFile();
    filterProp.delete();
    filterProp.createNewFile();
    logger.debug( "Sleeping 60 seconds" );
    Thread.sleep(60000);
    logger.debug( "stdout: "+filter.getStdout() );
    assertTrue( "returns original stdout", Pattern.matches(
        "^<errorMessage>orig stdout$", filter.getStdout()) );
  }
}
