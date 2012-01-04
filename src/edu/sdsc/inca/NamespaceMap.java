/*
 * NamespaceMap.java
 */
package edu.sdsc.inca;


import java.util.Iterator;
import java.util.Map;
import java.util.TreeMap;

import javax.xml.namespace.NamespaceContext;


/**
 *
 * @author Paul Hoover
 *
 */
class NamespaceMap implements NamespaceContext {

	private final Map<String, String> m_namespaces = new TreeMap<String, String>();


	// public methods


	/**
	 *
	 * @param prefix
	 * @param uri
	 */
	public void addMapping(String prefix, String uri)
	{
		m_namespaces.put(prefix, uri);
	}

	/**
	 * @param prefix
	 * @return
	 */
	public String getNamespaceURI(String prefix)
	{
		return m_namespaces.get(prefix);
	}

	/**
	 * @param namespaceURI
	 * @return
	 */
	public String getPrefix(String namespaceURI)
	{
		return null;
	}

	/**
	 * @param namespaceURI
	 * @return
	 */
	public Iterator<String> getPrefixes(String namespaceURI)
	{
		return null;
	}
}
