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
	  <br/>
	  <p>The below map uses the 
	     <a href="http://www.google.com/apis/maps">Google Maps API</a> 
	     to display the summary status of the TeraGrid as monitored by
	     <a href="http://inca.sdsc.edu">Inca</a>. </p><p>
	     Click on resource markers to view test errors for 
             individual resources<br/> (any cross-resource tests will have 
             toggle buttons to display them under the map image).</p>
	</td>
    </tr>
  </table>
  </xsl:template>

</xsl:stylesheet>
