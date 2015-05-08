/*
 * IncaConnectionFactory.java
 */
package org.xsede.messaging;


import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import java.security.KeyManagementException;
import java.security.KeyPair;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.Security;
import java.security.UnrecoverableKeyException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManagerFactory;
import javax.security.auth.x500.X500Principal;

import org.bouncycastle.asn1.x500.RDN;
import org.bouncycastle.asn1.x500.X500Name;
import org.bouncycastle.asn1.x500.style.BCStyle;
import org.bouncycastle.asn1.x500.style.IETFUtils;
import org.bouncycastle.cert.X509CertificateHolder;
import org.bouncycastle.cert.jcajce.JcaX509CertificateConverter;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.openssl.PEMDecryptorProvider;
import org.bouncycastle.openssl.PEMEncryptedKeyPair;
import org.bouncycastle.openssl.PEMReader;
import org.bouncycastle.openssl.PasswordFinder;
import org.bouncycastle.openssl.PEMKeyPair;
import org.bouncycastle.openssl.PEMParser;
import org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter;
import org.bouncycastle.openssl.jcajce.JcePEMDecryptorProviderBuilder;

import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.DefaultSaslConfig;


/**
 * An extension of the RabbitMQ <code>ConnectionFactory</code> object
 *
 * @author Paul Hoover
 *
 */
public class AmqpConnectionFactory extends ConnectionFactory {

  static {
    Security.addProvider(new BouncyCastleProvider());
  }


  // data fields


  private static final String PROVIDER = "BC";


  // constructors


  /**
   * Constructs a <code>ConnectionFactory</code> with settings appropriate for FutureGrid's AMQP server
   */
  public AmqpConnectionFactory()
  {
    setHost("inca.dyn.xsede.org");
    setVirtualHost("monitoring");
  }


  // public methods


  /**
   * Configures the <code>ConnectionFactory</code> so that it will use secure authentication when
   * connecting to the server
   *
   * @param certFile the name of the client's X509 certificate file
   * @param keyFile the name of the client's private key file
   * @param keyPassPhrase a pass phrase for the private key
   * @param hostCerts an array of names of hosts' X509 certificate files
   * @throws IOException
   * @throws KeyStoreException
   * @throws NoSuchProviderException
   * @throws NoSuchAlgorithmException
   * @throws CertificateException
   * @throws UnrecoverableKeyException
   * @throws KeyManagementException
   */
  public void setSslContext(String certFile, String keyFile, String keyPassPhrase, String[] hostCerts) throws IOException, KeyStoreException, NoSuchProviderException, NoSuchAlgorithmException, CertificateException, UnrecoverableKeyException, KeyManagementException
  {
    KeyStore userStore = readUserCert(certFile, keyFile, keyPassPhrase);
    KeyManagerFactory keyFactory = KeyManagerFactory.getInstance("SunX509");

    keyFactory.init(userStore, keyPassPhrase.toCharArray());

    KeyStore trustedStore = readTrustedCerts(hostCerts);
    TrustManagerFactory trustFactory = TrustManagerFactory.getInstance("SunX509");

    trustFactory.init(trustedStore);

    SSLContext context = SSLContext.getInstance("SSLv3");

    context.init(keyFactory.getKeyManagers(), trustFactory.getTrustManagers(), null);

    useSslProtocol(context);
    setSaslConfig(DefaultSaslConfig.EXTERNAL);
  }

  /**
   * Configures the <code>ConnectionFactory</code> so that it will use secure authentication when
   * connecting to the server
   *
   * @param certFile the name of the client's X509 certificate file
   * @param keyFile the name of the client's private key file
   * @param keyPassPhrase a pass phrase for the private key
   * @param hostCert the name of the host's X509 certificate file
   * @throws IOException
   * @throws KeyStoreException
   * @throws NoSuchProviderException
   * @throws NoSuchAlgorithmException
   * @throws CertificateException
   * @throws UnrecoverableKeyException
   * @throws KeyManagementException
   */
  public void setSslContext(String certFile, String keyFile, String keyPassPhrase, String hostCert) throws IOException, KeyStoreException, NoSuchProviderException, NoSuchAlgorithmException, CertificateException, UnrecoverableKeyException, KeyManagementException
  {
    setSslContext(certFile, keyFile, keyPassPhrase, new String[] { hostCert });
  }


