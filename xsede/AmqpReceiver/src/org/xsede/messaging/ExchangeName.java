/*
 * Exchange.java
 */
package org.xsede.messaging;


import java.util.EnumSet;
import java.util.Map;
import java.util.TreeMap;


/**
 * An enumeration that represents the name of an exchange hosted by the FutureGrid AMQP server. The
 * AMQP protocol does not currently provide for any server management features, so there's no way to
 * determine what exchanges are available remotely
 *
 * @author Paul Hoover
 *
 */
public enum ExchangeName {

  GLUE2_ACTIVITIES("glue2.computing_activities"),
  GLUE2_ACTIVITY_UPDATES("glue2.computing_activity"),
  GLUE2_SYSTEMS("glue2.compute"),
  GLUE2_APPS("glue2.applications"),
  INCA("inca");


  // data fields


  private static final Map<String, ExchangeName> m_names = new TreeMap<String, ExchangeName>();
  private final String m_value;


  static {
    for (ExchangeName name : EnumSet.allOf(ExchangeName.class))
      m_names.put(name.toString(), name);
  }


  // constructors


  /**
   *
   * @param value
   */
  private ExchangeName(String value)
  {
    m_value = value;
  }


  // public methods


  @Override
  public String toString()
  {
    return m_value;
  }

  /**
   * Parses the provided exchange name and returns the <code>ExchangeName</code> equivalent. If no value of
   * the class matches the name, an <code>IllegalArgumentException</code> is thrown
   *
   * @param value the name of an exchange
   * @return the <code>ExchangeName</code> equivalent
   */
  public static ExchangeName parse(String value)
  {
    ExchangeName result = m_names.get(value);

    if (result == null)
      throw new IllegalArgumentException();

    return result;
  }
}
