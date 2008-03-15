import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import java.util.Vector;
import java.util.regex.Pattern;
import java.net.URL;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
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
  private static long lastRefresh = 0;

  /**
   * Checks context to see if matches regex string for a down resource
   *
   * @return  string with resource down optional string
   */
  private String downSeriesResource() {
    String downResource = null;
    URL url = ClassLoader.getSystemClassLoader().getResource("filter.xml");
    if(url == null) {
      logger.error( "filter.xml not found in classpath" );
    }
    Vector checkResources = new Vector();
    try {
      File file = new File(url.getFile());
      Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);
      doc.getDocumentElement().normalize();
      NodeList nodeLst = doc.getElementsByTagName("resource");
      for (int i = 0; i < nodeLst.getLength(); i++) {
        Node node = nodeLst.item(i);
        if (node.getNodeType() == Node.ELEMENT_NODE) {
          Element resource = (Element)node;
          Element name = (Element)(resource.getElementsByTagName("name").item(0));
          String resourceName = (name.getChildNodes().item(0)).getNodeValue();
          //logger.debug("Name: "  + resourceName);
          Element regex = (Element)(resource.getElementsByTagName("regex").item(0));
          String regexStr = (regex.getChildNodes().item(0)).getNodeValue();
          //logger.debug("Regex: "  + regexStr);
          if (Pattern.matches("(.|\\n)*"+regexStr+"(.|\\n)*", super.getContext())){
            checkResources.addElement(resourceName);
          }
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
    } catch (Exception e){
      logger.error( "Problem parsing: " + e );
    }
    return downResource;
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
    long minSinceLastRefresh = (System.currentTimeMillis()-lastRefresh)/60000;
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
        logger.error( "Can't load properties file" );
      }
      lastRefresh = System.currentTimeMillis();
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