  // private methods


  /**
   *
   * @param fileName
   * @return
   * @throws FileNotFoundException
   */
  private InputStream openStream(String fileName) throws FileNotFoundException
  {
    InputStream result = ClassLoader.getSystemClassLoader().getResourceAsStream(fileName);

    if (result == null)
      result = new FileInputStream(fileName);

    return result;
  }

  /**
   *
   * @param fileName
   * @return
   * @throws IOException
   */
  private Object readPEMFile(String fileName) throws IOException
  {
    InputStream inStream = openStream(fileName);
    PEMReader reader = null;

    try {
      reader = new PEMReader(new InputStreamReader(inStream));

      return reader.readObject();
    }
    finally {
      if (reader != null)
        reader.close();
      else
        inStream.close();
    }

  }

  /**
   *
   * @param fileName
   * @return
   * @throws IOException
   * @throws CertificateException
   */
  private X509Certificate readCertFile(String fileName) throws IOException, CertificateException
  {
    return (X509Certificate)readPEMFile(fileName);
  }

  /**
   *
   * @param fileName
   * @param password
   * @return
   * @throws IOException
   * @throws KeyStoreException
   */
  private KeyPair readKeyFile(String fileName, final String password) throws IOException, KeyStoreException
  {
    InputStream inStream = openStream(fileName);
    PEMReader reader = null;

    try {
      reader =  new PEMReader(
        new InputStreamReader(inStream),
        new PasswordFinder() {
          public char[] getPassword() {
            return password.toCharArray();
          }
        }
      );

      return (KeyPair)reader.readObject();
    }
    finally {
      if (reader != null)
        reader.close();
      else
        inStream.close();
    }
  }

  /**
   *
   * @param principal
   * @return
   */
  private String getCommonName(X500Principal principal)
  {
    X500Name name = new X500Name(principal.getName());
    RDN[] rdns = name.getRDNs(BCStyle.CN);

    return IETFUtils.valueToString(rdns[0].getFirst().getValue());
  }

  /**
   *
   * @param cert
   * @return
   */
  private String getAlias(X509Certificate cert)
  {
    String subjectCN = getCommonName(cert.getSubjectX500Principal());
    String issuerCN = getCommonName(cert.getIssuerX500Principal());

    return subjectCN + " issued by " + issuerCN;
  }

  /**
   *
   * @param certFile
   * @param keyFile
   * @param keyPassPhrase
   * @return
   * @throws IOException
   * @throws KeyStoreException
   * @throws NoSuchProviderException
   * @throws NoSuchAlgorithmException
   * @throws CertificateException
   */
  private KeyStore readUserCert(String certFile, String keyFile, String keyPassPhrase) throws IOException, KeyStoreException, NoSuchProviderException, NoSuchAlgorithmException, CertificateException
  {
    X509Certificate cert = readCertFile(certFile);
    KeyPair keyPair = readKeyFile(keyFile, keyPassPhrase);
    String alias = getAlias(cert);
    KeyStore.PrivateKeyEntry entry = new KeyStore.PrivateKeyEntry(keyPair.getPrivate(), new Certificate[] { (Certificate)cert });
    KeyStore.PasswordProtection prot = new KeyStore.PasswordProtection(keyPassPhrase.toCharArray());
    KeyStore store = KeyStore.getInstance("PKCS12", PROVIDER);

    store.load(null, null);
    store.setEntry(alias, entry, prot);

    return store;
  }

  /**
   *
   * @param certFiles
   * @return
   * @throws IOException
   * @throws KeyStoreException
   * @throws NoSuchAlgorithmException
   * @throws CertificateException
   */
  private KeyStore readTrustedCerts(String[] certFiles) throws IOException, KeyStoreException, NoSuchAlgorithmException, CertificateException
  {
    KeyStore store = KeyStore.getInstance("JKS");

    store.load(null, null);

    for (String file : certFiles) {
      X509Certificate cert = readCertFile(file);
      KeyStore.TrustedCertificateEntry entry = new KeyStore.TrustedCertificateEntry(cert);
      String alias = getAlias(cert);

      store.setEntry(alias, entry, null);
    }

    return store;
  }
}
