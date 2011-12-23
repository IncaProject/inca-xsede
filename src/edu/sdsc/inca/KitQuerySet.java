/*
 * KitQuerySet.java
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
class KitQuerySet {

	private final String m_kitName;
	private final String m_kitVersion;
	private final String m_groupName;
	private final List<String> m_optionalGroups = new ArrayList<String>();
	private final List<KitQuery> m_queries = new ArrayList<KitQuery>();


	// constructors


	public KitQuerySet(XPath xpath, Node querySet) throws XPathExpressionException, IncaException
	{
		m_kitName = xpath.evaluate("name", querySet);
		m_kitVersion = xpath.evaluate("version", querySet);
		m_groupName = xpath.evaluate("group", querySet);

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
	 * @param inputKit
	 * @return
	 * @throws XPathExpressionException
	 */
	public boolean matches(XPath xpath, Node inputKit) throws XPathExpressionException
	{
		for (KitQuery query : m_queries) {
			if (query.matches(xpath, inputKit))
				return true;
		}

		return false;
	}

	/**
	 *
	 * @param xpath
	 * @param configDoc
	 * @param inputKit
	 * @param configRes
	 * @return
	 * @throws XPathExpressionException
	 * @throws IncaException
	 */
	public boolean evaluate(XPath xpath, Document configDoc, Node inputKit, Node configRes) throws XPathExpressionException, IncaException
	{
		Node configKit = (Node)xpath.evaluate("/config/groups/group[type = 'kit' and name = '" + m_groupName + "']", configDoc, XPathConstants.NODE);

		if (configKit == null)
			throw new IncaException("Couldn't find a corresponding group for kit " + m_kitName + ", version " + m_kitVersion);

		Node kitGroup = (Node)xpath.evaluate("group[type = 'kit' and name = '" + m_groupName + "']", configRes, XPathConstants.NODE);
		boolean changedConfig = false;

		if (kitGroup == null) {
			Node macroRes = (Node)xpath.evaluate("macroResource", configRes, XPathConstants.NODE);
			Node newGroup = configDoc.createElement("group");
			Node newType = configDoc.createElement("type");
			Node newName = configDoc.createElement("name");

			newType.setTextContent("kit");
			newName.setTextContent(m_groupName);
			newGroup.appendChild(newType);
			newGroup.appendChild(newName);
			configRes.insertBefore(newGroup, macroRes);

			changedConfig = true;

			String resId = xpath.evaluate("name", configRes);

			System.err.println(resId + ": added kit " + m_kitName + ", version " + m_kitVersion);
		}

		for (KitQuery query : m_queries) {
			if (query.evaluate(xpath, configDoc, inputKit, configKit, configRes))
				changedConfig = true;
		}

		return changedConfig;
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
	public boolean examineGroups(XPath xpath, Document configDoc, Node inputRes, Node configRes) throws XPathExpressionException
	{
		Node kitGroup = (Node)xpath.evaluate("group[type = 'kit' and name = '" + m_groupName + "']", configRes, XPathConstants.NODE);

		if (kitGroup == null)
			return false;

		Node inputKit = (Node)xpath.evaluate("kit[Name = '" + m_kitName + "' and Version = '" + m_kitVersion + "']", inputRes, XPathConstants.NODE);
		boolean removeKit = false;

		if (inputKit == null)
			removeKit = true;
		else {
			String supportLevel = xpath.evaluate("SupportLevel", inputKit);

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
}
