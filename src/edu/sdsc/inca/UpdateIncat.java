/*
 * UpdateIncat.java
 */
package edu.sdsc.inca;


import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.OutputStreamWriter;
import java.io.StringReader;
import java.io.Writer;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import net.sf.saxon.om.NamespaceConstant;
import org.apache.log4j.ConsoleAppender;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.log4j.PatternLayout;
import org.w3c.dom.Document;
import org.w3c.dom.DOMException;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.ls.DOMImplementationLS;
import org.w3c.dom.ls.LSOutput;
import org.w3c.dom.ls.LSSerializer;
import org.xml.sax.InputSource;


/**
 *
 * @author Paul Hoover
 *
 */
public class UpdateIncat {
	private static final List<ResourceQuery> m_resourceQueries = new ArrayList<ResourceQuery>();
	private static final List<KitQuerySet> m_kitQueries = new ArrayList<KitQuerySet>();
	private static final Logger m_logger = Logger.getLogger(UpdateIncat.class);


	// public methods


	/**
	 *
	 * @param args
	 */
	public static void main(String[] args)
	{
		Logger logger = Logger.getRootLogger();
		logger.setLevel(Level.ERROR);
		Logger incaLogger = Logger.getLogger("edu.sdsc.inca");
		incaLogger.setLevel(Level.WARN);
		if (System.getProperty("LOGLEVEL") != null) {
			incaLogger.setLevel(Level.toLevel(System.getProperty("LOGLEVEL")));
		}
		logger.addAppender(new ConsoleAppender(new PatternLayout("%d{ABSOLUTE} %5p [%t] %c{1}:%L - %m%n"), "System.out"));
		try {
			if (args.length < 2 || args.length > 3)
				throw new IncaException("usage: UpdateIncat config input [ output ]");

			System.setProperty("javax.xml.xpath.XPathFactory:" + NamespaceConstant.OBJECT_MODEL_SAXON, "net.sf.saxon.xpath.XPathFactoryImpl");
			XPathFactory xPathFactory = XPathFactory.newInstance(NamespaceConstant.OBJECT_MODEL_SAXON);
			XPath xpath = xPathFactory.newXPath();
			DocumentBuilder docBuilder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
			m_logger.info("Reading config doc " + args[0]);
			Document configDoc = docBuilder.parse(new FileInputStream(args[0]));

			populateQueries(xpath, configDoc);

			m_logger.info("Reading input doc " + args[1]);
			Document inputDoc = docBuilder.parse(new FileInputStream(args[1]));
			boolean changedConfig = examineInput(xpath, inputDoc, configDoc);

			if (examineConfig(xpath, inputDoc, configDoc))
				changedConfig = true;

			DOMImplementationLS lsImpl = (DOMImplementationLS)configDoc.getImplementation().getFeature("LS", "3.0");
			LSSerializer lsSerializer = lsImpl.createLSSerializer();
			LSOutput lsOutput = lsImpl.createLSOutput();

			lsOutput.setEncoding("UTF-8");
			lsSerializer.getDomConfig().setParameter("format-pretty-print", Boolean.TRUE);

			if (changedConfig) {
				createBackupFile(args[0]);

				lsOutput.setCharacterStream(new FileWriter(args[0]));
				lsSerializer.write(configDoc, lsOutput);

				m_logger.info("Wrote new config file");
			}

			StringBuilder builder = new StringBuilder();
			String repository = xpath.evaluate("/config/properties/repository", configDoc);

			builder.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
			builder.append("<inca:inca xmlns:inca=\"http://inca.sdsc.edu/dataModel/inca_2.0\">");
			builder.append("<repositories>");
			builder.append("<repository>" + repository + "</repository>");
			builder.append("</repositories>");
			builder.append("<resourceConfig>");
			builder.append("<resources>");

			writeXsedeResources(xpath, configDoc, builder);
			writeGroupResources(xpath, configDoc, builder);

			builder.append("</resources>");
			builder.append("</resourceConfig>");
			builder.append("</inca:inca>");

			InputSource source = new InputSource(new StringReader(builder.toString()));
			Document incatDoc = docBuilder.parse(source);
			Node configSuites = (Node)xpath.evaluate("/config/suites", configDoc, XPathConstants.NODE);
			Node importedSuites = incatDoc.importNode(configSuites, true);

			incatDoc.getDocumentElement().appendChild(importedSuites);

			Writer outStream = args.length < 3 ? new OutputStreamWriter(System.out) : new FileWriter(args[2]);

			lsOutput.setCharacterStream(outStream);
			lsSerializer.write(incatDoc, lsOutput);
		}
		catch (Exception err) {
			m_logger.error("Problem running UpdateIncat", err);
			System.exit(-1);
		}
	}


