/*
 * CreateInputDocument.java
 */
package edu.sdsc.inca;


import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.StringReader;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import javax.json.Json;
import javax.json.JsonArray;
import javax.json.JsonObject;
import javax.json.JsonReader;
import javax.json.JsonValue;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.apache.log4j.Logger;
import org.w3c.dom.Document;
import org.w3c.dom.ls.DOMImplementationLS;
import org.w3c.dom.ls.LSOutput;
import org.w3c.dom.ls.LSSerializer;
import org.xml.sax.InputSource;


/**
 *
 * @author Paul Hoover
 *
 */
public class CreateInputDocument {

	// public methods
	private static final Logger m_logger = Logger.getLogger(CreateInputDocument.class);



	/**
	 *
	 * @param args
	 */
	public static void main(String[] args)
	{
		try {
			if (args.length < 2 || args.length > 3)
				throw new IncaException("usage: CreateInputDocument services software [ output ]");

			Map<String, List<JsonObject>> services = readObjects(args[0]);
			Map<String, List<JsonObject>> software = readObjects(args[1]);
			StringBuilder builder = new StringBuilder();

			builder.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
			builder.append("<Resources>");

			for (Map.Entry<String, List<JsonObject>> entry : services.entrySet()) {
				String resourceId = entry.getKey();

				builder.append("<Resource>");
				builder.append("<ResourceID>" + resourceId + "</ResourceID>");

				List<JsonObject> servList = entry.getValue();

				for (JsonObject serv : servList) {
					builder.append("<Service>");

					writeValues(serv, builder);

					builder.append("</Service>");
				}

				List<JsonObject> softList = software.get(resourceId);

				if (softList != null) {
					for (JsonObject soft : softList) {
						builder.append("<Software>");

						writeValues(soft, builder);

						builder.append("</Software>");
					}
				}

				builder.append("</Resource>");
			}

			for (Map.Entry<String, List<JsonObject>> entry : software.entrySet()) {
				String resourceId = entry.getKey();

				if (!services.containsKey(resourceId)) {
					builder.append("<Resource>");
					builder.append("<ResourceID>" + resourceId + "</ResourceID>");

					List<JsonObject> softList = entry.getValue();

					for (JsonObject soft : softList) {
						builder.append("<Software>");

						writeValues(soft, builder);

						builder.append("</Software>");
					}

					builder.append("</Resource>");
				}
			}

			builder.append("</Resources>");

			InputSource source = new InputSource(new StringReader(builder.toString()));
			DocumentBuilder docBuilder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
			Document outputDoc = docBuilder.parse(source);
			DOMImplementationLS lsImpl = (DOMImplementationLS)outputDoc.getImplementation().getFeature("LS", "3.0");
			LSSerializer lsSerializer = lsImpl.createLSSerializer();
			LSOutput lsOutput = lsImpl.createLSOutput();

			lsOutput.setEncoding("UTF-8");
			lsSerializer.getDomConfig().setParameter("format-pretty-print", Boolean.TRUE);

			Writer outStream = args.length < 3 ? new OutputStreamWriter(System.out) : new FileWriter(args[2]);

			lsOutput.setCharacterStream(outStream);
			lsSerializer.write(outputDoc, lsOutput);
		}
		catch (Exception err) {
			m_logger.error("Problem reading input", err);

			System.exit(-1);
		}
	}


	// private methods


	/**
	 *
	 * @param fileName
	 * @return
	 * @throws IOException
	 * @throws IncaException
	 */
	private static Map<String, List<JsonObject>> readObjects(String fileName) throws IOException, IncaException
	{
		Map<String, List<JsonObject>> result = new TreeMap<String, List<JsonObject>>();
		JsonReader reader = Json.createReader(new FileReader(fileName));

  	try {
  		JsonArray elements = reader.readArray();

  		for (JsonValue val : elements) {
  			if (val.getValueType() != JsonValue.ValueType.OBJECT)
  				throw new IncaException("expected OBJECT, found " + val.getValueType().toString());

  			JsonObject obj = (JsonObject)val;

  			if (!obj.containsKey("ResourceID"))
  				throw new IncaException("couldn't find ResourceID field");

  			String key = obj.getString("ResourceID");

  			List<JsonObject> objList = result.get(key);

  			if (objList == null) {
  				objList = new ArrayList<JsonObject>();

  				result.put(key, objList);
  			}

  			objList.add(obj);
  		}
  	}
  	finally {
  		reader.close();
  	}

  	return result;
	}

	/**
	 *
	 * @param obj
	 * @param builder
	 */
	private static void writeValues(JsonObject obj, StringBuilder builder)
	{
		for (Map.Entry<String, JsonValue> entry : obj.entrySet()) {
			String name = entry.getKey();
			JsonValue value = entry.getValue();

			builder.append("<");
			builder.append(name);
			builder.append(">");

			if (value != JsonValue.NULL) {
				String text = value.toString();

				text = text.substring(1, text.length() - 1);

				if (text.matches(".*[&<>]+.*"))
					builder.append("<![CDATA[" + text + "]]>");
				else
					builder.append(text);
			}

			builder.append("</");
			builder.append(name);
			builder.append(">");
		}
	}
}
