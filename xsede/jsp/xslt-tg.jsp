<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="inca.tld" prefix="inca" %>
<%@ taglib uri="xslt.tld" prefix="xslt" %>
<%@ taglib uri="sql.tld" prefix="sql" %>
<%@ taglib uri="c.tld" prefix="c" %>
<%@page import="java.net.URL"%>


<html>

<%
  String urlStr = request.getQueryString();
  String urlPage = new URL(request.getScheme(), request.getServerName(),
                           request.getServerPort(), request.getRequestURI()).toString();
  String suiteName = request.getParameter("suiteName");
  String resourceID = request.getParameter("resourceID");
  String instanceID = request.getParameter("instanceID");
  String configID = request.getParameter("configID");
  String xmlFile = request.getParameter("xmlFile");
  String xsl = request.getParameter("xsl");
  String xslPath = null;

  if (xmlFile==null){
    xmlFile = "swStack.xml";
  }
  if ( xsl != null ) {
    URL url = ClassLoader.getSystemClassLoader().getResource( xsl );
    if( url == null ) {
      out.println( "Unable to locate xsl file: " + xsl );
      xsl = null;
    } else {
      xslPath = url.getFile();
    }
  }

  // check for input parameters
  if ( ( suiteName == null || suiteName.equals("") ||
         resourceID == null || resourceID.equals("") )
       &&
       ( configID == null || configID.equals("")  ) ) {
    out.println( "This script requires parameters to be one of the following: <br><ol>" +
      "<li>one or more CSV suiteName for test results to display AND<br/>" +
      "one or more CSV resourceID for the resource results to display:<br/>" +
      " (e.g. xslt.jsp?suiteName=sampleSuite&resourceID=defaultGrid)<br/></li><br/>" +
      "<li>a instanceID AND a configID to display a single report instance:<br/>"+
      " (e.g. xslt.jsp?instanceID=4480&configID=1)<br/></li><br/>"+
      "<li>a configID to display a history of instances for a series:<br/>"+
      " (e.g. xslt.jsp?configID=1)</li></ol><br>");
  }else{
    // path to xsl file is required
    String xml = "";
    // get results for a suite
    if ( (suiteName != null)  && (!suiteName.equals("")) ) {
      String[] suiteNames = suiteName.split(",");
      String[] resourceIDs = resourceID.split(",");
      String[] xmlFiles = xmlFile.split(",");
      String numWarn = "1 or "+suiteNames.length;
      if (suiteNames.length==1){
          numWarn = "1";
      }
      String warn =  " parameter must contain "+numWarn+" value(s).<br/><br/>";
      if ( (resourceIDs.length != 1) && (resourceIDs.length != suiteNames.length) ){
        out.println("The resourceID"+warn);
      }else if( (xmlFiles.length != 1) && (xmlFiles.length != suiteNames.length) ){
        out.println("The xmlFile"+warn);
      }else{
        xml += "<combo>\n";
        for(int i=0; i<suiteNames.length; i++) {
            xml += "<suiteResults>\n";
            %><inca:getAll2AllSummary suiteName="<%=suiteNames[i]%>" retAttrName="all2all"/><%
            xml += (String)pageContext.getAttribute("all2all");
            %><inca:getSuiteLatestInstances suiteName="<%=suiteNames[i]%>" retAttrName="suite"/><%
            xml += (String)pageContext.getAttribute("suite");
            if (resourceIDs.length == suiteNames.length) {
                xml += "<resourceName>"+resourceIDs[i]+"</resourceName>\n";
                %><inca:getResourceConfig resourceID="<%=resourceIDs[i]%>" macros="__regexp__ __regexpTmp__" retAttrName="resources"/><%
                xml += (String)pageContext.getAttribute("resources");
            }
            if (xmlFiles.length == suiteNames.length) {
                %><inca:getXmlFromClasspath xmlFile="<%=xmlFiles[i]%>" retAttrName="swStack"/><%
                xml += ((String)pageContext.getAttribute("swStack")).replaceAll("<\\?xml.*\\?>", "");
            }
            xml += "</suiteResults>";
        }
        if(resourceIDs.length == 1){
            xml += "<resourceName>"+resourceIDs[0]+"</resourceName>\n";
            %><inca:getResourceConfig resourceID="<%=resourceIDs[0]%>" macros="__regexp__ __regexpTmp__" retAttrName="resources"/><%
            xml += (String)pageContext.getAttribute("resources");}
        if(xmlFiles.length == 1){
            %><inca:getXmlFromClasspath xmlFile="<%=xmlFiles[0]%>" retAttrName="swStack"/><%
            xml += ((String)pageContext.getAttribute("swStack")).replaceAll("<\\?xml.*\\?>", "");
        }
        xml += "</combo>";
      }
    } else if ( instanceID != null && ! instanceID.equals("")  ) {
      // get results for a single test
      %><inca:getInstance configID="<%=configID%>" instanceID="<%=instanceID%>" retAttrName="instance"/>
      <% xml = "<combo>\n" + (String)pageContext.getAttribute("instance") + "\n<comments>"; %>
      <%@ include file="db-connect.jsp" %>
      <sql:query var="comments" dataSource="${tgdb}">
        SELECT * FROM incaseriesconfigcomments WHERE incaseriesconfigid='<%=configID%>'
      </sql:query>
      <c:forEach var="row" items="${comments.rows}">
        <c:set var="rawauthor" value="${row.incaauthor}"/>
        <c:set var="author"><inca:printXML xml="<%=pageContext.getAttribute("rawauthor").toString()%>"/></c:set>
        <c:set var="date" value="${row.incaentered}"/>
        <c:set var="rawcomment" value="${row.incacomment}"/>
        <c:set var="comment"><inca:printXML xml="<%=pageContext.getAttribute("rawcomment").toString()%>"/></c:set>
        <% xml += "\n\t<row>\n\t\t<comment>" + pageContext.getAttribute("comment") + "</comment>";
           xml += "\n\t\t<author>" + pageContext.getAttribute("author") + "</author>";
           xml += "\n\t\t<date>" + pageContext.getAttribute("date") + "</date>\n\t</row>"; %>
      </c:forEach>
      <% xml += "\n</comments>\n</combo>\n";
    } else {
      %><inca:getSeries configID="<%=configID%>" retAttrName="series"/><%
      xml = (String)pageContext.getAttribute("series");
    }
    if ( xsl!=null && !xsl.equals("") && !xml.equals("")){
      %>
      <xslt:applyXSL xmlString="<%=xml%>" xslData="<%=xslPath%>">
        <xslt:setParameter name="url"><%=urlStr%></xslt:setParameter>
        <xslt:setParameter name="page"><%=urlPage%></xslt:setParameter> 
      </xslt:applyXSL>
      <%
    }else if ( xsl==null || xsl.equals("") ){
      out.println("Please add an xsl file parameter to format " +
         "the xml below<br>(e.g. xslt.jsp?xsl=default.xsl):<br/><br/>");
      %><pre><inca:printXML xml="<%=xml%>"/></pre><%
    }
  }
%>

</html>
