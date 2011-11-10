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

	private static final Map<String, List<KitQuery>> m_kitQueries = new TreeMap<String, List<KitQuery>>();
	private static final Map<String, Map<String, String>> m_implQueries = new TreeMap<String, Map<String, String>>();


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

			DocumentBuilder docBuilder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
			XPath xpath = XPathFactory.newInstance().newXPath();
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
			writeKitResources(xpath, configDoc, builder);
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
		NodeList kitNodes = (NodeList)xpath.evaluate("/config/queries/kit", configDoc, XPathConstants.NODESET);

		for (int i = 0 ; i < kitNodes.getLength() ; i += 1) {
			Node kit = kitNodes.item(i);
			String kitKey = xpath.evaluate("resource", kit);

			if (m_kitQueries.containsKey(kitKey))
				throw new IncaException("Config contains duplicate kits");

			NodeList queryNodes = (NodeList)xpath.evaluate("query", kit, XPathConstants.NODESET);
			List<KitQuery> queryList = new ArrayList<KitQuery>();
			Map<String, String> queryMap = new TreeMap<String, String>();

			for (int j = 0 ; j < queryNodes.getLength() ; j += 1) {
				Node query = queryNodes.item(j);

				queryList.add(new KitQuery(xpath, query));

				Node optional = (Node)xpath.evaluate("products/optional", query, XPathConstants.NODE);

				if (optional != null) {
					String expression = xpath.evaluate("expression", query);

					queryMap.put(optional.getTextContent(), expression);
				}
			}

			m_kitQueries.put(kitKey, queryList);
			m_implQueries.put(kitKey, queryMap);
		}
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
		NodeList kitNodes = (NodeList)xpath.evaluate("kit[SupportLevel != 'retired']", inputRes, XPathConstants.NODESET);

		for (int j = 0 ; j < kitNodes.getLength() ; j += 1) {
			Node kit = kitNodes.item(j);
			String kitName = xpath.evaluate("Name", kit);
			String kitVersion = xpath.evaluate("Version", kit);
			String kitKey = kitName + "-" + kitVersion;
			List<KitQuery> queryList = m_kitQueries.get(kitKey);

			if (queryList == null)
				continue;

			for (KitQuery query : queryList) {
				if (query.matches(xpath, kit))
					return true;
			}
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
	 */
	private static boolean examineInput(XPath xpath, Document inputDoc, Document configDoc) throws XPathExpressionException
	{
		NodeList inputResNodes = (NodeList)xpath.evaluate("//resource", inputDoc, XPathConstants.NODESET);
		boolean changedConfig = false;

		for (int i = 0 ; i < inputResNodes.getLength() ; i += 1) {
			Node inputRes = inputResNodes.item(i);
			String resId = xpath.evaluate("ResourceID", inputRes);
			Node configRes = (Node)xpath.evaluate("/config/xsedeResources/resource[name = '" + resId + "']", configDoc, XPathConstants.NODE);

			if (configRes == null) {
				if (hasTestedSoftware(xpath, inputRes))
					System.err.println(resId + ": has applicable kits, but is not present in config");

				continue;
			}

			NodeList kitNodes = (NodeList)xpath.evaluate("kit[SupportLevel != 'retired']", inputRes, XPathConstants.NODESET);

			for (int j = 0 ; j < kitNodes.getLength() ; j += 1) {
				Node kit = kitNodes.item(j);
				String kitName = xpath.evaluate("Name", kit);
				String kitVersion = xpath.evaluate("Version", kit);
				String kitKey = kitName + "-" + kitVersion;
				List<KitQuery> queryList = m_kitQueries.get(kitKey);

				if (queryList == null) {
					System.err.println(resId + ": couldn't find a corresponding query entry for kit " + kitName + ", version " + kitVersion);

					continue;
				}

				Node configKit = (Node)xpath.evaluate("/config/kitResources/resource[name = '" + kitKey + "']", configDoc, XPathConstants.NODE);

				if (configKit == null) {
					System.err.println(resId + ": couldn't find a corresponding resource for kit " + kitName + ", version " + kitVersion);

					continue;
				}

				Node resKit = (Node)xpath.evaluate("kit[name = '" + kitKey + "']", configRes, XPathConstants.NODE);

				if (resKit == null) {
					Node newResKit = configDoc.createElement("kit");
					Node newName = configDoc.createElement("name");

					newName.setTextContent(kitKey);
					newResKit.appendChild(newName);
					configRes.appendChild(newResKit);

					changedConfig = true;

					System.err.println(resId + ": added kit " + kitKey);
				}

				for (KitQuery query : queryList) {
					if (query.evaluate(xpath, configDoc, kit, configKit, configRes))
						changedConfig = true;
				}
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
		NodeList configResNodes = (NodeList)xpath.evaluate("/config/xsedeResources/resource", configDoc, XPathConstants.NODESET);
		boolean changedConfig = false;

		for (int i = 0 ; i < configResNodes.getLength() ; i += 1) {
			Node configRes = configResNodes.item(i);
			String resId = xpath.evaluate("name", configRes);
			Node inputRes = (Node)xpath.evaluate("//resource[ResourceID = '" + resId + "']", inputDoc, XPathConstants.NODE);

			if (inputRes == null) {
				configRes.getParentNode().removeChild(configRes);

				changedConfig = true;

				System.err.println(resId + ": removed resource");

				continue;
			}

			NodeList resKitNodes = (NodeList)xpath.evaluate("kit", configRes, XPathConstants.NODESET);

			for (int j = 0 ; j < resKitNodes.getLength() ; j += 1) {
				Node resKit = resKitNodes.item(j);
				String kitKey = xpath.evaluate("name", resKit);
				int separator = kitKey.lastIndexOf("-");
				String kitName = kitKey.substring(0, separator);
				String kitVersion = kitKey.substring(separator + 1, kitKey.length());
				Map<String, String> queryMap = m_implQueries.get(kitKey);

				if (queryMap == null) {
					configRes.removeChild(resKit);

					changedConfig = true;

					System.err.println(resId + ": couldn't find a corresponding query entry for kit " + kitName + ", version " + kitVersion);

					continue;
				}

				Node inputKit = (Node)xpath.evaluate("kit[Name = '" + kitName + "' and Version = '" + kitVersion + "']", inputRes, XPathConstants.NODE);

				if (inputKit == null) {
					configRes.removeChild(resKit);

					changedConfig = true;

					System.err.println(resId + ": removed kit " + kitName + ", version " + kitVersion);

					continue;
				}

				String supportLevel = xpath.evaluate("SupportLevel", inputKit);

				if (supportLevel != null && supportLevel.equals("retired")) {
					configRes.removeChild(resKit);

					changedConfig = true;

					System.err.println(resId + ": removed retired kit " + kitName + ", version " + kitVersion);

					continue;
				}

				NodeList optionalNodes = (NodeList)xpath.evaluate("optional", resKit, XPathConstants.NODESET);

				for (int k = 0 ; k < optionalNodes.getLength() ; k += 1) {
					Node optional = optionalNodes.item(k);
					String optionalName = optional.getTextContent();
					String expression = queryMap.get(optionalName);

					if (expression == null) {
						resKit.removeChild(optional);

						changedConfig = true;

						System.err.println(resId + ": couldn't find a corresponding query entry for optional component " + optionalName);

						continue;
					}

					NodeList resultNodes = (NodeList)xpath.evaluate(expression, inputKit, XPathConstants.NODESET);

					if (resultNodes.getLength() < 1) {
						resKit.removeChild(optional);

						changedConfig = true;

						System.err.println(resId + ": removed optional component " + optionalName);

						continue;
					}
				}
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
		String timestamp = new SimpleDateFormat("ddMMMyyyy").format(new Date(oldFile.lastModified()));
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
		NodeList configResNodes = (NodeList)xpath.evaluate("/config/xsedeResources/resource", configDoc, XPathConstants.NODESET);

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
	private static void writeKitResources(XPath xpath, Document configDoc, StringBuilder builder) throws XPathExpressionException
	{
		NodeList configKitNodes = (NodeList)xpath.evaluate("/config/kitResources/resource", configDoc, XPathConstants.NODESET);

		for (int i = 0 ; i < configKitNodes.getLength() ; i += 1) {
			Node kit = configKitNodes.item(i);
			String kitName = xpath.evaluate("name", kit);
			NodeList implNodes = (NodeList)xpath.evaluate("/config/xsedeResources/resource[kit/name = '" + kitName + "']/name", configDoc, XPathConstants.NODESET);

			if (implNodes.getLength() < 1)
				System.err.println("kit " + kitName + " has no implementers");
			else {
				StringBuilder implementers = new StringBuilder();

				implementers.append(implNodes.item(0).getTextContent());

				for (int j = 1 ; j < implNodes.getLength() ; j += 1) {
					implementers.append(' ');
					implementers.append(implNodes.item(j).getTextContent());
				}

				writeIncatResource(xpath, kit, implementers.toString(), false, builder);
			}

			NodeList optionalNodes = (NodeList)xpath.evaluate("optional", kit, XPathConstants.NODESET);

			for (int j = 0 ; j < optionalNodes.getLength() ; j += 1) {
				kit = optionalNodes.item(j);
				kitName = xpath.evaluate("name", kit);
				implNodes = (NodeList)xpath.evaluate("/config/xsedeResources/resource[kit/optional = '" + kitName + "']/name", configDoc, XPathConstants.NODESET);

				if (implNodes.getLength() < 1)
					System.err.println("optional component " + kitName + " has no implementers");
				else {
					StringBuilder implementers = new StringBuilder();

					implementers.append(implNodes.item(0).getTextContent());

					for (int k = 1 ; k < implNodes.getLength() ; k += 1) {
						implementers.append(' ');
						implementers.append(implNodes.item(k).getTextContent());
					}

					writeIncatResource(xpath, kit, implementers.toString(), false, builder);
				}
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
		NodeList configGroupNodes = (NodeList)xpath.evaluate("/config/groupResources/resource", configDoc, XPathConstants.NODESET);

		for (int i = 0 ; i < configGroupNodes.getLength() ; i += 1) {
			Node group = configGroupNodes.item(i);
			String groupName = xpath.evaluate("name", group);
			NodeList implNodes = (NodeList)xpath.evaluate("/config//*[group = '" + groupName + "']/name", configDoc, XPathConstants.NODESET);

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
