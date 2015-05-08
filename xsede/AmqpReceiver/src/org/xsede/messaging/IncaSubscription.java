/*
 * IncaSubscription.java
 */
package org.xsede.messaging;


import java.io.IOException;

import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;


/**
 * A specialization of <code>AmqpSubscription</code> that simplifies working with the Inca exchange
 *
 * @author Paul Hoover
 *
 */
public class IncaSubscription extends AmqpSubscription {

  // constructors


  /**
   *
   * @param factory
   * @throws IOException
   */
  public IncaSubscription(ConnectionFactory factory) throws IOException
  {
    super(factory);
  }

  /**
   *
   * @param connection
   * @throws IOException
   */
  public IncaSubscription(Connection connection) throws IOException
  {
    super(connection);
  }


  // public methods


  /**
   * Subscribes to messages related to a particular Inca resource
   *
   * @param resource the name of a resource
   * @throws IOException
   */
  public void subscribeToResource(String resource) throws IOException
  {
    String filter = "*.*.*." + resource + ".#";

    subscribe(filter);
  }

  /**
   * Subscribes to messages related to a particular Inca service
   *
   * @param service the name of a service
   * @throws IOException
   */
  public void subscribeToService(String service) throws IOException
  {
    String filter = "*.*." + service + ".#";

    subscribe(filter);
  }

  /**
   * Subscribes to messages related to a particular Inca test
   *
   * @param test the name of a test
   * @throws IOException
   */
  public void subscribeToTest(String test) throws IOException
  {
    String filter = "*." + test + ".#";

    subscribe(filter);
  }

  /**
   * Subscribes to all messages published by the Inca exchange
   *
   * @throws IOException
   */
  public void subscribeToAll() throws IOException
  {
    subscribe("#");
  }


  // private methods


  /**
   *
   * @param filter
   * @throws IOException
   */
  private void subscribe(String filter) throws IOException
  {
    subscribe(ExchangeName.INCA, filter);
  }
}
