/*
 * ReceiverExample.java
 */
package org.xsede;


import java.io.File;
import java.io.FilenameFilter;
import java.util.EnumSet;
import java.util.regex.Pattern;

import org.apache.commons.cli.Options;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.HelpFormatter;

import org.xsede.messaging.AmqpConnectionFactory;
import org.xsede.messaging.AmqpSubscription;
import org.xsede.messaging.ExchangeName;


/**
 *
 * @author Paul Hoover
 *
 */
public class ReceiverExample {

  // nested classes


  /**
   *
   */
  private static class RegExFilter implements FilenameFilter {

    private final Pattern m_pattern;


    /**
     *
     * @param expression
     */
    public RegExFilter(String expression)
    {
      m_pattern = Pattern.compile(expression);
    }


    /**
     *
     * @param dir
     * @param name
     * @return
     */
    public boolean accept(File dir, String name)
    {
      return m_pattern.matcher(name).matches();
    }
  }


  // public methods


  /**
   * Main method
   *
   * @param args command-line arguments
   */
  public static void main(String[] args)
  {
    Options options = new Options();
    options.addOption("c", true, "path to user certificate");
    options.addOption("k", true, "path to user key");
    options.addOption("t", true, "path to trusted certificates directory");
    options.addOption("p", true, "passphrase");
    options.addOption("h", false, "print help information");
    options.addOption("s", true, "hostname of AMQP server (default: info.dyn.xsede.org)");
    options.addOption("v", true, "virtual hostname of AMQP server (default: xsede)");
    options.addOption("T", true, "Stop listening (or timeout) afer provided seconds");

    CommandLineParser parser = new GnuParser();
    AmqpConnectionFactory connFactory = new AmqpConnectionFactory();
    long timeout = 0;
    try {
      CommandLine cmd = parser.parse( options, args);
      if ( cmd.hasOption("h") ) {
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp( "ReceiverExample [ exchange [ filters... ] ]", options );
        System.exit(1);
      }
      if ( cmd.hasOption("c") && cmd.hasOption("k") && cmd.hasOption("t") ) {
        String[] certFiles = getTrustedCertNames( cmd.getOptionValue("t") );
        System.out.println( "Certificate " + cmd.getOptionValue("c") );
        connFactory.setSslContext(cmd.getOptionValue("c"), cmd.getOptionValue("k"), cmd.getOptionValue("p"), certFiles);
      }
      if ( cmd.hasOption("s") ) {
        connFactory.setHost( cmd.getOptionValue("s") );
      }
      if ( cmd.hasOption("v") ) {
        connFactory.setVirtualHost( cmd.getOptionValue("v") );
      }
      if ( cmd.hasOption("T") ) {
        timeout = Long.parseLong( cmd.getOptionValue("T") );
        timeout *= 1000;
      }

      connFactory.setConnectionTimeout(30000);
      AmqpSubscription subscription = new AmqpSubscription(connFactory);
      
      String[] program_args = cmd.getArgs();
      try {
        if (program_args.length < 1) {
          for (ExchangeName exchange : EnumSet.allOf(ExchangeName.class))
            subscription.subscribe(exchange);
        }
        else {
          ExchangeName exchange = ExchangeName.parse(program_args[0]);

          if (program_args.length < 2)
            subscription.subscribe(exchange);
          else {
            for (int i = 0 ; i < program_args.length ; i += 1)
              subscription.subscribe(exchange, program_args[i]);
          }
        }

        long startTime = System.currentTimeMillis();
        long timeRunning = 0;
        while ( timeout <= 0 || timeRunning < timeout ) {
          AmqpSubscription.Message message = subscription.nextMessage();

          if (message == null)
            break;

          String body = message.getBody();
          String routingKey = message.getEnvelope().getRoutingKey();

          System.out.println(routingKey + " ==> " + body);
          timeRunning = System.currentTimeMillis() - startTime;
        }
      }
      finally {
        subscription.close();
      }
    }
    catch (Exception err) {
      err.printStackTrace(System.err);

      System.exit(-1);
    }
  }


  // private methods


  /**
   *
   * @param dirName
   * @return
   */
  private static String[] getTrustedCertNames(String dirName)
  {
    String[] fileNames = (new File(dirName)).list(new RegExFilter(".+\\.pem"));
    String[] result = new String[fileNames.length];
    String separator = System.getProperty("file.separator");

    for (int i = 0 ; i < fileNames.length ; i += 1)
      result[i] = dirName + separator + fileNames[i];

    return result;
  }
}
