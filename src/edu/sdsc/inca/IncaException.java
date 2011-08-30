/*
 * IncaException.java
 */
package edu.sdsc.inca;


/**
 *
 * @author Paul Hoover
 *
 */
public class IncaException extends Exception {

	/**
	 *
	 */
	private static final long serialVersionUID = 8288433054597641692L;

	// constructors


	/**
	 *
	 */
	public IncaException()
	{
		super();
	}

	/**
	 *
	 * @param message
	 */
	public IncaException(String message)
	{
		super(message);
	}

	/**
	 *
	 * @param message
	 * @param cause
	 */
	public IncaException(String message, Throwable cause)
	{
		super(message, cause);
	}

	/**
	 *
	 * @param cause
	 */
	public IncaException(Throwable cause)
	{
		super (cause);
	}
}
