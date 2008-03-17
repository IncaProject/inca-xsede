import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import java.util.Vector;
import java.util.Enumeration;
import java.util.regex.Pattern;
import java.net.URL;
import org.apache.log4j.Logger;
import edu.sdsc.inca.depot.util.DowntimeFilter;

/**
 * Prefixes error messages in depot reports with "DOWNTIME: +optionalString+: "
 * if the resource the report ran on is in downtime.   Resources are determined
 * to be in downtime if they are listed in a downtime properties file.  In order
 * to reduce overhead, the downtime properties file is retrieved and cached at
 * a refresh interval in the getDowntimes() method instead of being retrieved
 * for each filter instance.
 *
 * @author Kate Ericson &lt;kericson@sdsc.edu&gt;
 * @author Shava Smallen &lt;ssmallen@sdsc.edu&gt;
 */
public class TeraGridFilter extends edu.sdsc.inca.depot.util.ReportFilter {
  private static Logger logger = Logger.getLogger(DowntimeFilter.class);
  private static Properties downtimes = new Properties();
  private static Properties filters = new Properties();
  private static long lastDowntimeRefresh = 0;
  private static long lastFilterRefresh = 0;

  /**
   * Checks context to see if matches regex string for a down resource
   *
   * @return  string with resource down optional string
   */
  private String downSeriesResource() {
    String downResource = null;
    Enumeration keys = getFilters().keys();
    Vector checkResources = new Vector();
    while (keys.hasMoreElements()) {
      String key = (String)keys.nextElement();
      String value = (String)getFilters().get(key);
      if (Pattern.matches("(.|\\n)*"+value+"(.|\\n)*", super.getContext())){
        checkResources.addElement(key);
      }
    }
    String[] check = (String[])checkResources.toArray(
        new String [checkResources.size()] );
    for (String lookup : check){
      String resourceProp  = getDowntimes().getProperty(lookup);
      if (resourceProp != null){
        logger.debug( lookup + " is down " + resourceProp );
        return resourceProp;
      }
    }
    return downResource;
  }

  /**
   * Returns cached property list of regex filters.  Gets and caches
   * property list from file in classpath (filter.properties) if cache has
   * expired according to refreshMins.
   *
   */
  synchronized static Properties getFilters()  {
    String filterPropFile = System.getProperty("inca.depot.filterFile");
    if(filterPropFile == null) {
      filterPropFile  = "filter.properties";
    }
    String filterRefresh = System.getProperty("inca.depot.filterRefresh");
    if(filterRefresh == null) {
      filterRefresh  = "1440";
    }
    Integer refreshMins = Integer.parseInt(filterRefresh);
    long minSinceLastRefresh = (System.currentTimeMillis()-lastFilterRefresh)/60000;
    if (minSinceLastRefresh >= refreshMins){
      URL url = ClassLoader.getSystemClassLoader().getResource(filterPropFile);
      if(url == null) {
        logger.error( filterPropFile + " not found in classpath" );
      }
      logger.debug( "Located file " + url.getFile() );
      filters.clear();
      try {
        InputStream is = url.openStream();
        filters.load(is);
        is.close();
      } catch (IOException e){
        logger.error( "Can't load filter properties file" );
      }
      lastFilterRefresh = System.currentTimeMillis();
    }
    return filters;
  }

  /**
   * Returns cached property list of resources in downtime.  Gets and caches
   * property list from file in classpath (downtime.properties) if cache has
   * expired according to refreshMins.
   *
   * The property list file contents can be:
   *
   *  downResource1=optionalErrorMessagePrefixStringForResource1
   *  downResource2=optionalErrorMessagePrefixStringForResource2
   *
   * OR
   *
   *  downResource1
   *  downResource2
   *
   */
  synchronized static Properties getDowntimes()  {
    String downtimePropFile = System.getProperty("inca.depot.downtimeFile");
    if(downtimePropFile == null) {
      downtimePropFile  = "downtime.properties";
    }
    String downtimeRefresh = System.getProperty("inca.depot.downtimeRefresh");
    if(downtimeRefresh == null) {
      downtimeRefresh  = "15";
    }
    Integer refreshMins = Integer.parseInt(downtimeRefresh);
    long minSinceLastRefresh = (System.currentTimeMillis()-lastDowntimeRefresh)/60000;
    if (minSinceLastRefresh >= refreshMins){
      URL url = ClassLoader.getSystemClassLoader().getResource(downtimePropFile);
      if(url == null) {
        logger.error( downtimePropFile + " not found in classpath" );
      }
      logger.debug( "Located file " + url.getFile() );
      downtimes.clear();
      try {
        InputStream is = url.openStream();
        downtimes.load(is);
        is.close();
      } catch (IOException e){
        logger.error( "Can't load downtime properties file" );
      }
      lastDowntimeRefresh = System.currentTimeMillis();
    }
    return downtimes;
  }

  /**
   * Writes new report with modified error message to depot if resource is down
   *
   * @return  string with depot report (reporter Stdout)
   */
  public String getStdout() {
    if (getDowntimes().isEmpty()){
      return super.getStdout();
    } else {
      String downSeriesProp = downSeriesResource();
      if (downSeriesProp != null){
        return super.getStdout().replaceFirst(
            "<errorMessage>", "<errorMessage>DOWNTIME:"+ downSeriesProp +": ");
      }
      String resourceProp  = getDowntimes().getProperty(super.getResource());
      if (resourceProp != null){
        logger.debug( super.getResource() + " is down " + resourceProp );
        return super.getStdout().replaceFirst(
            "<errorMessage>", "<errorMessage>DOWNTIME:"+ resourceProp +": ");
      } else{
        return super.getStdout();
      }
    }
  }

}
