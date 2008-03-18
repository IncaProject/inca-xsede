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
  private String downSeriesResource(Properties downProp) {
    String downResource = null;
    Properties filterProp =
        getProperties("filter", "1440", filters, lastFilterRefresh);
    Enumeration keys = filterProp.keys();
    Vector checkResources = new Vector();
    while (keys.hasMoreElements()) {
      String key = (String)keys.nextElement();
      String value = (String)filterProp.get(key);
      if (Pattern.matches("(.|\\n)*"+value+"(.|\\n)*", super.getContext())){
        checkResources.addElement(key);
      }
    }
    String[] check = (String[])checkResources.toArray(
        new String [checkResources.size()] );
    for (String lookup : check){
      String resourceProp  = downProp.getProperty(lookup);
      if (resourceProp != null){
        logger.debug( lookup + " is down " + resourceProp );
        return resourceProp;
      }
    }
    return downResource;
  }

  /**
   * Returns cached property list.  Gets property list from file in classpath
   * if cache has expired according to refreshMins.
   */
  synchronized static Properties getProperties(
      String name, String refreshDefault, Properties prop, long lastRefresh)  {
    String propFile = System.getProperty("inca.depot."+name+"File");
    if(propFile == null) {
      propFile  = name+".properties";
    }
    String refresh = System.getProperty("inca.depot."+name+"Refresh");
    if(refresh == null) {
      refresh  = refreshDefault;
    }
    Integer refreshMins = Integer.parseInt(refresh);
    long minSinceLastRefresh = (System.currentTimeMillis()-lastRefresh)/60000;
    if (minSinceLastRefresh >= refreshMins){
      URL url = ClassLoader.getSystemClassLoader().getResource(propFile);
      if(url == null) {
        logger.error( propFile + " not found in classpath" );
      }
      logger.debug( "Located file " + url.getFile() );
      prop.clear();
      try {
        InputStream is = url.openStream();
        prop.load(is);
        is.close();
      } catch (IOException e){
        logger.error( "Can't load "+name+" properties file" );
      }
      if (name == "downtime") {
        lastDowntimeRefresh = System.currentTimeMillis();
      }
      if (name == "filter") {
        lastFilterRefresh = System.currentTimeMillis();
      }
    }
    return prop;
  }

  /**
   * Writes new report with modified error message to depot if resource is down
   *
   * @return  string with depot report (reporter Stdout)
   */
  public String getStdout() {
    Properties downProp =
        getProperties("downtime", "15", downtimes, lastDowntimeRefresh);
    if (downProp.isEmpty()){
      return super.getStdout();
    } else {
      String downSeriesProp = downSeriesResource(downProp);
      if (downSeriesProp != null){
        return super.getStdout().replaceFirst(
            "<errorMessage>", "<errorMessage>DOWNTIME:"+ downSeriesProp +": ");
      }
      String resourceProp  = downProp.getProperty(super.getResource());
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
