/*
 * UpdateIncat.java
 */
package edu.sdsc.inca;


import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.ArrayList;
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


	private static final Map<String, List<Software>> m_kits = new TreeMap<String, List<Software>>();


	// public methods


	/**
	 *
	 * @param args
	 */
	public static void main(String[] args)
	{
		try {
			if (args.length < 3 || args.length > 4)
				throw new Exception("usage: UpdateIncat config incat input [ output ]");

			DocumentBuilder docBuilder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
			XPath xpath = XPathFactory.newInstance().newXPath();
			Document configDoc = docBuilder.parse(new FileInputStream(args[0]));

			populateKits(xpath, configDoc);

			Document incatDoc = docBuilder.parse(new FileInputStream(args[1]));
			Document inputDoc = docBuilder.parse(new FileInputStream(args[2]));
			NodeList resNodes = (NodeList)xpath.evaluate("//resource", inputDoc, XPathConstants.NODESET);

			for (int i = 0 ; i < resNodes.getLength() ; i += 1) {
				Node resource = resNodes.item(i);
				String resId = xpath.evaluate("ResourceID", resource);
				Node incatRes = (Node)xpath.evaluate("//resourceConfig/resources/resource[name = '" + resId + "']", incatDoc, XPathConstants.NODE);

				if (incatRes == null) {
					if (hasTestedSoftware(xpath, resource))
						System.err.println(resId + ": has applicable kits, but is not present in incat");

					continue;
				}

				NodeList kitNodes = (NodeList)xpath.evaluate("kit", resource, XPathConstants.NODESET);

				for (int j = 0 ; j < kitNodes.getLength() ; j += 1) {
					Node kit = kitNodes.item(j);
					String kitName = xpath.evaluate("Name", kit);
					String kitVersion = xpath.evaluate("Version", kit);
					String kitKey = kitName + "-" + kitVersion;
					List<Software> swList = m_kits.get(kitKey);

					if (swList == null) {
						System.err.println(resId + ": couldn't find a corresponding software entry for kit " + kitName + ", version " + kitVersion);

						continue;
					}

					Node incatKit = (Node)xpath.evaluate("//resourceConfig/resources/resource[name = '" + kitKey + "']", incatDoc, XPathConstants.NODE);

					if (incatKit == null) {
						System.err.println(resId + ": couldn't find a corresponding incat resource for kit " + kitName + ", version " + kitVersion);

						continue;
					}

					String kitXpath = xpath.evaluate("xpath[matches(., '.+" + resId.replace(".", "\\\\.") + ".+')]", incatKit);

					if (kitXpath == null || kitXpath.length() < 1) {
						addIdToResource(xpath, incatKit, resId);

						System.err.println(resId + ": added kit " + kitKey);
					}

					for (Software element : swList) {
						NodeList swNodes = (NodeList)xpath.evaluate(element.expression, kit, XPathConstants.NODESET);

						if (swNodes.getLength() > 0) {
							if (element.macro != null) {
								String newest = findNewest(xpath, swNodes);
								Node defaultValue = (Node)xpath.evaluate("macros/macro[name = '" + element.macro + "']/value", incatKit, XPathConstants.NODE);

								if (defaultValue == null || !defaultValue.getTextContent().equals(newest)) {
									String resXpath = xpath.evaluate("xpath", incatRes);
									Node macroRes = (Node)xpath.evaluate(resXpath, incatDoc, XPathConstants.NODE);
									Node macroValue = (Node)xpath.evaluate("macros/macro[name = '" + element.macro + "']/value", macroRes, XPathConstants.NODE);

									if (macroValue == null) {
										Node newMacro = incatDoc.createElement("macro");
										Node newChild = incatDoc.createElement("name");

										newChild.setTextContent(element.macro);
										newMacro.appendChild(newChild);

										newChild = incatDoc.createElement("value");

										newChild.setTextContent(newest);
										newMacro.appendChild(newChild);

										Node macrosNode = (Node)xpath.evaluate("macros", macroRes, XPathConstants.NODE);

										macrosNode.appendChild(newMacro);

										System.err.println(resId + ": added macro " + element.macro);
									}
									else {
										String macroText = macroValue.getTextContent();

										if (!macroText.equals(newest)) {
											macroValue.setTextContent(newest);

											System.err.println(resId + ": changed value of macro " + element.macro + " from " + macroText + " to " + newest);
										}
									}
								}
							}

							if (element.resource != null) {
								Node optionalKit = (Node)xpath.evaluate("//resourceConfig/resources/resource[name = '" + element.resource + "']", incatDoc, XPathConstants.NODE);
								String optionalXpath = xpath.evaluate("xpath[matches(., '.+" + resId.replace(".", "\\\\.") + ".+')]", optionalKit);

								if (optionalXpath == null || optionalXpath.length() < 1) {
									addIdToResource(xpath, optionalKit, resId);

									System.err.println(resId + ": added optional component " + element.resource);
								}
							}
						}
					}
				}
			}

			for (Map.Entry<String, List<Software>> entry : m_kits.entrySet()) {
				String kitKey = entry.getKey();
				Node incatKit = (Node)xpath.evaluate("//resourceConfig/resources/resource[name = '" + kitKey + "']", incatDoc, XPathConstants.NODE);

				if (incatKit == null)
					continue;

				int separator = kitKey.lastIndexOf("-");
				String kitName = kitKey.substring(0, separator);
				String kitVersion = kitKey.substring(separator + 1, kitKey.length());
				String regexp = xpath.evaluate("macros/macro[name = '__regexp__']/value", incatKit);
				String[] resIds = regexp.split("\\s+");

				for (int i = 0 ; i < resIds.length ; i += 1) {
					Node resNode = (Node)xpath.evaluate("//resource[ResourceID = '" + resIds[i] + "']", inputDoc, XPathConstants.NODE);

					if (resNode == null) {
						NodeList nodes = (NodeList)xpath.evaluate("//resourceConfig/resources/resource[matches(xpath, '.+" + resIds[i].replace(".", "\\\\.") + ".+')]", incatDoc, XPathConstants.NODESET);

						for (int j = 0 ; j < nodes.getLength() ; j += 1)
							removeIdFromResource(xpath, nodes.item(j), resIds[i], incatDoc);

						Node incatRes = (Node)xpath.evaluate("//resourceConfig/resources/resource[name = '" + resIds[i] + "']", incatDoc, XPathConstants.NODE);
						String resXpath = xpath.evaluate("xpath", incatRes);
						NodeList macroNodes = (NodeList)xpath.evaluate(resXpath, incatDoc, XPathConstants.NODESET);

						for (int j = 0 ; j < macroNodes.getLength() ; j += 1) {
							Node macroNode = macroNodes.item(j);

							resXpath = xpath.evaluate("xpath", macroNode);
							nodes = (NodeList)xpath.evaluate(resXpath, incatDoc, XPathConstants.NODESET);

							for (int k = 0 ; k < nodes.getLength() ; k += 1) {
								Node host = nodes.item(k);

								host.getParentNode().removeChild(host);
							}

							macroNode.getParentNode().removeChild(macroNode);
						}

						incatRes.getParentNode().removeChild(incatRes);

						System.err.println(resIds[i] + ": removed resource");

						continue;
					}

					Node kitNode = (Node)xpath.evaluate("kit[Name = '" + kitName + "' and Version = '" + kitVersion + "']", resNode, XPathConstants.NODE);

					if (kitNode == null) {
						removeIdFromResource(xpath, incatKit, resIds[i], incatDoc);

						System.err.println(resIds[i] + ": removed kit " + kitKey);
					}
				}

				for (Software element : entry.getValue()) {
					if (element.resource == null)
						continue;

					incatKit = (Node)xpath.evaluate("//resourceConfig/resources/resource[name = '" + element.resource + "']", incatDoc, XPathConstants.NODE);

					if (incatKit == null)
						continue;

					regexp = xpath.evaluate("macros/macro[name = '__regexp__']/value", incatKit);
					resIds = regexp.split("\\s+");

					for (int i = 0 ; i < resIds.length ; i += 1) {
						Node resNode = (Node)xpath.evaluate("//resource[ResourceID = '" + resIds[i] + "']", inputDoc, XPathConstants.NODE);
						Node kitNode = (Node)xpath.evaluate("kit[Name = '" + kitName + "' and Version = '" + kitVersion + "']", resNode, XPathConstants.NODE);
						NodeList swNodes = (NodeList)xpath.evaluate(element.expression, kitNode, XPathConstants.NODESET);

						if (swNodes.getLength() < 1) {
							removeIdFromResource(xpath, incatKit, resIds[i], incatDoc);

							System.err.println(resIds[i] + ": removed optional component " + element.resource);
						}
					}
				}
			}

			DOMImplementationLS domLS = (DOMImplementationLS)incatDoc.getImplementation().getFeature("LS", "3.0");
			LSSerializer serializer = domLS.createLSSerializer();
			LSOutput output = domLS.createLSOutput();
			Writer stream = args.length < 4 ? new OutputStreamWriter(System.out) : new FileWriter(args[3]);

			output.setEncoding("UTF-8");
			output.setCharacterStream(stream);
			serializer.getDomConfig().setParameter("format-pretty-print", Boolean.TRUE);
			serializer.write(incatDoc, output);
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
	private static void populateKits(XPath xpath, Document config) throws XPathExpressionException, IncaException
	{
		NodeList kitNodes = (NodeList)xpath.evaluate("/kits/kit", config, XPathConstants.NODESET);

		for (int i = 0 ; i < kitNodes.getLength() ; i += 1) {
			Node kit = kitNodes.item(i);
			String kitKey = xpath.evaluate("resource", kit);

			if (kitKey == null || kitKey.length() < 1)
				throw new IncaException("Config kit resource name is empty");

			if (m_kits.containsKey(kitKey))
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

			m_kits.put(kitKey, swList);
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
			List<Software> swList = m_kits.get(kitKey);

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
	 * @param resource
	 * @param id
	 * @throws XPathExpressionException
	 */
	private static void addIdToResource(XPath xpath, Node resource, String id) throws XPathExpressionException
	{
		Node node = (Node)xpath.evaluate("xpath", resource, XPathConstants.NODE);
		String text = node.getTextContent();
		String expression = text.substring(0, text.length() - 5);

		node.setTextContent(expression + "|" + id.replace(".", "\\.") + ")$')]");

		node = (Node)xpath.evaluate("macros/macro[name = '__regexp__']/value", resource, XPathConstants.NODE);
		text = node.getTextContent();

		node.setTextContent(text + " " + id);
	}

	/**
	 *
	 * @param xpath
	 * @param resource
	 * @param id
	 * @param incat
	 * @throws XPathExpressionException
	 */
	private static void removeIdFromResource(XPath xpath, Node resource, String id, Document incat) throws XPathExpressionException
	{
		Node node = (Node)xpath.evaluate("xpath", resource, XPathConstants.NODE);
		String text = node.getTextContent();

		text = text.replaceAll(id.replace("\\.", "\\\\.") + "\\|?", "").replace("|)", ")");

		node.setTextContent(text);

		node = (Node)xpath.evaluate("macros/macro[name = '__regexp__']/value", resource, XPathConstants.NODE);
		text = node.getTextContent();
		text = text.replaceAll(id + "(:?\\s|\\|)*", "").replaceAll("(:?\\s|\\|)+$", "");

		node.setTextContent(text);
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
}
