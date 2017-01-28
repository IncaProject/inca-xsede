/*
 * KitQuery.java
 */
package edu.sdsc.inca;


import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.HashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;

import edu.sdsc.inca.util.StringMethods;
import org.apache.log4j.Logger;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;


/**
 *
 * @author Paul Hoover
 *
 */
class KitQuery {

  private static final Logger m_logger = Logger.getLogger(KitQuery.class);


  /**
   *
   */
  private static abstract class QueryProduct {

    private final String m_expression;


    // constructors


    /**
     *
     * @param expression
     */
    public QueryProduct(String expression)
    {
      m_expression = expression;
    }


    // public methods


    /**
     *
     * @param xpath
     * @param result
     * @param configDoc
     * @param configKit
     * @param configRes
     * @return
     * @throws XPathExpressionException
     */
    boolean evaluate(XPath xpath, NodeList result, Document configDoc, Node configKit, Node configRes) throws XPathExpressionException
    {
      List<Node> resultList = new ArrayList<Node>();

      if (m_expression.length() > 0) {
        for (int i = 0 ; i < result.getLength() ; i += 1) {
          Node resultNode = (Node)xpath.evaluate(m_expression, result.item(i), XPathConstants.NODE);

          if (resultNode != null)
            resultList.add(resultNode);
        }
      }
      else {
        for (int i = 0 ; i < result.getLength() ; i += 1)
          resultList.add(result.item(i));
      }

      return evaluate(xpath, resultList, configDoc, configKit, configRes);
    }


    // protected methods


    /**
     *
     * @param xpath
     * @param result
     * @param configDoc
     * @param configKit
     * @param configRes
     * @return
     * @throws XPathExpressionException
     */
    protected abstract boolean evaluate(XPath xpath, List<Node> result, Document configDoc, Node configKit, Node configRes) throws XPathExpressionException;

    public String toString() {
      return "Expression: " + this.m_expression;
    }
  }

  /**
   *
   */
  private static class VersionProduct extends QueryProduct {

    private final String m_macroName;


    // constructors


    /**
     *
     * @param name
     */
    public VersionProduct(String expression, String name)
    {
      super(expression);

      m_macroName = name;
    }


    // protected methods


