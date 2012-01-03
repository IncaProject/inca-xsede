<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- def2config.xsl:  Converts CTSS kit definition into incat config.     -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:iis="http://www.xsede.org/iis"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml" >

   <xsl:output method="xml" indent="yes"/>
  <xsl:preserve-space elements="* iis:*"/>
  <!-- ==================================================================== -->
  <!-- Main template                                                        -->
  <!-- ==================================================================== -->
  <xsl:template name="generateXML" match="/def2config">
    <config>
      <xsl:copy-of select="config/properties"/>
      <queries>
      <!-- insert kit queries -->
      <xsl:apply-templates select="Kits/iis:Kit" />
      </queries>
      <xsl:copy-of select="config/resources"/>
      <groups>
        <!-- insert kit groups -->
        <xsl:for-each select="Kits/iis:Kit">
          <xsl:call-template name="printGroups">
            <xsl:with-param name="kit" select="."/>
            <xsl:with-param name="existingGroups" select="/def2config/config/groups/group"/>
          </xsl:call-template>
        </xsl:for-each>
        <!-- copy manual groups -->
        <xsl:copy-of select="config/groups/group"/>
      </groups>
      <xsl:copy-of select="config/suites"/>
    </config>
  </xsl:template>

  
  <!-- ==================================================================== -->
  <!-- crossProduct                                                         -->
  <!--                                                                      -->
  <!-- Takes as input an array of arrays and returns the cross product as a -->
  <!-- string of "|" separated values.                                      -->
  <!--                                                                      -->
  <!-- Inputs:                                                              -->
  <!--   values - an xslt array of strings.  Each string is a "|" separated -->
  <!--            array of values.                                          -->
  <!-- ==================================================================== -->
  <xsl:template name="crossProduct">
    <xsl:param name="values"/>

    <xsl:variable name="numValues" select="count($values)"/>
    <xsl:variable name="lastItem" select="subsequence($values, $numValues, 1)"/>
    <xsl:variable name="values" select="remove($values,$numValues)"/>
    <xsl:choose><xsl:when test="count($values)=0">
      <xsl:value-of select="$lastItem"/>
    </xsl:when><xsl:otherwise>
      <xsl:variable name="intermediateCrossProduct">
         <xsl:call-template name="crossProduct">
           <xsl:with-param name="values" select="$values"/>
         </xsl:call-template>
      </xsl:variable>
      <xsl:for-each select="tokenize($intermediateCrossProduct, '\|')">
        <xsl:variable name="intermediateVal" select="."/>
        <xsl:for-each select="tokenize($lastItem, '\|')">
          <xsl:value-of select="concat('(', $intermediateVal,')?(-',.,')?')"/>|
        </xsl:for-each>
      </xsl:for-each>
    </xsl:otherwise></xsl:choose>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSwQuery                                                         -->
  <!--                                                                      -->
  <!-- Prints the query xml to describe a software packages.                -->
  <!--                                                                      -->
  <!-- Inputs:                                                              -->
  <!--   kit - the kit node containing its details                          -->
  <!--   sw - the software node containing its details                      -->
  <!--   optional - true if the software package is optional and false      -->
  <!--              otherwise                                               -->
  <!-- ==================================================================== -->
  <xsl:template name="printSwQuery">
    <xsl:param name="kit"/>
    <xsl:param name="sw"/>
    <xsl:param name="swRegex"/>
    <xsl:param name="optional"/>

    <query>
        <xsl:variable name="regexPrefix"><xsl:choose><xsl:when test="$swRegex!=''"><xsl:value-of select="$swRegex"/></xsl:when><xsl:otherwise><xsl:value-of select="$sw"/></xsl:otherwise></xsl:choose></xsl:variable>
        <xsl:variable name="groupName" select="concat($kit/Name,$kit/Version,'-',$sw)"/>
        <expression>Software[matches(Name,'^<xsl:value-of select="$regexPrefix"/>(-[\d\.]+)?$')]</expression>
        <products>
          <version>
            <macro><xsl:value-of select="concat($groupName,'-version')"/></macro>
          </version>
          <xsl:if test="$optional=1">
          <optional>
            <group><xsl:value-of select="$groupName"/></group>
          </optional>
          </xsl:if>
          <key>
            <macro><xsl:value-of select="concat($groupName,'-key')"/></macro>
          </key>
      </products>
    </query>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printServiceQuery                                                    -->
  <!--                                                                      -->
  <!-- Prints the query xml to describe a software packages.                -->
  <!--                                                                      -->
  <!-- Inputs:                                                              -->
  <!--   kit - the kit node containing its details                          -->
  <!--   service - the service name                                         -->
  <!--   optional - true if the software package is optional and false      -->
  <!--              otherwise                                               -->
  <!-- ==================================================================== -->
  <xsl:template name="printServiceQuery">
    <xsl:param name="kit"/>
    <xsl:param name="service"/>
    <xsl:param name="optional"/>

    <query>
      <!-- exception for ws gram service registrations -->
      <xsl:variable name="serviceRegex" select="replace($service, '^ws-gram-', 'ws-gram/')"/>
      <xsl:variable name="service" select="replace($service, '/', '-')"/>
      <expression>Service[Name = '<xsl:value-of select="$serviceRegex"/>']</expression>
      <xsl:variable name="groupName" select="concat($kit/Name, $kit/Version, '-', $service)"/>
      <products>
        <version>
          <macro><xsl:value-of select="concat($groupName, '-registered-version')"/></macro>
        </version>
        <xsl:if test="$optional=1">
          <optional>
            <group><xsl:value-of select="$groupName"/></group>
          </optional>
        </xsl:if>
        <url>
          <host><xsl:value-of select="concat($groupName, '-host')"/></host>
          <port><xsl:value-of select="concat($groupName, '-port')"/></port>
        </url>
        <endpoint>
          <macro><xsl:value-of select="concat($groupName, '-endpoint')"/></macro>
        </endpoint>
      </products>
    </query>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printGroups                                                          -->
  <!--                                                                      -->
  <!-- Prints a kit or service group.                                       -->
  <!-- ==================================================================== -->
  <xsl:template name="printGroups">
    <xsl:param name="kit"/>
    <xsl:param name="existingGroups"/>

   <xsl:variable name="kitGroup" select="concat($kit/Name,'.teragrid.org-',$kit/Version)"/>
   <!-- if there is already a group in the config file we don't override it
   because it contains custom macros -->
   <xsl:if test="count($existingGroups[name=$kitGroup])=0">
     <group>
       <name><xsl:value-of select="$kitGroup"/></name>
       <type>kit</type>
     </group>
   </xsl:if>
    <xsl:for-each select="Software">
      <xsl:variable name="sw" select="."/>
      <xsl:variable name="variables">
        <xsl:call-template name="crossProduct">
          <xsl:with-param name="values" select="Variable"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:choose><xsl:when test="not(matches($variables, '^\s*$'))">
        <xsl:for-each select="tokenize($variables, '\|')">
          <xsl:if test="not(matches(.,'^\s*$'))">
          <xsl:variable name="name" select="concat($sw/Name,'-',normalize-space(.))"/>
          <xsl:variable name="plainName" select="replace(replace($name, '[()?]', ''), '\+', 'p')"/>
          <xsl:variable name="swGroup" select="concat($kit/Name,$kit/Version,'-',$plainName)"/>
          <xsl:if test="count($existingGroups[name=$swGroup])=0">
          <group>
            <name><xsl:value-of select="$swGroup"/></name>
            <type>optional</type>
          </group>
          </xsl:if>
          </xsl:if>
        </xsl:for-each>
      </xsl:when><xsl:when test="$kit/Fixed='false' or ($kit/Fixed='true' and $sw/Required='false')">
          <xsl:variable name="swGroup"
                        select="concat($kit/Name,$kit/Version,'-',$sw/Name)"/>
          <xsl:if test="count($existingGroups[name=$swGroup])=0">
          <group>
            <name><xsl:value-of select="$swGroup"/></name>
            <type>optional</type>
          </group>
          </xsl:if>
      </xsl:when></xsl:choose>
    </xsl:for-each>

    <xsl:for-each select="Service">
      <xsl:variable name="service" select="."/>
      <xsl:variable name="variables">
        <xsl:call-template name="crossProduct">
          <xsl:with-param name="values" select="Variable"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:for-each select="$service/Group">
        <group>
          <name><xsl:value-of select="concat($kit/Name,$kit/Version,'-',$service/Name,'-',@Name)"/></name>
          <type>general</type>
        </group>
      </xsl:for-each>
      <xsl:choose><xsl:when test="not(matches($variables, '^\s*$'))">
        <xsl:for-each select="tokenize($variables, '\|')">
          <xsl:if test="not(matches(.,'^\s*$'))">
          <xsl:variable name="name" select="concat($service/Name,'-',normalize-space(.))"/>
          <xsl:variable name="plainName" select="replace(replace($name, '[()?]', ''), '\+', 'p')"/>
          <xsl:variable name="serviceGroup" 
                        select="concat($kit/Name,$kit/Version,'-',$plainName)"/>
          <xsl:if test="count($existingGroups[name=$serviceGroup])=0">
          <group>
            <name><xsl:value-of select="$serviceGroup"/></name>
            <type>optional</type>
            <xsl:for-each select="$service/Variable">
              <xsl:variable name="var" select="."/>
              <xsl:variable name="varMacroPrefix" 
                            select="concat($kit/Name,$kit/Version,'-',$service/Name, '-', @Name)"/>
              <macro>
                <type>constant</type>
                <name><xsl:value-of select="$varMacroPrefix"/></name>
                <xsl:for-each select="tokenize($plainName, '-')">
                  <xsl:if test="matches(.,$var)">
                    <value><xsl:value-of select="."/></value>
                  </xsl:if>
                </xsl:for-each>
              </macro>
              <macro>
                <type>constant</type>
                <name><xsl:value-of select="concat($varMacroPrefix, '-host' )"/></name>
                <value>@<xsl:value-of select="concat($serviceGroup, '-host')"/>@</value>
              </macro>
              <macro>
                <type>constant</type>
                <name><xsl:value-of select="concat($varMacroPrefix, '-port' )"/></name>
                <value>@<xsl:value-of select="concat($serviceGroup, '-port')"/>@</value>
              </macro>
            </xsl:for-each>
            <xsl:for-each select="$service/Group">
              <xsl:if test="matches($plainName, .)">
              <group>
                <name><xsl:value-of select="concat($kit/Name,$kit/Version,'-',$service/Name,'-',@Name)"/></name>
                <type>general</type>
              </group>
              </xsl:if>
            </xsl:for-each>
          </group>
          </xsl:if>
          </xsl:if>
        </xsl:for-each>
      </xsl:when><xsl:when test="$kit/Fixed='false' or ($kit/Fixed='true' and $service/Required='false')">
        <xsl:variable name="serviceGroup" 
                      select="concat($kit/Name,$kit/Version,'-',$service/Name)"/>
        <xsl:if test="count($existingGroups[name=$serviceGroup])=0">
        <xsl:variable name="serviceName" select="replace($service/Name, '/', '-')"/>
        <group>
          <name><xsl:value-of select="concat($kit/Name,$kit/Version,'-',$serviceName)"/></name>
          <type>optional</type>
        </group>
        </xsl:if>
      </xsl:when></xsl:choose>
    </xsl:for-each>
    
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printKit                                                             -->
  <!--                                                                      -->
  <!-- Prints a kit.                                                        -->
  <!-- ==================================================================== -->
  <xsl:template name="printKit" match="iis:Kit">
      <kit>
        <xsl:variable name="kit" select="."/>
        <name><xsl:value-of select="Name"/>.teragrid.org</name>
        <version><xsl:value-of select="Version"/></version>
        <group><xsl:value-of select="concat(Name,'.teragrid.org-',Version)"/></group>
        <xsl:for-each select="Software">
          <xsl:variable name="sw" select="."/>
          <xsl:variable name="variables">
            <xsl:call-template name="crossProduct">
              <xsl:with-param name="values" select="Variable"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:choose><xsl:when test="not(matches($variables, '^\s*$'))">
            <xsl:for-each select="tokenize($variables, '\|')">
              <xsl:if test="not(matches(.,'^\s*$'))">
              <xsl:variable name="name" select="concat($sw/Name,'-?',normalize-space(.))"/>
              <xsl:call-template name="printSwQuery">
                <xsl:with-param name="swRegex" select="replace($name, '\+', '\\+')"/>
                <xsl:with-param name="sw" select="replace(replace($name, '[()?]', ''), '\+', 'p')"/>
                <xsl:with-param name="kit" select="$kit"/>
                <xsl:with-param name="optional" select="1"/>
              </xsl:call-template>
              </xsl:if>
            </xsl:for-each>
          </xsl:when><xsl:otherwise>
            <xsl:call-template name="printSwQuery">
              <xsl:with-param name="sw" select="$sw/Name"/>
              <xsl:with-param name="kit" select="$kit"/>
              <xsl:with-param name="optional" select="$kit/Fixed='false' or ($kit/Fixed='true' and $sw/Required='false')"/>
            </xsl:call-template>
          </xsl:otherwise></xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="Service">
          <xsl:variable name="service" select="."/>
          <xsl:variable name="variables">
            <xsl:call-template name="crossProduct">
              <xsl:with-param name="values" select="Variable"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:choose><xsl:when test="not(matches($variables, '^\s*$'))">
            <xsl:for-each select="tokenize($variables, '\|')">
              <xsl:if test="not(matches(.,'^\s*$'))">
              <xsl:call-template name="printServiceQuery">
                <xsl:with-param name="service" select="concat($service/Name,'-',normalize-space(.))"/>
                <xsl:with-param name="kit" select="$kit"/>
                <xsl:with-param name="optional" select="1"/>
              </xsl:call-template>
              </xsl:if>
            </xsl:for-each>
          </xsl:when><xsl:otherwise>
            <xsl:call-template name="printServiceQuery">
              <xsl:with-param name="service" select="$service/Name"/>
              <xsl:with-param name="kit" select="$kit"/>
              <xsl:with-param name="optional" select="$kit/Fixed='false' or ($kit/Fixed='true' and $service/Required='false')"/>
            </xsl:call-template>
          </xsl:otherwise></xsl:choose>
        </xsl:for-each>
      </kit>
  </xsl:template>

</xsl:stylesheet>


