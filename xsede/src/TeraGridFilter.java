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
  private CachedProperties cacheDown = new CachedProperties("downtime", "15");
  private CachedProperties cacheFilter = new CachedProperties("filter", "1440");

  /**
   * Creates cached Properties fetched according to refreshMins.
   */
  private class CachedProperties {
    private Properties prop = new Properties();
    private long lastRefresh = 0;
    private String fileName;
    private String defaultRefresh;

    /**
     * Sets the name of the properties file in the classpath and the default
     * number of minutes to fetch it if not specified as a system property.
     */
    public CachedProperties(String fileName, String defaultRefresh){
      this.fileName = fileName;
      this.defaultRefresh = defaultRefresh;
    }

    /**
     * Gets property list from file in classpath if cache has expired
     * according to refreshMins.
     *
     * @return  cached Properties
     */
    synchronized Properties getProperties()  {
      String propFile = System.getProperty("inca.depot."+fileName+"File");
      if(propFile == null) {
        propFile  = fileName+".properties";
      }
      String refresh = System.getProperty("inca.depot."+fileName+"Refresh");
      if(refresh == null) {
        refresh  = defaultRefresh;
      }
      Integer refreshMins = Integer.parseInt(refresh);
      long minSinceLastRefresh = (System.currentTimeMillis()-lastRefresh)/60000;
      if (minSinceLastRefresh >= refreshMins){
        URL url = ClassLoader.getSystemClassLoader().getResource(propFile);
        if(url == null) {
          logger.error( propFile + " not found in classpath" );
        }
        logger.debug( "Located file " + url.getFile()
            + " refresh every " + refreshMins + " min.");
        prop.clear();
        try {
          InputStream is = url.openStream();
          prop.load(is);
          is.close();
        } catch (IOException e){
          logger.error( "Can't load "+fileName+" properties file" );
        }
        lastRefresh = System.currentTimeMillis();
      }
      return prop;
    }
  }

  /**
   * Checks context to see if matches regex string for a down resource
   *
   * @return  string with resource down optional string
   */
  private String downSeriesResource() {
    String downResource = null;
    Enumeration keys = cacheFilter.getProperties().keys();
    Vector checkResources = new Vector();
    while (keys.hasMoreElements()) {
      String key = (String)keys.nextElement();
      String value = (String)cacheFilter.getProperties().get(key);
      if (Pattern.matches("(.|\\n)*"+value+"(.|\\n)*", super.getContext())){
        checkResources.addElement(key);
      }
    }
    String[] check = (String[])checkResources.toArray(
        new String [checkResources.size()] );
    for (String lookup : check){
      String resourceProp  = cacheDown.getProperties().getProperty(lookup);
      if (resourceProp != null){
        logger.debug( lookup + " is down " + resourceProp );
        return resourceProp;
      }
    }
    return downResource;
  }

  /**
   * Writes new report with modified error message to depot if resource is down
   *
   * @return  string with depot report (reporter Stdout)
   */
  public String getStdout() {
    if (cacheDown.getProperties().isEmpty()){
      return super.getStdout();
    } else {
      String downSeriesProp = downSeriesResource();
      if (downSeriesProp != null){
        return super.getStdout().replaceFirst(
            "<errorMessage>", "<errorMessage>DOWNTIME:"+ downSeriesProp +": ");
      }
      String resourceProp  = cacheDown.getProperties().getProperty(super.getResource());
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