    /**
     *
     * @param xpath
     * @param result
     * @param configDoc
     * @param configKit
     * @param configRes
     * @return
     * @throws XPathExpressionException
     */
    protected boolean evaluate(XPath xpath, List<Node> result, Document configDoc, Node configKit, Node configRes) throws XPathExpressionException
    {
      if (result.isEmpty())
        return false;

      // May be duplicate versions (e.g., two login nodes for a host; so just do it once)
      HashMap<String,String> uniqueVersions = new HashMap<>();
      for ( int i = 0; i < result.toArray().length; i++ ) {
        String version = getVersion(xpath, result.get(i));
        uniqueVersions.put(version, "");
      }
      String[] newVersions = uniqueVersions.keySet().toArray(new String[uniqueVersions.keySet().size()]);
      Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);
      String resId = xpath.evaluate("name", configRes);
      return setMacroValues(xpath, configDoc, configKit, macroRes, resId, m_macroName, newVersions);
    }
  }

  /**
   *
   */
  private static class LatestVersionProduct extends QueryProduct {

    private final String m_macroName;


    // constructors


    /**
     *
     * @param name
     */
    public LatestVersionProduct(String expression, String name)
    {
      super(expression);

      m_macroName = name;
    }


    // protected methods


    /**
     *
     * @param xpath
     * @param result
     * @param configDoc
     * @param configKit
     * @param configRes
     * @return
     * @throws XPathExpressionException
     */
    protected boolean evaluate(XPath xpath, List<Node> result, Document configDoc, Node configKit, Node configRes) throws XPathExpressionException
    {
      if (result.isEmpty())
        return false;

      Node newest = findNewest(xpath, result);
      String version = getVersion(xpath, newest);
      String resId = xpath.evaluate("name", configRes);
      Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);

      return setMacroValue(xpath, configDoc, configKit, macroRes, resId, m_macroName, version);
    }
  }

  /**
   *
   */
  private static class URLProduct extends QueryProduct {

    private static final Pattern m_urlPattern = Pattern.compile("(?:[a-zA-Z]+://)?([a-zA-Z0-9\\-]+(?:\\.[a-zA-Z0-9\\-]+)*)(?::(\\d+))?(?:/[\\w\\-\\.]*)*");
    private final String m_hostName;
    private final String m_portName;


    // constructors


    /**
     *
     * @param host
     * @param port
     */
    public URLProduct(String expression, String host, String port)
    {
      super(expression);

      m_hostName = host;
      m_portName = port;
    }


    // protected methods


    /**
     *
     * @param xpath
     * @param result
     * @param configDoc
     * @param configKit
     * @param configRes
     * @return
     * @throws XPathExpressionException
     */
    protected boolean evaluate(XPath xpath, List<Node> result, Document configDoc, Node configKit, Node configRes) throws XPathExpressionException
    {
      if (result.isEmpty())
        return false;

      String resId = xpath.evaluate("name", configRes);

      HashMap<String, String> uniqueHosts = new HashMap<>();
      HashMap<String, String> uniquePorts = new HashMap<>();
      for ( int i = 0; i < result.toArray().length; i++ ) {
        String interfaceName = xpath.evaluate("InterfaceName", result.get(i));
        String url = xpath.evaluate("URL", result.get(i));
        Matcher matchResult = m_urlPattern.matcher(url);

        if (!matchResult.matches()) {
          if ( url.equals("") ) {
            m_logger.warn(resId + ": " + interfaceName + ": Empty URL found");
          } else {
            m_logger.warn(resId + ": " + interfaceName + ": invalid URL: " + url + "");
          }
          continue;
        }
        uniqueHosts.put(matchResult.group(1), "");
        uniquePorts.put(matchResult.group(2), "");
      }
      String[] newHosts = uniqueHosts.keySet().toArray(new String[uniqueHosts.size()]);
      String[] newPorts = uniquePorts.keySet().toArray(new String[uniquePorts.size()]);


      Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);
      boolean changedConfig = setMacroValues(xpath, configDoc, macroRes, resId, m_hostName, newHosts);

      if (setMacroValues(xpath, configDoc, configKit, macroRes, resId, m_portName, newPorts))
        changedConfig = true;

      return changedConfig;
    }
  }

  /**
   *
   */
  private static class OptionalProduct extends QueryProduct {

    private final String m_optionalName;


    // constructors


    /**
     *
     * @param name
     */
    public OptionalProduct(String expression, String optionalName)
    {
      super(expression);
      m_optionalName = optionalName;
    }


    // protected methods


    /**
     *
     * @param xpath
     * @param result
     * @param configDoc
     * @param configKit
     * @param configRes
     * @param id
     * @return
     * @throws XPathExpressionException
     */
    protected boolean evaluate(XPath xpath, List<Node> result, Document configDoc, Node configKit, Node configRes) throws XPathExpressionException
    {
      String query = "group[type = 'optional' and name = '" + m_optionalName + "']";
      Node optional = (Node)xpath.evaluate(query, configRes, XPathConstants.NODE);
      m_logger.debug("Running query: " + query);
      if (!result.isEmpty()) {
        if (optional != null) {
          return false;
        }

        String resId = xpath.evaluate("name", configRes);
        Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);
        Node newGroup = configDoc.createElement("group");
        Node newType = configDoc.createElement("type");
        Node newName = configDoc.createElement("name");

        newType.setTextContent("optional");
        newName.setTextContent(m_optionalName);
        newGroup.appendChild(newType);
        newGroup.appendChild(newName);
        configRes.insertBefore(newGroup, macroRes);

        m_logger.info(resId + ": added optional component " + m_optionalName);

        return true;
      }
      else {
        if (optional == null) {
          return false;
        }

        configRes.removeChild(optional);

        String resId = xpath.evaluate("name", configRes);

        m_logger.info(resId + ": removed optional component " + m_optionalName);

        return true;
      }
    }
  }

  /**
   *
   */
  private static class KeyProduct extends QueryProduct {

    private final String m_macroName;


    // constructors


    /**
     *
     * @param name
     */
    public KeyProduct(String expression, String name)
    {
      super(expression);

      m_macroName = name;
    }


    // protected methods


    /**
     *
     * @param xpath
     * @param result
     * @param configDoc
     * @param configKit
     * @param configRes
     * @return
     * @throws XPathExpressionException
     */
    protected boolean evaluate(XPath xpath, List<Node> result, Document configDoc, Node configKit, Node configRes) throws XPathExpressionException
    {
      if (result.isEmpty())
        return false;

      Node newest = findNewest(xpath, result);
      String appName = xpath.evaluate("AppName", newest);
      String appVersion = xpath.evaluate("AppVersion", newest);

      String key;

      if (appName.length() < 1 || appName.equalsIgnoreCase("None"))
      	key = "";
      else {
        key = "@keyPre@ " + appName;
        if (appVersion != null)
          key += "/" + appVersion;
        key += " @keyPost@";
      }

      String resId = xpath.evaluate("name", configRes);
      Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);

      return setMacroValue(xpath, configDoc, macroRes, resId, m_macroName, key);
    }
  }

  /**
   *
   */
  private static class EndpointProduct extends QueryProduct {

    private final String m_macroName;


    // constructors


    /**
     *
     * @param name
     */
    public EndpointProduct(String expression, String name)
    {
      super(expression);

      m_macroName = name;
    }


    // protected methods


    /**
     *
     * @param xpath
     * @param result
     * @param configDoc
     * @param configKit
     * @param configRes
     * @return
     * @throws XPathExpressionException
     */
    protected boolean evaluate(XPath xpath, List<Node> result, Document configDoc, Node configKit, Node configRes) throws XPathExpressionException
    {
      if (result.isEmpty())
        return false;

      String resId = xpath.evaluate("name", configRes);
      Node macroRes = (Node) xpath.evaluate("macroResource", configRes, XPathConstants.NODE);

      HashMap<String, String> uniqueURLs = new HashMap<>();
      for ( int i = 0; i < result.toArray().length; i++ ) {
        String endpoint = xpath.evaluate("URL", result.get(i));
        endpoint = endpoint.replaceFirst("\\/$", ""); // strip ending slash if exist
        uniqueURLs.put(endpoint, "");
      }
      String[] newURLs = uniqueURLs.keySet().toArray(new String[uniqueURLs.size()]);
      return setMacroValues(xpath, configDoc, configKit, macroRes, resId, m_macroName, newURLs);
    }
  }

  /**
   *
   */
  private static class GOEndpointProduct extends QueryProduct {

    private final String m_macroName;


    // constructors


    /**
     *
     * @param name
     */
    public GOEndpointProduct(String expression, String name)
    {
      super(expression);

      m_macroName = name;
    }


    // protected methods


    /**
     *
     * @param xpath
     * @param result
     * @param configDoc
     * @param configKit
     * @param configRes
     * @return
     * @throws XPathExpressionException
     */
    protected boolean evaluate(XPath xpath, List<Node> result, Document configDoc, Node configKit, Node configRes) throws XPathExpressionException
    {
      if (result.isEmpty())
        return false;

      String resId = xpath.evaluate("name", configRes);
      Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);
      String[] components = resId.split("\\.");
      String endpoint;

      if (components[0].equals("hpss"))
        endpoint = components[0] + "-" + components[1];
      else if (components[0].equals("blacklight"))
        endpoint = "pscdata";
      else
        endpoint = components[0];

      return setMacroValue(xpath, configDoc, macroRes, resId, m_macroName, endpoint);
    }
  }


  private final String m_expression;
  private final List<QueryProduct> m_products = new ArrayList<QueryProduct>();


  // constructors


  /**
   *
   * @param xpath
   * @param query
   * @throws XPathExpressionException
   * @throws IncaException
   */
  public KitQuery(XPath xpath, Node query) throws XPathExpressionException, IncaException
  {
    m_expression = xpath.evaluate("expression", query);

    if (m_expression.length() < 1)
      throw new IncaException("Kit query has no expression");

    NodeList productNodes = (NodeList)xpath.evaluate("products/*", query, XPathConstants.NODESET);

    for (int i = 0 ; i < productNodes.getLength() ; i += 1) {
      Node product = productNodes.item(i);
      String name = product.getNodeName();
      String expression = xpath.evaluate("expression", product);

      if (name.equals("version")) {
        String macro = xpath.evaluate("macro", product);

        m_products.add(new VersionProduct(expression, macro));
      }
      else if (name.equals("latestversion")) {
        String macro = xpath.evaluate("macro", product);

        m_products.add(new LatestVersionProduct(expression, macro));
      }
      else if (name.equals("url")) {
        String host = xpath.evaluate("host", product);
        String port = xpath.evaluate("port", product);

        m_products.add(new URLProduct(expression, host, port));
      }
      else if (name.equals("optional")) {
        String group = xpath.evaluate("group", product);

        m_products.add(new OptionalProduct(expression, group));
      }
      else if (name.equals("key")) {
        String macro = xpath.evaluate("macro", product);

        m_products.add(new KeyProduct(expression, macro));
      }
      else if (name.equals("endpoint")) {
        String macro = xpath.evaluate("macro", product);

        m_products.add(new EndpointProduct(expression, macro));
      }
      else if (name.equals("go-endpoint")) {
        String macro = xpath.evaluate("macro", product);

        m_products.add(new GOEndpointProduct(expression, macro));
      }
      else
        throw new IncaException("Unknown query product type " + name);
    }
  }


  // public methods


  /**
   *
   * @param xpath
   * @param inputRes
   * @return
   * @throws XPathExpressionException
   */
  public boolean matches(XPath xpath, Node inputRes) throws XPathExpressionException
  {
    NodeList resultNodes = (NodeList)xpath.evaluate(m_expression, inputRes, XPathConstants.NODESET);

    return resultNodes.getLength() > 0;
  }

  /**
   *
   * @param xpath
   * @param configDoc
   * @param inputRes
   * @param configKit
   * @param configRes
   * @return
   * @throws XPathExpressionException
   */
  public boolean evaluate(XPath xpath, Document configDoc, Node inputRes, Node configKit, Node configRes) throws XPathExpressionException
  {
    NodeList resultNodes = (NodeList)xpath.evaluate(m_expression, inputRes, XPathConstants.NODESET);
    m_logger.debug("Kit query " + m_expression + ": " + resultNodes.getLength() + " results");
    boolean changedConfig = false;

    for (QueryProduct product : m_products) {
      m_logger.debug("Evaluating product type: " + product.getClass().toString());
      if (product.evaluate(xpath, resultNodes, configDoc, configKit, configRes))
        changedConfig = true;
    }

    return changedConfig;
  }


  // private methods


  /**
   *
   * @param xpath
   * @param resultNode
   * @return
   * @throws XPathExpressionException
   */
  private static String getVersion(XPath xpath, Node resultNode) throws XPathExpressionException
  {
    String version = xpath.evaluate("InterfaceVersion", resultNode);

    if (version.length() < 1)
    	version = xpath.evaluate("AppVersion", resultNode);

    return version;
  }

  /**
   *
   * @param xpath
   * @param nodes
   * @return
   * @throws XPathExpressionException
   */
  private static Node findNewest(XPath xpath, List<Node> nodes) throws XPathExpressionException
  {
    assert !nodes.isEmpty();

    Iterator<Node> elements = nodes.iterator();
    Node resultNode = elements.next();
    String resultText = getVersion(xpath, resultNode);

    while (elements.hasNext()) {
      Node currentNode = elements.next();
      String currentText = getVersion(xpath, currentNode);
      String[] currentPieces = currentText.split("\\.|r");
      String[] newestPieces = resultText.split("\\.|r");
      int offset = 0;

      while (true) {
        if (offset >= currentPieces.length)
          break;

        if (offset >= newestPieces.length) {
          resultNode = currentNode;
          resultText = currentText;

          break;
        }

        try {
          int current = Integer.valueOf(currentPieces[offset]);
          int newest = Integer.valueOf(newestPieces[offset]);

          if (newest > current)
            break;

          if (current > newest) {
            resultNode = currentNode;
            resultText = currentText;

            break;
          }
        }
        catch (NumberFormatException formatErr) {
          int comparison = currentPieces[offset].compareTo(newestPieces[offset]);

          if (comparison < 0)
            break;

          if (comparison > 0) {
            resultNode = currentNode;
            resultText = currentText;

            break;
          }
        }

        offset += 1;
      }
    }

    return resultNode;
  }

  protected static boolean setMacroValue(XPath xpath, Document config, Node kit, Node resource, String id, String name, String value) throws XPathExpressionException
  {
    return setMacroValues(xpath, config, kit, resource, id, name, new String[]{value} );
  }
  /**
   *
   * @param xpath
   * @param config
   * @param kit
   * @param resource
   * @param id
   * @param name
   * @param values
   * @return
   * @throws XPathExpressionException
   */
  protected static boolean setMacroValues(XPath xpath, Document config, Node kit, Node resource, String id, String name, String[] values) throws XPathExpressionException
  {
    Node defaultValue = (Node)xpath.evaluate("macro[name = '" + name + "']/value", kit, XPathConstants.NODE);

    if (defaultValue != null && defaultValue.getTextContent().equals(values[0]))
      return false;

    return setMacroValues(xpath, config, resource, id, name, values);
  }

  protected static boolean setMacroValue(XPath xpath, Document config, Node resource, String id, String name, String value) throws XPathExpressionException
  {
    return setMacroValues(xpath, config, resource, id, name, new String[]{value});
  }

  /**
   *
   * @param xpath
   * @param config
   * @param resource
   * @param id
   * @param name
   * @param newValues
   * @return
   * @throws XPathExpressionException
   */
  protected static boolean setMacroValues(XPath xpath, Document config, Node resource, String id, String name, String[] newValues) throws XPathExpressionException
  {
    Node currentMacro = (Node)xpath.evaluate("macro[name = '" + name + "']", resource, XPathConstants.NODE);

    if (currentMacro == null) {
      Node newMacro = createMacroNode(config, name, newValues);
      resource.appendChild(newMacro);
      m_logger.info(id + ": added macro " + name);

      return true;
    } else {
      String macroType = xpath.evaluate("type", currentMacro);

      if (!macroType.equals("constant")) {
        NodeList macroValues = (NodeList)xpath.evaluate("value", currentMacro, XPathConstants.NODESET);
        String[] currentValues = new String[macroValues.getLength()];
        for (int i = 0; i < macroValues.getLength(); i++ ) {
           Node macroValue = macroValues.item(i);
           currentValues[i] = macroValue.getTextContent();
        }
        if (!Arrays.equals(newValues, currentValues)) {
          Node newMacro = createMacroNode(config, name, newValues);
          resource.replaceChild(newMacro, currentMacro);

          m_logger.info(id + ": changed value of macro " + name + " from " + StringMethods.join(", ", currentValues) +
                  " to " + StringMethods.join(", ", newValues));

          return true;
        }
      }
      return false;
    }
  }

  private static Node createMacroNode(Document config, String name, String[] newValues) {
    Node newMacro = config.createElement("macro");
    Node newChild = config.createElement("type");

    newChild.setTextContent("variable");
    newMacro.appendChild(newChild);

    newChild = config.createElement("name");

    newChild.setTextContent(name);
    newMacro.appendChild(newChild);

    for (String value : newValues) {
      newChild = config.createElement("value");

      newChild.setTextContent(value);
      newMacro.appendChild(newChild);
    }
    return newMacro;
  }

  public String toString() {
    return  "  expression = " + this.m_expression + "\n" +
            "  product count = " + this.m_products.size() + "\n";
  }
}
