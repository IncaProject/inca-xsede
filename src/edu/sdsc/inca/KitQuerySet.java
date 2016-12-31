/*
 * KitQuerySet.java
 */
package edu.sdsc.inca;


import java.util.ArrayList;
import java.util.List;

import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;

import org.apache.log4j.Logger;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;


/**
 *
 * @author Paul Hoover
 *
 */
class KitQuerySet {

	private final String m_kitName;
	private final String m_kitVersion;
	private final String m_groupName;
	private final String m_expression;
	private final List<String> m_optionalGroups = new ArrayList<String>();
	private final List<KitQuery> m_queries = new ArrayList<KitQuery>();
	private static final Logger m_logger = Logger.getLogger(KitQuerySet.class);


	// constructors


	/**
	 *
	 * @param xpath
	 * @param querySet
	 * @throws XPathExpressionException
	 * @throws IncaException
	 */
	public KitQuerySet(XPath xpath, Node querySet) throws XPathExpressionException, IncaException
	{
		m_kitName = xpath.evaluate("name", querySet);
		m_kitVersion = xpath.evaluate("version", querySet);
		m_groupName = xpath.evaluate("group", querySet);
		m_expression = xpath.evaluate("expression", querySet);

		NodeList nodes = (NodeList)xpath.evaluate("query/products/optional/group", querySet, XPathConstants.NODESET);

		for (int i = 0 ; i < nodes.getLength() ; i += 1)
			m_optionalGroups.add(nodes.item(i).getTextContent());

		nodes = (NodeList)xpath.evaluate("query", querySet, XPathConstants.NODESET);

		for (int i = 0 ; i < nodes.getLength() ; i += 1) {
			Node query = nodes.item(i);

			m_queries.add(new KitQuery(xpath, query));
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
		if (m_expression.length() > 0) {
			NodeList resultNodes = (NodeList)xpath.evaluate(m_expression, inputRes, XPathConstants.NODESET);

			if (resultNodes.getLength() < 1)
				return false;
		}

		for (KitQuery query : m_queries) {
			if (query.matches(xpath, inputRes))
				return true;
		}

		return false;
	}

	/**
	 *
	 * @param xpath
	 * @param configDoc
	 * @param inputRes
	 * @param configRes
	 * @return
	 * @throws XPathExpressionException
	 * @throws IncaException
	 */
	public boolean evaluate(XPath xpath, Document configDoc, Node inputRes, Node configRes) throws XPathExpressionException, IncaException
	{
		Node configKit = (Node)xpath.evaluate("/config/groups/group[type = 'kit' and name = '" + m_groupName + "']", configDoc, XPathConstants.NODE);

		if (configKit == null)
			throw new IncaException("Couldn't find a corresponding group for kit " + m_kitName + ", version " + m_kitVersion);

		Node kitGroup = (Node)xpath.evaluate("group[type = 'kit' and name = '" + m_groupName + "']", configRes, XPathConstants.NODE);
		boolean changedConfig = false;

		if (kitGroup == null) {
			Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);
			kitGroup = configDoc.createElement("group");
			Node newType = configDoc.createElement("type");
			Node newName = configDoc.createElement("name");

			newType.setTextContent("kit");
			newName.setTextContent(m_groupName);
			kitGroup.appendChild(newType);
			kitGroup.appendChild(newName);

			configRes.insertBefore(kitGroup, macroRes);

			changedConfig = true;

			String resId = xpath.evaluate("name", configRes);

			m_logger.info(resId + ": added kit " + m_kitName + ", version " + m_kitVersion);
		}

		for (KitQuery query : m_queries) {
				m_logger.debug("KitQuery: " + query.toString());
				if (query.evaluate(xpath, configDoc, inputRes, kitGroup, configRes))
					changedConfig = true;

		}

		return changedConfig;
	}

	public String toString() {
		return "Kit: " + this.m_kitName + " v " + this.m_kitVersion + ", group = " + m_groupName + "\n" +
				"  expression = '" + m_expression + "', " +
				"  optional groups count = " + m_optionalGroups.size() + ", " +
				"  queries groups count = " + m_queries.size();
	}

	/**
	 *
	 * @param xpath
	 * @param configDoc
	 * @param inputRes
	 * @param configRes
	 * @return
	 * @throws XPathExpressionException
	 */
	/*
	public boolean examineGroups(XPath xpath, Document configDoc, Node inputRes, Node configRes) throws XPathExpressionException
	{
		Node kitGroup = (Node)xpath.evaluate("group[type = 'kit' and name = '" + m_groupName + "']", configRes, XPathConstants.NODE);

		if (kitGroup == null)
			return false;

		Node inputKit = (Node)xpath.evaluate("tg:Kit[tg:Name = '" + m_kitName + "' and tg:Version = '" + m_kitVersion + "']", inputRes, XPathConstants.NODE);
		boolean removeKit = false;

		if (inputKit == null)
			removeKit = true;
		else {
			String supportLevel = xpath.evaluate("tg:SupportLevel", inputKit);

			if (supportLevel.equals("retired"))
				removeKit = true;
		}

		if (!removeKit)
			return false;

		configRes.removeChild(kitGroup);

		for (String optional : m_optionalGroups) {
			Node optionalGroup = (Node)xpath.evaluate("group[type = 'optional' and name = '" + optional + "']", configRes, XPathConstants.NODE);

			if (optionalGroup != null)
				configRes.removeChild(optionalGroup);
		}

		String resId = xpath.evaluate("name", configRes);

		System.err.println(resId + ": removed kit " + m_kitName + ", version " + m_kitVersion);

		return true;
	}
	*/
}