	// private methods


	/**
	 *
	 * @param xpath
	 * @param configDoc
	 * @throws XPathExpressionException
	 * @throws IncaException
	 */
	private static void populateQueries(XPath xpath, Document configDoc) throws XPathExpressionException, IncaException
	{
		Map<String, KitQuerySet> kitQueries = new TreeMap<String, KitQuerySet>();
		NodeList nodes = (NodeList)xpath.evaluate("/config/queries/kit", configDoc, XPathConstants.NODESET);

		for (int i = 0 ; i < nodes.getLength() ; i += 1) {
			Node kit = nodes.item(i);
			String kitName = xpath.evaluate("name", kit);
			String kitVersion = xpath.evaluate("version", kit);
			String kitKey = kitName + "-" + kitVersion;

			if (kitQueries.containsKey(kitKey))
				throw new IncaException("Config contains duplicate kits");

			kitQueries.put(kitKey, new KitQuerySet(xpath, kit));
		}

		m_kitQueries.addAll(kitQueries.values());

		nodes = (NodeList)xpath.evaluate("/config/queries/resource", configDoc, XPathConstants.NODESET);

		for (int i = 0 ; i < nodes.getLength() ; i += 1)
			m_resourceQueries.add(new ResourceQuery(xpath, nodes.item(i)));
	}

	/**
	 *
	 * @param xpath
	 * @param inputDoc
	 * @param configDoc
	 * @return
	 * @throws XPathExpressionException
	 * @throws ParserConfigurationException
	 * @throws DOMException
	 * @throws IncaException
	 */
	private static boolean examineInput(XPath xpath, Document inputDoc, Document configDoc) throws XPathExpressionException, ParserConfigurationException, DOMException, IncaException
	{
		// There appears to be two types of resources (most of the time) for every resource; one that is rdr_type
		// compute and the other is rdr_type resource.  Each has different attributes of interest so we combine when
		// both exist
		NodeList inputComputeResourceNodes = (NodeList)xpath.evaluate("//resources/list-item[rdr_type = 'compute' and matches(current_statuses,'test|[^-]?production') and matches(provider_level, 'XSEDE Level (1|2)$')]", inputDoc, XPathConstants.NODESET);
		boolean changedConfig = false;
		NodeList allinputs =  (NodeList)xpath.evaluate("//list-item", inputDoc, XPathConstants.NODESET);
		m_logger.debug(allinputs.getLength() + " all input items");


		for (int i = 0 ; i < inputComputeResourceNodes.getLength() ; i += 1) {
			Node computeResNode = inputComputeResourceNodes.item(i);
			String resId = xpath.evaluate("info_resourceid", computeResNode);
			Node resourceNode = (Node)xpath.evaluate("//resources/list-item[rdr_type = 'resource' and info_resourceid = '" + resId + "']", inputDoc, XPathConstants.NODE);
			if ( resourceNode != null ) {
				extractAttributes(computeResNode, resourceNode);
			}

			Node configRes = (Node)xpath.evaluate("/config/resources/resource[name = '" + resId + "' and not(exists(skip))]", configDoc, XPathConstants.NODE);
			String inputQuery = "//list-item[ResourceID = '" + resId.replace("teragrid", "xsede") + "' and (not(ServingState) or ServingState != 'retired') ]";
			NodeList inputSoftwareServiceNodes = (NodeList)xpath.evaluate(inputQuery, inputDoc, XPathConstants.NODESET);
			m_logger.debug("Resource query " + inputQuery + ": " + inputSoftwareServiceNodes.getLength() + " results");
			if (configRes == null) {
				if (inputSoftwareServiceNodes.getLength()>0)
					m_logger.warn(resId + ": has applicable services or software, but is not present in the config");
				continue;
			}

			resourceNode = (Node)xpath.evaluate("//xdcdb/list-item[ResourceID = '" + resId + "']", inputDoc, XPathConstants.NODE);
			if ( resourceNode != null ) {
				extractAttributes(computeResNode, resourceNode);
			} else {
				m_logger.warn("No XDCDB info for " + resId);
			}

			for (ResourceQuery query : m_resourceQueries) {
				m_logger.debug("Running resource query: " + query.toString());
				if (query.evaluate(xpath, configDoc, computeResNode, configRes))
					changedConfig = true;
			}

			// some resources are old enough to have .teragrid.org in RDR but are registering with .xsede.org (e.g., Gordon)
			if ( inputSoftwareServiceNodes == null ) {
				m_logger.warn(resId + ": has no services or software, but is present in the config");
				continue;
			}
			Document queryTarget = DocumentBuilderFactory.newInstance().newDocumentBuilder().newDocument();
			Element root = queryTarget.createElement("root");
			queryTarget.appendChild(root);
			for( int j = 0; j < inputSoftwareServiceNodes.getLength(); j++) {
				Node node = inputSoftwareServiceNodes.item(j);
				Node copyNode = queryTarget.importNode(node, true);
				root.appendChild(copyNode);
			}
			for (KitQuerySet querySet : m_kitQueries) {
				m_logger.debug("Running kit query: " + querySet.toString());
				if (querySet.matches(xpath, root) && querySet.evaluate(xpath, configDoc, root, configRes))
					changedConfig = true;
			}



		}

		return changedConfig;
	}

