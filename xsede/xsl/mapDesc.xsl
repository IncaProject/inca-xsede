<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- mapDesc.xsl:  Description of TG google map                           -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml">

  <xsl:include href="header.xsl"/>

  <xsl:template name="mapDesc">
    <xsl:call-template name="header"/>
    
    <table>
      <tr>
        <td>
	  <p>*** In development ***</p>
	  <p>The below map uses the 
	     <a href="http://www.google.com/apis/maps">Google Maps API</a> 
	     to display the summary status of the TeraGrid as monitored by
	     <a href="http://inca.sdsc.edu">Inca</a>. 
	     Click on any marker to view more information about that resource.
	     Use the buttons below the map to turn the gram, gridftp, and
	     gsissh status lines on and off.</p> 
	</td>
    </tr>
  </table>
  </xsl:template>

</xsl:stylesheet>
