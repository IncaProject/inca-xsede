<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- reqs2config.xsl:  Converts CTSS kit definition into incat config.     -->
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
  <xsl:template name="generateXML" match="/reqs2config">
    <xsl:variable name="testable_statuses" select="tokenize('production friendly testing', ' ')"/>
    <xsl:variable name="testable_schedulers" select="tokenize('slurm torque|pbs condor moab', ' ')"/>
    <config>
      <xsl:copy-of select="config/properties"/>
      <queries>
      <xsl:for-each select="$testable_statuses">
        <resource>
             <expression>current_statuses[matches(.,'<xsl:value-of select="."/>')]</expression>
             <products>
                   <group>
                       <group>rdr-<xsl:value-of select="."/></group>
                   </group>
             </products>
        </resource>
      </xsl:for-each>

      <xsl:for-each select="distinct-values(//requirements/list-item/SPClass)">
        <xsl:variable name="spid" select="translate(lower-case(.),' ', '-')"/>
        <resource>
             <expression>other_attributes[provider_level='<xsl:value-of select="."/>']</expression>
             <products>
                   <group>
                       <group><xsl:value-of select="$spid"/></group>
                   </group>
             </products>
        </resource>
      </xsl:for-each>
        <resource>
             <expression>other_attributes/batch_system</expression>
             <products>
                   <group>
                       <group>xsede-batch</group>
                   </group>
             </products>
        </resource>
      <xsl:for-each select="$testable_schedulers">
        <resource>
             <expression>other_attributes[matches(lower-case(batch_system), '<xsl:value-of select="."/>')]</expression>
             <products>
                   <group>
                       <group><xsl:value-of select="tokenize(., '\|')"/></group>
                   </group>
             </products>
        </resource>
      </xsl:for-each>

      <xsl:call-template name="printKit">
        <xsl:with-param name="components" select="/reqs2config/requirements/list-item"/>
        <xsl:with-param name="synonyms" select="/reqs2config/synonyms/list-item"/>
      </xsl:call-template>
      </queries>
      <xsl:copy-of select="config/resources"/>
      <groups>
        <xsl:for-each select="$testable_statuses">
            <group>
               <name>rdr-<xsl:value-of select="."/></name>
               <type>general</type>
               <group>
                 <type>general</type>
                 <name>xsede</name>
               </group>
            </group>
        </xsl:for-each>
        <!-- insert kit groups -->
        <xsl:call-template name="printGroups">
          <xsl:with-param name="reqs" select="//requirements"/>
          <xsl:with-param name="existingGroups" select="/reqs2config/config/groups/group"/>
        </xsl:call-template>
        <!-- copy manual groups -->
        <xsl:copy-of select="config/groups/group"/>
      </groups>
      <suites>
        <xsl:call-template name="printSuites">
          <xsl:with-param name="reqs" select="//requirements"/>
          <xsl:with-param name="suites" select="/reqs2config/config/suites"/>
        </xsl:call-template>
      </suites>
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
  <!--   component - the software node containing its details                      -->
  <!--   optional - true if the software package is optional and false      -->
  <!--              otherwise                                               -->
  <!-- ==================================================================== -->
  <xsl:template name="printSwQuery">
    <xsl:param name="kit"/>
    <xsl:param name="sw"/>
    <xsl:param name="swRegex"/>
    <xsl:param name="optional"/>
    <xsl:param name="accessMethod"/>

    <query>
        <xsl:variable name="regexPrefix"><xsl:choose><xsl:when test="$swRegex!=''"><xsl:value-of select="$swRegex"/></xsl:when><xsl:otherwise><xsl:value-of select="$sw"/></xsl:otherwise></xsl:choose></xsl:variable>
        <xsl:variable name="groupName" select="concat($kit/Name,$kit/Version,'-',$sw)"/>
        <expression>tg:Software[matches(tg:Name,'^<xsl:value-of select="$regexPrefix"/>(-[\d\.]+)?$')]</expression>
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
          <xsl:if test="$accessMethod">
            <xsl:if test="$optional=1">
            <optional>
              <expression>tg:Extensions/tg:ExtendedInfo/tg:AccessMethod[tg:Type='<xsl:value-of select="$accessMethod"/>']</expression>
              <group><xsl:value-of select="concat($groupName, '-', $accessMethod)"/></group>
            </optional>
            </xsl:if>
            <url>
              <expression>tg:Extensions/tg:ExtendedInfo/tg:AccessMethod[tg:Type='<xsl:value-of select="$accessMethod"/>']</expression>
              <host><xsl:value-of select="concat($groupName, '-', $accessMethod, '-host')"/></host>
              <port><xsl:value-of select="concat($groupName, '-', $accessMethod, '-port')"/></port>
            </url>
            <endpoint>
              <expression>tg:Extensions/tg:ExtendedInfo/tg:AccessMethod[tg:Type='<xsl:value-of select="$accessMethod"/>']</expression>
              <macro><xsl:value-of select="concat($groupName, '-', $accessMethod, '-endpoint')"/></macro>
            </endpoint>
          </xsl:if>
      </products>
    </query>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printServiceQuery                                                    --> <!--                                                                      -->
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
      <expression>tg:Service[tg:Name = '<xsl:value-of select="$serviceRegex"/>']</expression>
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
        <xsl:if test="$service='gridftp-default-server'">
        <go-endpoint><macro>go-id</macro></go-endpoint>
        </xsl:if>
      </products>
    </query>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printGroups                                                          -->
  <!--                                                                      -->
  <!-- Prints a kit or service group.                                       -->
  <!-- ==================================================================== -->
  <xsl:template name="printGroups">
    <xsl:param name="reqs"/>
    <xsl:param name="existingGroups"/>

    
    <xsl:for-each select="distinct-values($reqs/list-item/SPClass)">
        <xsl:variable name="splevel" select="."/>
        <xsl:variable name="spid" select="translate(lower-case($splevel),' ', '-')"/>
        <group>
            <name><xsl:value-of select="$spid"/></name>
            <type>general</type>
            <xsl:for-each select="$reqs/list-item[SPClass=$splevel and Requirement='Required']">
              <group>
                  <name><xsl:value-of select="ComponentName"/></name>
                  <type>general</type>
              </group>
            </xsl:for-each>
        </group>
    </xsl:for-each>
    <group>
       <name>xsede-kit</name>
       <type>kit</type>
    </group>
    <xsl:for-each select="distinct-values($reqs/list-item[Requirement='Optional']/ComponentName)">
        <xsl:variable name="optGroupName" select="concat(.,'-optional')"/>
        <xsl:if test="count($existingGroups[name=$optGroupName])=0">
        <group>
            <name><xsl:value-of select="."/>-optional</name>
            <type>optional</type>
            <group>
              <name><xsl:value-of select="."/></name>
              <type>general</type>
            </group>
        </group>
        </xsl:if>
    </xsl:for-each>
    <xsl:for-each select="distinct-values($reqs/list-item/ComponentName)">
        <group>
            <name><xsl:value-of select="."/></name>
            <type>general</type>
        </group>
    </xsl:for-each>
    
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSuites                                                          -->
  <!--                                                                      -->
  <!-- Prints out suites with sp tags                                       -->
  <!-- ==================================================================== -->
  <xsl:template name="printSuites">
    <xsl:param name="reqs"/>
    <xsl:param name="suites"/>

    <xsl:for-each select="$suites/suite">
      <xsl:for-each select="*">
        <xsl:variable name="sctag" select="./name()"/>
        <xsl:choose><xsl:when test="$sctag='seriesConfigs'">
          <seriesConfig>
          <xsl:for-each select="seriesConfig/*">
            <xsl:variable name="stag" select="./name()"/>
            <xsl:choose><xsl:when test="$stag='tags'">
            <xsl:variable name="componentstring" select="tag[starts-with(.,'software') or starts-with(.,'service')]"/>
            <xsl:variable name="component" select="substring-after($componentstring,'=')"/>
            <tags>
              <xsl:for-each select="$reqs/list-item[ComponentName=$component]">
                <tag><xsl:value-of select="replace(SPClass,' ','_')"/>=<xsl:value-of select="Requirement"/></tag>
              </xsl:for-each>
              <xsl:copy-of select="./tag"/>
            </tags>
            </xsl:when><xsl:otherwise>
              <xsl:copy-of select="."/>
            </xsl:otherwise></xsl:choose>
          </xsl:for-each>
          </seriesConfig>
        </xsl:when><xsl:otherwise>
          <xsl:copy-of select="."/>
        </xsl:otherwise></xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
    
  </xsl:template>
  <!-- ==================================================================== -->
  <!-- printKit                                                             -->
  <!--                                                                      -->
  <!-- Prints a kit.                                                        -->
  <!-- ==================================================================== -->
  <xsl:template name="printKit">
      <xsl:param name="components"/>
      <xsl:param name="synonyms"/>

      <kit>
        <name>XSEDE</name>
        <version>1.0.0</version>
        <group>xsede-kit</group>
        <xsl:for-each select="distinct-values($components/ComponentName)">
          <xsl:variable name="component" select="."/>
        <query>
          <expression>list-item[AppName = '<xsl:value-of select="."/>' or InterfaceName = '<xsl:value-of select="."/>'<xsl:if test="count($synonyms[ComponentName=$component])>0"> or matches(AppName,'<xsl:value-of select="$synonyms[ComponentName=$component]/module-pattern"/>')</xsl:if>]</expression>
          <products>
             <version>
                 <macro><xsl:value-of select="."/>-version</macro>
             </version>
             <latestversion>
                 <macro><xsl:value-of select="."/>-latestversion</macro>
             </latestversion>
             <optional>
                 <group><xsl:value-of select="."/>-optional</group>
             </optional>
         </products>
        </query>
        <query>
          <expression>list-item[AppName = '<xsl:value-of select="."/>' <xsl:if test="count($synonyms[ComponentName=$component])>0"> or matches(AppName,'<xsl:value-of select="$synonyms[ComponentName=$component]/module-pattern"/>')</xsl:if>]</expression>
          <products>
             <key>
                 <macro><xsl:value-of select="."/>-key</macro>
             </key>
         </products>
        </query>
        <query>
          <expression>list-item[InterfaceName = '<xsl:value-of select="."/>']</expression>
          <products>
             <url>
               <host><xsl:value-of select="."/>-host</host>
               <port><xsl:value-of select="."/>-port</port>
             </url>
             <endpoint>
               <macro><xsl:value-of select="."/>-endpoint</macro>
             </endpoint>
         </products>
        </query>
        </xsl:for-each>
      </kit>
  </xsl:template>

</xsl:stylesheet>


