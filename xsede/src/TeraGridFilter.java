import java.util.Vector;
import java.util.Enumeration;
import java.util.regex.Pattern;
import org.apache.log4j.Logger;
import edu.sdsc.inca.util.CachedProperties;

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
  private static Logger logger = Logger.getLogger(TeraGridFilter.class);
  private static CachedProperties cacheDown =
      new CachedProperties("inca.depot.", "downtime", "15");
  private static CachedProperties cacheFilter =
      new CachedProperties("inca.depot.", "filter", "1440");

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
      String resourceProp  =
          cacheDown.getProperties().getProperty(super.getResource());
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
