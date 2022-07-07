/*
 * AmqpSubscription.java
 */
package org.xsede.messaging;


import java.io.IOException;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.Consumer;
import com.rabbitmq.client.Envelope;
import com.rabbitmq.client.ShutdownSignalException;
import com.rabbitmq.client.AMQP.BasicProperties;


/**
 * A class that retrieves messages published by an AMQP server. The set of messages to retrieve is
 * determined by subscriptions, which are defined as the combination of an exchange and a routing
 * key. An instance of an <code>AmqpSubscription</code> may have any number of subscriptions.
 *
 * @author Paul Hoover
 *
 */
public class AmqpSubscription {

  // nested classes


  /**
   * A representation of a discrete message received from the AMQP server
   */
  public static class Message {

    // data fields


    private final Envelope m_envelope;
    private final BasicProperties m_properties;
    private final String m_body;


    // constructors


    /**
     *
     * @param envelope
     * @param properties
     * @param body
     */
    private Message(Envelope envelope, BasicProperties properties, String body)
    {
      m_envelope = envelope;
      m_properties = properties;
      m_body = body;
    }


    // public methods


    /**
     * Provides access to the <code>Envelope</code> object for the message
     *
     * @return the <code>Envelope</code> object
     */
    public Envelope getEnvelope()
    {
      return m_envelope;
    }

    /**
     * Provides access to the <code>BasicProperties</code> object for the message
     *
     * @return the <code>BasicProperties</code> object
     */
    public BasicProperties getProperties()
    {
      return m_properties;
    }

    /**
     * Provides access to the body of the message
     *
     * @return the message body
     */
    public String getBody()
    {
      return m_body;
    }
  }


  /**
   *
   */
  private class SubscriptionConsumer implements Consumer {

    // public methods


    @Override
    public void handleCancel(String consumerTag) throws IOException
    {
      m_messages.add(CLOSED);
    }

    @Override
    public void handleCancelOk(String consumerTag)
    {
      m_messages.add(CLOSED);
    }

    @Override
    public void handleConsumeOk(String consumerTag)
    {

    }

    @Override
    public void handleDelivery(String consumerTag, Envelope envelope, BasicProperties properties, byte[] body) throws IOException
    {
      if (m_shutdown != null)
        throw m_shutdown;

      m_messages.add(new Message(envelope, properties, new String(body)));
    }

    @Override
    public void handleRecoverOk(String consumerTag)
    {

    }

    @Override
    public void handleShutdownSignal(String consumerTag, ShutdownSignalException sig)
    {
      m_shutdown = sig;

      m_messages.add(CLOSED);
    }
  }


  // data fields


  private static final Message CLOSED = new Message(null, null, null);

  private final boolean m_connectionOwner;
  private final Connection m_connection;
  private final Channel m_channel;
  private final String m_queueName;
  private final BlockingQueue<Message> m_messages = new LinkedBlockingQueue<Message>();
  private volatile ShutdownSignalException m_shutdown;


  // constructors


  /**
   * Uses the provided <code>ConnectionFactory</code> to create a <code>Connection</code> and
   * <code>Channel</code> for receiving deliveries from the AMQP server. The <code>Connection</code>
   * is owned by the <code>AmqpSubscription</code> object, and will be closed when the object is closed
   *
   * @param factory a <code>ConnectionFactory</code>
   * @throws IOException
   */
  public AmqpSubscription(ConnectionFactory factory) throws IOException
  {
    this(factory.newConnection(), true);
  }

  /**
   * Uses the provided <code>Connection</code> to create a <code>Channel</code> for receiving deliveries
   * from the AMQP server. The <code>Connection</code> is not owned by the <code>AmqpSubscription</code>
   * object, and will not be closed when the object is closed
   *
   * @param connection a <code>Connection</code>
   * @throws IOException
   */
  public AmqpSubscription(Connection connection) throws IOException
  {
    this(connection, false);
  }

  /**
   *
   * @param connection
   * @param owner
   * @throws IOException
   */
  private AmqpSubscription(Connection connection, boolean owner) throws IOException
  {
    m_connectionOwner = owner;
    m_connection = connection;
    m_channel = m_connection.createChannel();
    m_queueName = m_channel.queueDeclare().getQueue();

    m_channel.basicConsume(m_queueName, true, new SubscriptionConsumer());
  }


  // public methods


  /**
   * Provides access to the <code>Connection</code> used by the instance
   *
   * @return a <code>Connection</code>
   */
  public Connection getConnection()
  {
    return m_connection;
  }

  /**
   * Provides access to the <code>Channel</code> used by the instance
   *
   * @return a <code>Channel</code>
   */
  public Channel getChannel()
  {
    return m_channel;
  }

  /**
   * Subscribes to all messages published by a particular exchange
   *
   * @param exchange the name of an exchange
   * @throws IOException
   */
  public void subscribe(ExchangeName exchange) throws IOException
  {
    subscribe(exchange, "#");
  }

  /**
   * Subscribes to a subset of messages published by a particular exchange, as defined by the
   * routing key provided
   *
   * @param exchange the name of an exchange
   * @param filter a routing key
   * @throws IOException
   */
  public void subscribe(ExchangeName exchange, String filter) throws IOException
  {
    m_channel.queueBind(m_queueName, exchange.toString(), filter);
  }

  /**
   * Releases any resources owned by the instance
   *
   * @throws IOException
   */
  public void close() throws IOException
  {
    if (m_channel.isOpen())
      m_channel.close();

    if (m_connectionOwner && m_connection.isOpen())
      m_connection.close();
  }

  /**
   * Returns a message received from the server, encapsulated in a <code>Message</code> object. If
   * no messages are available, the method blocks until one is
   *
   * @return the <code>Message</code>, or <code>null</code> if the connections is closed
   * @throws InterruptedException
   * @throws ShutdownSignalException
   */
  public Message nextMessage() throws InterruptedException, ShutdownSignalException
  {
    return nextMessage(m_messages.take());
  }

  /**
   * Returns a message received from the server, encapsulated in a <code>Message</code> object. If
   * no messages are available, the method blocks until either a message is available or the timeout
   * period has been exceeded
   *
   * @param timeout the timeout period, in milliseconds
   * @return the <code>Message</code>, or <code>null</code> if the connections is closed
   * @throws InterruptedException
   * @throws ShutdownSignalException
   */
  public Message nextMessage(int timeout) throws InterruptedException, ShutdownSignalException
  {
    return nextMessage(m_messages.poll(timeout, TimeUnit.MILLISECONDS));
  }


  // private methods


  /**
   *
   * @param message
   * @return
   */
  private Message nextMessage(Message message)
  {
    if (message != null && message != CLOSED)
      return message;

    if (message == CLOSED)
      m_messages.add(CLOSED);

    if (m_shutdown != null)
      throw m_shutdown;

    return null;
  }
}