	private static void extractAttributes(Node computeResNode, Node resourceNode) {
		NodeList resourceAttributes = resourceNode.getChildNodes();
		for ( int j = 0; j < resourceAttributes.getLength(); j++) {
            computeResNode.appendChild(resourceAttributes.item(j).cloneNode(true));
        }
	}

	/**
	 *
	 * @param xpath
	 * @param inputDoc
	 * @param configDoc
	 * @return
	 * @throws XPathExpressionException
	 */
	private static boolean examineConfig(XPath xpath, Document inputDoc, Document configDoc) throws XPathExpressionException
	{
		NodeList configResNodes = (NodeList)xpath.evaluate("/config/resources/resource", configDoc, XPathConstants.NODESET);
		boolean changedConfig = false;

		for (int i = 0 ; i < configResNodes.getLength() ; i += 1) {
			Node configRes = configResNodes.item(i);
			String resId = xpath.evaluate("name", configRes);
			Node inputRes = (Node)xpath.evaluate("//resources/list-item[info_resourceid = '" + resId + "']", inputDoc, XPathConstants.NODE);

			if (inputRes == null) {
				m_logger.warn(resId + ": present in the config, but not in the input");

				continue;
			}

			/*
			for (KitQuerySet querySet : m_kitQueries) {
				if (querySet.examineGroups(xpath, configDoc, inputRes, configRes))
					changedConfig = true;
			}
			*/
		}

		return changedConfig;
	}

	/**
	 *
	 * @param fileName
	 * @throws IncaException
	 */
	private static void createBackupFile(String fileName) throws IncaException
	{
		int position = fileName.lastIndexOf('.');
		File oldFile = new File(fileName);
		String timestamp = (new SimpleDateFormat("ddMMMyyyy")).format(new Date(oldFile.lastModified()));
		String basename;
		String extension;

		if (position >= 0) {
			basename = fileName.substring(0, position) + "_" + timestamp;
			extension = fileName.substring(position);
		}
		else {
			basename = fileName + "_" + timestamp;
			extension = "";
		}

		File newFile = new File(basename + extension);

		if (newFile.exists()) {
			int version = 1;

			do {
				newFile = new File(basename + "_" + version + extension);

				version += 1;
			}
			while (newFile.exists());
		}

		if (!oldFile.renameTo(newFile))
			throw new IncaException("Can't rename " + fileName);
	}

