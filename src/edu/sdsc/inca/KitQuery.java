/*
 * KitQuery.java
 */
package edu.sdsc.inca;


import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;

import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;


/**
 *
 * @author Paul Hoover
 *
 */
class KitQuery {

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

			Node newest = findNewest(xpath, result);
			String version = xpath.evaluate("Version", newest);
			String resId = xpath.evaluate("name", configRes);
			Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);

			return setMacroValue(xpath, configDoc, configKit, macroRes, resId, m_macroName, version);
		}
	}

	/**
	 *
	 */
	private static class URLProduct extends QueryProduct {

		private static final Pattern m_urlPattern = Pattern.compile("(?:[a-zA-Z]+://)?([a-zA-Z0-9\\-]+(?:\\.[a-zA-Z0-9\\-]+)*)(?::(\\d+))?(?:/[a-zA-Z0-9\\-\\.]*)*");
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
			String url = xpath.evaluate("Endpoint", result.get(0));
			Matcher matchResult = m_urlPattern.matcher(url);

			if (!matchResult.matches()) {
				System.err.println(resId + ": invalid URL: " + url);

				return false;
			}

			Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);
			boolean changedConfig = setMacroValue(xpath, configDoc, macroRes, resId, m_hostName, matchResult.group(1));

			if (setMacroValue(xpath, configDoc, configKit, macroRes, resId, m_portName, matchResult.group(2)))
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
			Node optional = (Node)xpath.evaluate("group[type = 'optional' and name = '" + m_optionalName + "']", configRes, XPathConstants.NODE);

			if (!result.isEmpty()) {
				if (optional != null)
					return false;

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

				System.err.println(resId + ": added optional component " + m_optionalName);

				return true;
			}
			else {
				if (optional == null)
					return false;

				configRes.removeChild(optional);

				String resId = xpath.evaluate("name", configRes);

				System.err.println(resId + ": removed optional component " + m_optionalName);

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
			String defaultText = xpath.evaluate("Default", newest);
			String key;

			if (defaultText.equalsIgnoreCase("yes"))
				key = "";
			else {
				String keyText = xpath.evaluate("HandleKey", newest);

				if (keyText.length() < 1 || keyText.equalsIgnoreCase("None"))
					key = "";
				else
					key = "@keyPre@ " + keyText + " @keyPost@";
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

			String endpoint = xpath.evaluate("Endpoint", result.get(0));
			String resId = xpath.evaluate("name", configRes);
			Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);

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
			else
				throw new IncaException("Unknown query product type " + name);
		}
	}


	// public methods


	/**
	 *
	 * @param xpath
	 * @param inputKit
	 * @return
	 * @throws XPathExpressionException
	 */
	public boolean matches(XPath xpath, Node inputKit) throws XPathExpressionException
	{
		NodeList resultNodes = (NodeList)xpath.evaluate(m_expression, inputKit, XPathConstants.NODESET);

		return resultNodes.getLength() > 0;
	}

	/**
	 *
	 * @param xpath
	 * @param configDoc
	 * @param inputKit
	 * @param configKit
	 * @param configRes
	 * @return
	 * @throws XPathExpressionException
	 */
	public boolean evaluate(XPath xpath, Document configDoc, Node inputKit, Node configKit, Node configRes) throws XPathExpressionException
	{
		NodeList resultNodes = (NodeList)xpath.evaluate(m_expression, inputKit, XPathConstants.NODESET);
		boolean changedConfig = false;

		for (QueryProduct product : m_products) {
			if (product.evaluate(xpath, resultNodes, configDoc, configKit, configRes))
				changedConfig = true;
		}

		return changedConfig;
	}


	// private methods


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
		String resultText = xpath.evaluate("Version", resultNode);
		String defaultText = xpath.evaluate("Default", resultNode);
		boolean hasDefault = false;

		if (defaultText.equalsIgnoreCase("yes"))
			hasDefault = true;

		while (elements.hasNext()) {
			Node currentNode = elements.next();
			String currentText = xpath.evaluate("Version", currentNode);

			defaultText = xpath.evaluate("Default", currentNode);

			if (hasDefault) {
				if (!defaultText.equalsIgnoreCase("yes"))
					continue;
			}
			else if (defaultText.equalsIgnoreCase("yes")) {
				resultNode = currentNode;
				resultText = currentText;
				hasDefault = true;

				continue;
			}

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

	/**
	 *
	 * @param xpath
	 * @param config
	 * @param kit
	 * @param resource
	 * @param id
	 * @param name
	 * @param value
	 * @return
	 * @throws XPathExpressionException
	 */
	private static boolean setMacroValue(XPath xpath, Document config, Node kit, Node resource, String id, String name, String value) throws XPathExpressionException
	{
		Node defaultValue = (Node)xpath.evaluate("macro[name = '" + name + "']/value", kit, XPathConstants.NODE);

		if (defaultValue != null && defaultValue.getTextContent().equals(value))
			return false;

		return setMacroValue(xpath, config, resource, id, name, value);
	}

	/**
	 *
	 * @param xpath
	 * @param config
	 * @param resource
	 * @param id
	 * @param name
	 * @param value
	 * @return
	 * @throws XPathExpressionException
	 */
	private static boolean setMacroValue(XPath xpath, Document config, Node resource, String id, String name, String value) throws XPathExpressionException
	{
		Node macro = (Node)xpath.evaluate("macro[name = '" + name + "']", resource, XPathConstants.NODE);

		if (macro == null) {
			Node newMacro = config.createElement("macro");
			Node newChild = config.createElement("type");

			newChild.setTextContent("variable");
			newMacro.appendChild(newChild);

			newChild = config.createElement("name");

			newChild.setTextContent(name);
			newMacro.appendChild(newChild);

			newChild = config.createElement("value");

			newChild.setTextContent(value);
			newMacro.appendChild(newChild);
			resource.appendChild(newMacro);

			System.err.println(id + ": added macro " + name);

			return true;
		}
		else {
			String macroType = xpath.evaluate("type", macro);

			if (!macroType.equals("constant")) {
				Node macroValue = (Node)xpath.evaluate("value", macro, XPathConstants.NODE);
				String currentValue = macroValue.getTextContent();

				if (!currentValue.equals(value)) {
					macroValue.setTextContent(value);

					System.err.println(id + ": changed value of macro " + name + " from " + currentValue + " to " + value);

					return true;
				}
			}
		}

		return false;
	}
}
