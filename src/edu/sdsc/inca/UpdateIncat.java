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

import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Document;
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
	private static final Map<String, KitQuerySet> m_kitQueries = new TreeMap<String, KitQuerySet>();


	// public methods


	/**
	 *
	 * @param args
	 */
	public static void main(String[] args)
	{
		try {
			if (args.length < 2 || args.length > 3)
				throw new IncaException("usage: UpdateIncat config input [ output ]");

			XPath xpath = XPathFactory.newInstance().newXPath();
			NamespaceMap namespaces = new NamespaceMap();

			namespaces.addMapping("tg", "http://mds.teragrid.org/2007/02/ctss");
			xpath.setNamespaceContext(namespaces);

			DocumentBuilder docBuilder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
			Document configDoc = docBuilder.parse(new FileInputStream(args[0]));

			populateQueries(xpath, configDoc);

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

				System.err.println("Wrote new config file");
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
			err.printStackTrace(System.err);

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
		NodeList nodes = (NodeList)xpath.evaluate("/config/queries/kit", configDoc, XPathConstants.NODESET);

		for (int i = 0 ; i < nodes.getLength() ; i += 1) {
			Node kit = nodes.item(i);
			String kitName = xpath.evaluate("name", kit);
			String kitVersion = xpath.evaluate("version", kit);
			String kitKey = kitName + "-" + kitVersion;

			if (m_kitQueries.containsKey(kitKey))
				throw new IncaException("Config contains duplicate kits");

			m_kitQueries.put(kitKey, new KitQuerySet(xpath, kit));
		}

		nodes = (NodeList)xpath.evaluate("/config/queries/resource", configDoc, XPathConstants.NODESET);

		for (int i = 0 ; i < nodes.getLength() ; i += 1)
			m_resourceQueries.add(new ResourceQuery(xpath, nodes.item(i)));
	}

	/**
	 *
	 * @param xpath
	 * @param inputRes
	 * @return
	 * @throws XPathExpressionException
	 */
	private static boolean hasTestedSoftware(XPath xpath, Node inputRes) throws XPathExpressionException
	{
		NodeList kitNodes = (NodeList)xpath.evaluate("tg:Kit[tg:SupportLevel != 'retired']", inputRes, XPathConstants.NODESET);

		for (int j = 0 ; j < kitNodes.getLength() ; j += 1) {
			Node kit = kitNodes.item(j);
			String kitName = xpath.evaluate("tg:Name", kit);
			String kitVersion = xpath.evaluate("tg:Version", kit);
			String kitKey = kitName + "-" + kitVersion;
			KitQuerySet querySet = m_kitQueries.get(kitKey);

			if (querySet == null)
				continue;

			if (querySet.matches(xpath, kit))
				return true;
		}

		return false;
	}

	/**
	 *
	 * @param xpath
	 * @param inputDoc
	 * @param configDoc
	 * @return
	 * @throws XPathExpressionException
	 * @throws IncaException
	 */
	private static boolean examineInput(XPath xpath, Document inputDoc, Document configDoc) throws XPathExpressionException, IncaException
	{
		NodeList inputResNodes = (NodeList)xpath.evaluate("/tg:V4KitsRP/tg:KitRegistration", inputDoc, XPathConstants.NODESET);
		boolean changedConfig = false;

		for (int i = 0 ; i < inputResNodes.getLength() ; i += 1) {
			Node inputRes = inputResNodes.item(i);
			String resId = xpath.evaluate("tg:ResourceID", inputRes);
			Node configRes = (Node)xpath.evaluate("/config/resources/resource[name = '" + resId + "' and not(exists(skip))]", configDoc, XPathConstants.NODE);

			if (configRes == null) {
				if (hasTestedSoftware(xpath, inputRes))
					System.err.println(resId + ": has applicable kits, but is not present in the config");

				continue;
			}

			for (ResourceQuery query : m_resourceQueries) {
				if (query.evaluate(xpath, configDoc, inputRes, configRes))
					changedConfig = true;
			}

			NodeList kitNodes = (NodeList)xpath.evaluate("tg:Kit[tg:SupportLevel = 'production' or tg:SupportLevel = 'testing']", inputRes, XPathConstants.NODESET);

			for (int j = 0 ; j < kitNodes.getLength() ; j += 1) {
				Node kit = kitNodes.item(j);
				String kitName = xpath.evaluate("tg:Name", kit);
				String kitVersion = xpath.evaluate("tg:Version", kit);
				String kitKey = kitName + "-" + kitVersion;
				KitQuerySet querySet = m_kitQueries.get(kitKey);

				if (querySet == null) {
					System.err.println(resId + ": couldn't find a corresponding query set for kit " + kitName + ", version " + kitVersion);

					continue;
				}

				if (querySet.evaluate(xpath, configDoc, kit, configRes))
					changedConfig = true;
			}
		}

		return changedConfig;
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
			Node inputRes = (Node)xpath.evaluate("/tg:V4KitsRP/tg:KitRegistration[tg:ResourceID = '" + resId + "']", inputDoc, XPathConstants.NODE);

			if (inputRes == null) {
				System.err.println(resId + ": present in the config, but not in the input");

				continue;
			}

			for (KitQuerySet querySet : m_kitQueries.values()) {
				if (querySet.examineGroups(xpath, configDoc, inputRes, configRes))
					changedConfig = true;
			}
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
			String longName = xpath.evaluate("name", configRes);
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

			if (implNodes.getLength() < 1)
				System.err.println("group " + groupName + " has no implementers");
			else {
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
