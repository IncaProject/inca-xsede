<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  
  <xsl:template match="/">
    <xsl:for-each select="//KitRegistration">
      <xsl:sort select="ResourceName"/>
      <xsl:text>
      </xsl:text><resource><xsl:text>
        </xsl:text>
      <xsl:copy-of select="ResourceName" copy-namespaces="no"/><xsl:text>
        </xsl:text>
      <xsl:copy-of select="ResourceID" copy-namespaces="no"/><xsl:text>
        </xsl:text>
      <xsl:copy-of select="SiteID" copy-namespaces="no"/><xsl:text>
        </xsl:text>
      <xsl:for-each select="Kit">
        <xsl:sort select="Name"/>
        <kit><xsl:text>
	  </xsl:text>
	<xsl:copy-of select="Name" copy-namespaces="no"/><xsl:text>
	  </xsl:text>
        <xsl:copy-of select="Version" copy-namespaces="no"/><xsl:text>
	  </xsl:text>
        <xsl:copy-of select="SupportGoal" copy-namespaces="no"/><xsl:text>
	  </xsl:text>
        <xsl:copy-of select="SupportLevel" copy-namespaces="no"/><xsl:text>
	  </xsl:text>
        <xsl:copy-of select="Installed" copy-namespaces="no"/><xsl:text>
	  </xsl:text>
        <xsl:copy-of select="StatusURL" copy-namespaces="no"/><xsl:text>
	  </xsl:text>
        <xsl:copy-of select="Description" copy-namespaces="no"/><xsl:text>
	  </xsl:text>
        <xsl:copy-of select="UserSupportOrganization" copy-namespaces="no"/><xsl:text>
	  </xsl:text>
        <xsl:copy-of select="UserSupportContact" copy-namespaces="no"/><xsl:text>
	  </xsl:text>
        <xsl:for-each select="Software">
          <xsl:sort select="Name"/>
          <sw><xsl:text>
	    </xsl:text>
          <xsl:copy-of select="Name" copy-namespaces="no"/><xsl:text>
	    </xsl:text>
          <xsl:copy-of select="Version" copy-namespaces="no"/><xsl:text>
	    </xsl:text>
          <xsl:copy-of select="Default" copy-namespaces="no"/><xsl:text>
	    </xsl:text>
          <xsl:copy-of select="HandleKey" copy-namespaces="no"/><xsl:text>
	    </xsl:text>
          <xsl:copy-of select="HandleType" copy-namespaces="no"/><xsl:text>
	  </xsl:text>
          <xsl:copy-of select="Extensions" copy-namespaces="no"/><xsl:text>
	  </xsl:text>
          </sw><xsl:text>	
          </xsl:text>
        </xsl:for-each>
        <xsl:for-each select="Service">
          <xsl:sort select="Name"/>
          <service><xsl:text>
	    </xsl:text>
          <xsl:copy-of select="Name" copy-namespaces="no"/><xsl:text>
	    </xsl:text>
          <xsl:copy-of select="Version" copy-namespaces="no"/><xsl:text>
	    </xsl:text>
          <xsl:copy-of select="Endpoint" copy-namespaces="no"/><xsl:text>
	    </xsl:text>
          <xsl:copy-of select="Type" copy-namespaces="no"/><xsl:text>
	  </xsl:text>
          </service><xsl:text>	
          </xsl:text>
        </xsl:for-each>
        </kit><xsl:text>	
      </xsl:text>
      </xsl:for-each>
      </resource><xsl:text>
      </xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
