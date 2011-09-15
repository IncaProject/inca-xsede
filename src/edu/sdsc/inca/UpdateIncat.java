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

	/**
	 *
	 */
	private static class Software {

		public final String macro;
		public final String expression;
		public final String resource;


		// constructors


		/**
		 *
		 * @param m
		 * @param e
		 * @param r
		 */
		public Software(String m, String e, String r)
		{
			macro = m;
			expression = e;
			resource = r;
		}
	}


	private static final Map<String, List<Software>> m_kitQueries = new TreeMap<String, List<Software>>();


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

			populateKitQueries(xpath, configDoc);

			Document inputDoc = docBuilder.parse(new FileInputStream(args[1]));
			NodeList resNodes = (NodeList)xpath.evaluate("//resource", inputDoc, XPathConstants.NODESET);
			boolean changedConfig = false;

			for (int i = 0 ; i < resNodes.getLength() ; i += 1) {
				Node resource = resNodes.item(i);
				String resId = xpath.evaluate("ResourceID", resource);
				Node configRes = (Node)xpath.evaluate("/config/tgResources/resource[name = '" + resId + "']", configDoc, XPathConstants.NODE);

				if (configRes == null) {
					if (hasTestedSoftware(xpath, resource))
						System.err.println(resId + ": has applicable kits, but is not present in config");

					continue;
				}

				NodeList macroResNodes = (NodeList)xpath.evaluate("macroResource", configRes, XPathConstants.NODESET);
				NodeList kitNodes = (NodeList)xpath.evaluate("kit", resource, XPathConstants.NODESET);

				for (int j = 0 ; j < kitNodes.getLength() ; j += 1) {
					Node kit = kitNodes.item(j);
					String kitName = xpath.evaluate("Name", kit);
					String kitVersion = xpath.evaluate("Version", kit);
					String kitKey = kitName + "-" + kitVersion;
					List<Software> swList = m_kitQueries.get(kitKey);

					if (swList == null) {
						System.err.println(resId + ": couldn't find a corresponding software entry for kit " + kitName + ", version " + kitVersion);

						continue;
					}

					Node configKit = (Node)xpath.evaluate("/config/kitResources/resource[name = '" + kitKey + "']", configDoc, XPathConstants.NODE);

					if (configKit == null) {
						System.err.println(resId + ": couldn't find a corresponding resource for kit " + kitName + ", version " + kitVersion);

						continue;
					}

					if (addIdToKitResource(xpath, configKit, resId)) {
						changedConfig = true;

						System.err.println(resId + ": added kit " + kitKey);
					}

					for (Software element : swList) {
						NodeList swNodes = (NodeList)xpath.evaluate(element.expression, kit, XPathConstants.NODESET);

						if (swNodes.getLength() > 0) {
							if (element.macro != null) {
								String newest = findNewest(xpath, swNodes);
								Node defaultValue = (Node)xpath.evaluate("macro[name = '" + element.macro + "']/value", configKit, XPathConstants.NODE);

								if (defaultValue == null || !defaultValue.getTextContent().equals(newest)) {
									for (int k = 0 ; k < macroResNodes.getLength() ; k += 1) {
										Node macroRes = macroResNodes.item(k);
										Node macroValue = (Node)xpath.evaluate("macro[name = '" + element.macro + "']/value", macroRes, XPathConstants.NODE);

										if (macroValue == null) {
											Node newMacro = configDoc.createElement("macro");
											Node newChild = configDoc.createElement("type");

											newChild.setTextContent("variable");
											newMacro.appendChild(newChild);

											newChild = configDoc.createElement("name");

											newChild.setTextContent(element.macro);
											newMacro.appendChild(newChild);

											newChild = configDoc.createElement("value");

											newChild.setTextContent(newest);
											newMacro.appendChild(newChild);
											macroRes.appendChild(newMacro);

											changedConfig = true;

											System.err.println(resId + ": added macro " + element.macro);
										}
										else {
											String macroText = macroValue.getTextContent();

											if (!macroText.equals(newest)) {
												macroValue.setTextContent(newest);

												changedConfig = true;

												System.err.println(resId + ": changed value of macro " + element.macro + " from " + macroText + " to " + newest);
											}
										}
									}
								}
							}

							if (element.resource != null) {
								Node optionalKit = (Node)xpath.evaluate("/config/kitResources/resource[name = '" + element.resource + "']", configDoc, XPathConstants.NODE);

								if (optionalKit == null) {
									System.err.println(resId + ": couldn't find a corresponding resource for optional component " + element.resource);

									continue;
								}

								if (addIdToKitResource(xpath, optionalKit, resId)) {
									changedConfig = true;

									System.err.println(resId + ": added optional component " + element.resource);
								}
							}
						}
					}
				}
			}

			for (Map.Entry<String, List<Software>> entry : m_kitQueries.entrySet()) {
				String kitKey = entry.getKey();
				Node configKit = (Node)xpath.evaluate("/config/kitResources/resource[name = '" + kitKey + "']", configDoc, XPathConstants.NODE);

				if (configKit == null)
					continue;

				int separator = kitKey.lastIndexOf("-");
				String kitName = kitKey.substring(0, separator);
				String kitVersion = kitKey.substring(separator + 1, kitKey.length());
				String implementers = xpath.evaluate("implementers", configKit);
				String[] resIds = implementers.split("\\s+");

				for (int i = 0 ; i < resIds.length ; i += 1) {
					Node resNode = (Node)xpath.evaluate("//resource[ResourceID = '" + resIds[i] + "']", inputDoc, XPathConstants.NODE);

					if (resNode == null) {
						NodeList nodes = (NodeList)xpath.evaluate("/config/kitResources/resource[matches(implementers, '.*" + resIds[i] + ".*')]", configDoc, XPathConstants.NODESET);

						for (int j = 0 ; j < nodes.getLength() ; j += 1)
							removeIdFromKitResource(xpath, nodes.item(j), resIds[i]);

						Node configRes = (Node)xpath.evaluate("/config/tgResources/resource[name = '" + resIds[i] + "']", configDoc, XPathConstants.NODE);

						configRes.getParentNode().removeChild(configRes);

						changedConfig = true;

						System.err.println(resIds[i] + ": removed resource");

						continue;
					}

					Node kitNode = (Node)xpath.evaluate("kit[Name = '" + kitName + "' and Version = '" + kitVersion + "']", resNode, XPathConstants.NODE);

					if (kitNode == null) {
						removeIdFromKitResource(xpath, configKit, resIds[i]);

						changedConfig = true;

						System.err.println(resIds[i] + ": removed kit " + kitKey);
					}
				}

				for (Software element : entry.getValue()) {
					if (element.resource == null)
						continue;

					configKit = (Node)xpath.evaluate("/config/kitResources/resource[name = '" + element.resource + "']", configDoc, XPathConstants.NODE);

					if (configKit == null)
						continue;

					implementers = xpath.evaluate("implementers", configKit);
					resIds = implementers.split("\\s+");

					for (int i = 0 ; i < resIds.length ; i += 1) {
						Node resNode = (Node)xpath.evaluate("//resource[ResourceID = '" + resIds[i] + "']", inputDoc, XPathConstants.NODE);
						Node kitNode = (Node)xpath.evaluate("kit[Name = '" + kitName + "' and Version = '" + kitVersion + "']", resNode, XPathConstants.NODE);
						NodeList swNodes = (NodeList)xpath.evaluate(element.expression, kitNode, XPathConstants.NODESET);

						if (swNodes.getLength() < 1) {
							removeIdFromKitResource(xpath, configKit, resIds[i]);

							changedConfig = true;

							System.err.println(resIds[i] + ": removed optional component " + element.resource);
						}
					}
				}
			}

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

			NodeList configResNodes = (NodeList)xpath.evaluate("/config/tgResources/resource", configDoc, XPathConstants.NODESET);

			for (int i = 0 ; i < configResNodes.getLength() ; i += 1) {
				Node configRes = configResNodes.item(i);
				NodeList macroResNodes = (NodeList)xpath.evaluate("macroResource", configRes, XPathConstants.NODESET);
				Node macroRes = macroResNodes.item(0);
				String shortNames = xpath.evaluate("name", macroRes);

				for (int j = 1 ; j < macroResNodes.getLength() ; j += 1) {
					macroRes = macroResNodes.item(j);

					shortNames += " " + xpath.evaluate("name", macroRes);
				}

				writeIncatResource(xpath, configRes, shortNames, false, builder);

				for (int j = 0 ; j < macroResNodes.getLength() ; j += 1) {
					macroRes = macroResNodes.item(j);

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

			configResNodes = (NodeList)xpath.evaluate("/config/kitResources/resource", configDoc, XPathConstants.NODESET);

			for (int i = 0 ; i < configResNodes.getLength() ; i += 1) {
				Node configRes = configResNodes.item(i);
				String implementers = xpath.evaluate("implementers", configRes);

				writeIncatResource(xpath, configRes, implementers, false, builder);
			}

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
	 * @param config
	 * @throws XPathExpressionException
	 * @throws IncaException
	 */
	private static void populateKitQueries(XPath xpath, Document config) throws XPathExpressionException, IncaException
	{
		NodeList kitNodes = (NodeList)xpath.evaluate("/config/queries/kit", config, XPathConstants.NODESET);

		for (int i = 0 ; i < kitNodes.getLength() ; i += 1) {
			Node kit = kitNodes.item(i);
			String kitKey = xpath.evaluate("resource", kit);

			if (kitKey == null || kitKey.length() < 1)
				throw new IncaException("Config kit resource name is empty");

			if (m_kitQueries.containsKey(kitKey))
				throw new IncaException("Config contains duplicate kits");

			NodeList swNodes = (NodeList)xpath.evaluate("software", kit, XPathConstants.NODESET);
			List<Software> swList = new ArrayList<Software>();

			for (int j = 0 ; j < swNodes.getLength() ; j += 1) {
				Node software = swNodes.item(j);
				String macro = xpath.evaluate("macro", software);
				String expression = xpath.evaluate("expression", software);
				String optional = xpath.evaluate("resource", software);

				if (macro != null && macro.length() < 1)
					macro = null;

				if (expression != null && expression.length() < 1)
					expression = null;

				if (optional != null && optional.length() < 1)
					optional = null;

				Software newSoftware = new Software(macro, expression, optional);

				swList.add(newSoftware);
			}

			m_kitQueries.put(kitKey, swList);
		}
	}

	/**
	 *
	 * @param xpath
	 * @param resource
	 * @return
	 * @throws XPathExpressionException
	 */
	private static boolean hasTestedSoftware(XPath xpath, Node resource) throws XPathExpressionException
	{
		NodeList kitNodes = (NodeList)xpath.evaluate("kit", resource, XPathConstants.NODESET);

		for (int j = 0 ; j < kitNodes.getLength() ; j += 1) {
			Node kit = kitNodes.item(j);
			String kitName = xpath.evaluate("Name", kit);
			String kitVersion = xpath.evaluate("Version", kit);
			String kitKey = kitName + "-" + kitVersion;
			List<Software> swList = m_kitQueries.get(kitKey);

			if (swList == null)
				continue;

			for (Software element : swList) {
				NodeList swNodes = (NodeList)xpath.evaluate(element.expression, kit, XPathConstants.NODESET);

				if (swNodes.getLength() > 0)
					return true;
			}
		}

		return false;
	}

	/**
	 *
	 * @param xpath
	 * @param kit
	 * @param id
	 * @return
	 * @throws XPathExpressionException
	 */
	private static boolean addIdToKitResource(XPath xpath, Node kit, String id) throws XPathExpressionException
	{
		Node implNode = (Node)xpath.evaluate("implementers", kit, XPathConstants.NODE);
		String text = implNode.getTextContent();

		if (text.matches(".*" + id + ".*"))
			return false;

		if (text.length() > 0)
			implNode.setTextContent(text + " " + id);
		else
			implNode.setTextContent(id);

		return true;
	}

	/**
	 *
	 * @param xpath
	 * @param kit
	 * @param id
	 * @throws XPathExpressionException
	 */
	private static void removeIdFromKitResource(XPath xpath, Node kit, String id) throws XPathExpressionException
	{
		Node implNode = (Node)xpath.evaluate("implementers", kit, XPathConstants.NODE);
		String text = implNode.getTextContent();

		text = text.replaceAll(id.replace(".", "\\.") + "\\s*", "").replaceAll("\\s+$", "");

		implNode.setTextContent(text);
	}

	/**
	 *
	 * @param xpath
	 * @param nodes
	 * @return
	 * @throws XPathExpressionException
	 */
	private static String findNewest(XPath xpath, NodeList nodes) throws XPathExpressionException
	{
		String result = xpath.evaluate("Version", nodes.item(0));
		String defaultText = xpath.evaluate("Default", nodes.item(0));
		boolean hasDefault = false;

		if (defaultText != null && defaultText.equalsIgnoreCase("yes"))
			hasDefault = true;

		for (int i = 1 ; i < nodes.getLength() ; i += 1) {
			String currentNode = xpath.evaluate("Version", nodes.item(i));

			defaultText = xpath.evaluate("Default", nodes.item(i));

			if (hasDefault) {
				if (defaultText == null || !defaultText.equalsIgnoreCase("yes"))
					continue;
			}
			else if (defaultText != null && defaultText.equalsIgnoreCase("yes")) {
				result = currentNode;
				hasDefault = true;

				continue;
			}

			String[] currentPieces = currentNode.split("\\.");
			String[] newestPieces = result.split("\\.");
			int offset = 0;

			while (true) {
				if (offset >= currentPieces.length)
					break;

				if (offset >= newestPieces.length) {
					result = currentNode;

					break;
				}

				try {
					int current = Integer.valueOf(currentPieces[offset]);
					int newest = Integer.valueOf(newestPieces[offset]);

					if (newest > current)
						break;

					if (current > newest) {
						result = currentNode;

						break;
					}
				}
				catch (NumberFormatException formatErr) {
					int comparison = currentPieces[offset].compareTo(newestPieces[offset]);

					if (comparison < 0)
						break;

					if (comparison > 0) {
						result = currentNode;

						break;
					}
				}

				offset += 1;
			}
		}

		return result;
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
		String newFileName;

		if (position >= 0)
			newFileName = fileName.substring(0, position) + "_" + timestamp + fileName.substring(position);
		else
			newFileName = fileName + "_" + timestamp;

		File newFile = new File(newFileName);

		if (!oldFile.renameTo(newFile))
			throw new IncaException("Can't rename " + fileName);
	}

	/**
	 *
	 * @param xpath
	 * @param configRes
	 * @param pattern
	 * @param equivalent
	 * @param builder
	 * @throws XPathExpressionException
	 */
	private static void writeIncatResource(XPath xpath, Node configRes, String pattern, boolean equivalent, StringBuilder builder) throws XPathExpressionException
	{
		String resName = xpath.evaluate("name", configRes);

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

		NodeList macroNodes = (NodeList)xpath.evaluate("macro", configRes, XPathConstants.NODESET);

		for (int i = 0 ; i < macroNodes.getLength() ; i += 1) {
			Node macro = macroNodes.item(i);
			String macroName = xpath.evaluate("name", macro);
			String macroValue = xpath.evaluate("value", macro);

			builder.append("<macro>");
			builder.append("<name>" + macroName + "</name>");
			builder.append("<value>");

			if (macroValue.matches(".*[&<>]+.*"))
				builder.append("<![CDATA[" + macroValue + "]]>");
			else
				builder.append(macroValue);

			builder.append("</value>");
			builder.append("</macro>");
		}

		builder.append("</macros>");
		builder.append("</resource>");
	}
}