	/**
	 *
	 * @param xpath
	 * @param resource
	 * @param pattern
	 * @param equivalent
	 * @param builder
	 * @throws XPathExpressionException
	 */
	private static void writeIncatResource(XPath xpath, Node resource, String pattern, boolean equivalent, StringBuilder builder) throws XPathExpressionException
	{
		String resName = xpath.evaluate("name", resource);

		builder.append("<resource xmlns:res=\"http://inca.sdsc.edu/dataModel/resourceConfig_2.0\">");
		builder.append("<name>" + resName + "</name>");
		builder.append("<xpath>//resource[matches(name, '^(" + pattern.replace(' ', '|').replace(".", "\\.") + ")$')]</xpath>");
		builder.append("<macros>");
    if ( equivalent ) {
		  builder.append("<macro>");
		  builder.append("<name>__shortname__</name>");
		  builder.append("<value>" + resName + "</value>");
	  	builder.append("</macro>");
    } else {
		  builder.append("<macro>");
		  builder.append("<name>__longname__</name>");
		  builder.append("<value>" + resName + "</value>");
	  	builder.append("</macro>");
    }
		builder.append("<macro>");
		builder.append("<name>__groupname__</name>");
		builder.append("<value>" + resName + "</value>");
	  builder.append("</macro>");
		builder.append("<macro>");
		builder.append("<name>__regexp__</name>");
		builder.append("<value>" + pattern + "</value>");
		builder.append("</macro>");
		builder.append("<macro>");
		builder.append("<name>__equivalent__</name>");
		builder.append("<value>" + equivalent + "</value>");
		builder.append("</macro>");

		NodeList macroNodes = (NodeList)xpath.evaluate("macro", resource, XPathConstants.NODESET);

		for (int i = 0 ; i < macroNodes.getLength() ; i += 1) {
			Node macro = macroNodes.item(i);
			String macroName = xpath.evaluate("name", macro);
			NodeList macroValues = (NodeList)xpath.evaluate("value", macro, XPathConstants.NODESET);

			builder.append("<macro>");
			builder.append("<name>" + macroName + "</name>");

			for (int j = 0 ; j < macroValues.getLength() ; j += 1) {
				String value = macroValues.item(j).getTextContent();

				builder.append("<value>");

				if (value.matches(".*[&<>]+.*"))
					builder.append("<![CDATA[" + value + "]]>");
				else
					builder.append(value);

				builder.append("</value>");
			}

			builder.append("</macro>");
		}

		builder.append("</macros>");
		builder.append("</resource>");
	}

	/**
	 *
	 * @param xpath
	 * @param configDoc
	 * @param builder
	 * @throws XPathExpressionException
	 */
	private static void writeXsedeResources(XPath xpath, Document configDoc, StringBuilder builder) throws XPathExpressionException
	{
		NodeList configResNodes = (NodeList)xpath.evaluate("/config/resources/resource", configDoc, XPathConstants.NODESET);

		for (int i = 0 ; i < configResNodes.getLength() ; i += 1) {
			Node configRes = configResNodes.item(i);
			Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);
			String shortName = xpath.evaluate("name", macroRes);

			writeIncatResource(xpath, configRes, shortName, false, builder);

			String hostNames = xpath.evaluate("hosts", macroRes);

			writeIncatResource(xpath, macroRes, hostNames, true, builder);

			String[] hosts = hostNames.split("\\s+");

			for (int k = 0 ; k < hosts.length ; k += 1) {
				builder.append("<resource>");
				builder.append("<name>" + hosts[k] + "</name>");
				builder.append("</resource>");
			}
		}
	}

	/**
	 *
	 * @param xpath
	 * @param configDoc
	 * @param builder
	 * @throws XPathExpressionException
	 */
	private static void writeGroupResources(XPath xpath, Document configDoc, StringBuilder builder) throws XPathExpressionException
	{
		NodeList groupNodes = (NodeList)xpath.evaluate("/config/groups/group", configDoc, XPathConstants.NODESET);

		for (int i = 0 ; i < groupNodes.getLength() ; i += 1) {
			Node group = groupNodes.item(i);
			String groupType = xpath.evaluate("type", group);
			String groupName = xpath.evaluate("name", group);
			NodeList implNodes = (NodeList)xpath.evaluate("/config//*/group[type = '" + groupType + "' and name = '" + groupName + "']/../name", configDoc, XPathConstants.NODESET);

			if (implNodes.getLength() < 1) {
				m_logger.warn("group " + groupName + " has no implementers");
				writeIncatResource(xpath, group, "", false, builder);
			} else {
				StringBuilder implementers = new StringBuilder();

				implementers.append(implNodes.item(0).getTextContent());

				for (int j = 1 ; j < implNodes.getLength() ; j += 1) {
					implementers.append(' ');
					implementers.append(implNodes.item(j).getTextContent());
				}

				writeIncatResource(xpath, group, implementers.toString(), false, builder);
			}
		}
	}
}
