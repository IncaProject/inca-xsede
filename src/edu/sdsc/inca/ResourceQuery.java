/*
 * ResourceQuery.java
 */
package edu.sdsc.inca;


import java.util.ArrayList;
import java.util.List;

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
class ResourceQuery {

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
		 * @param configRes
		 * @return
		 * @throws XPathExpressionException
		 */
		public boolean evaluate(XPath xpath, NodeList result, Document configDoc, Node configRes) throws XPathExpressionException
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

			return evaluate(xpath, resultList, configDoc, configRes);
		}


		// protected methods


		/**
		 *
		 * @param xpath
		 * @param result
		 * @param configDoc
		 * @param configRes
		 * @return
		 * @throws XPathExpressionException
		 */
		protected abstract boolean evaluate(XPath xpath, List<Node> result, Document configDoc, Node configRes) throws XPathExpressionException;
	}

	/**
	 *
	 */
	private static class GroupProduct extends QueryProduct {

		private final String m_groupName;


		// constructors


		/**
		 *
		 * @param name
		 */
		public GroupProduct(String expression, String name)
		{
			super(expression);

			m_groupName = name;
		}


		// protected methods


		/**
		 *
		 * @param xpath
		 * @param result
		 * @param configDoc
		 * @param configRes
		 * @param id
		 * @return
		 * @throws XPathExpressionException
		 */
		protected boolean evaluate(XPath xpath, List<Node> result, Document configDoc, Node configRes) throws XPathExpressionException
		{
			Node group = (Node)xpath.evaluate("group[type = 'general' and name = '" + m_groupName + "']", configRes, XPathConstants.NODE);

			if (!result.isEmpty()) {
				if (group != null)
					return false;

				String resId = xpath.evaluate("name", configRes);
				Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);
				Node newGroup = configDoc.createElement("group");
				Node newType = configDoc.createElement("type");
				Node newName = configDoc.createElement("name");

				newType.setTextContent("general");
				newName.setTextContent(m_groupName);
				newGroup.appendChild(newType);
				newGroup.appendChild(newName);
				configRes.insertBefore(newGroup, macroRes);

				System.err.println(resId + ": added group " + m_groupName);

				return true;
			}
			else {
				if (group == null)
					return false;

				configRes.removeChild(group);

				String resId = xpath.evaluate("name", configRes);

				System.err.println(resId + ": removed group " + m_groupName);

				return true;
			}
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
	public ResourceQuery(XPath xpath, Node query) throws XPathExpressionException, IncaException
	{
		m_expression = xpath.evaluate("expression", query);

		if (m_expression.length() < 1)
			throw new IncaException("Resource query has no expression");

		NodeList productNodes = (NodeList)xpath.evaluate("products/*", query, XPathConstants.NODESET);

		for (int i = 0 ; i < productNodes.getLength() ; i += 1) {
			Node product = productNodes.item(i);
			String name = product.getNodeName();
			String expression = xpath.evaluate("expression", product);

			if (name.equals("group")) {
				String group = xpath.evaluate("group", product);

				m_products.add(new GroupProduct(expression, group));
			}
			else
				throw new IncaException("Unknown query product type " + name);
		}
	}


	// public methods


	/**
	 *
	 * @param xpath
	 * @param configDoc
	 * @param inputRes
	 * @param configRes
	 * @return
	 * @throws XPathExpressionException
	 */
	public boolean evaluate(XPath xpath, Document configDoc, Node inputRes, Node configRes) throws XPathExpressionException
	{
		NodeList resultNodes = (NodeList)xpath.evaluate(m_expression, inputRes, XPathConstants.NODESET);
		boolean changedConfig = false;

		for (QueryProduct product : m_products) {
			if (product.evaluate(xpath, resultNodes, configDoc, configRes))
				changedConfig = true;
		}

		return changedConfig;
	}
}
