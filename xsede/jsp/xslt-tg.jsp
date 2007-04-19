<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="inca.tld" prefix="inca" %>
<%@ taglib uri="xslt.tld" prefix="xslt" %>
<%@ taglib uri="sql.tld" prefix="sql" %>
<%@ taglib uri="c.tld" prefix="c" %>
<%@page import="java.net.URL"%>


<html>

<%
  String urlStr = request.getQueryString();
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
    out.println(
      "Please add an input parameter with either: <br><ol>" +
      "<li>a suiteName for a set of test results to display AND" +
      "a resourceID for the resource results to display, <i>OR</i></li>" +
      "<li>a instanceID AND a configID to display a single " +
      "report instance<i>OR</i></li>" +
      "<li>a configID to display a series instances</ol><br>" +
      "(e.g. \"http://this.jsp?suiteName=SuiteA&resourceID=teragrid\")" +
      "</li></ol>"
    );
  }else{
    // path to xsl file is required
    String type = "";
    String xml = "";
    // get results for a suite
    if ( (suiteName != null)  && (!suiteName.equals("")) ) {
      type = "suite";
      xml += "<combo>\n";
      %><inca:getAll2AllSummary
          suiteName="<%=suiteName%>" retAttrName="all2all"
      /><%
      xml += (String)pageContext.getAttribute("all2all");
      %><inca:getSuiteLatestInstances
          suiteName="<%=suiteName%>" retAttrName="suite"
      /><%
      xml += (String)pageContext.getAttribute("suite");
      %><inca:getResourceConfig
        resourceID="<%=resourceID%>" macros="__regexp__" retAttrName="resources"
      /><%
      xml += (String)pageContext.getAttribute("resources");
      %><inca:getXmlFromClasspath
        xmlFile="<%=xmlFile%>" retAttrName="swStack"
      /><%
      xml += ((String)pageContext.getAttribute("swStack")).replaceAll("<\\?xml.*\\?>", "");
      xml += "</combo>\n";
    } else if ( instanceID != null && ! instanceID.equals("")  ) {
      type ="test"; // get results for a single test
      %><inca:getInstance configID="<%=configID%>" instanceID="<%=instanceID%>" retAttrName="instance"/>
      <% xml = "<combo>\n" + (String)pageContext.getAttribute("instance") + "\n<comments>"; %>
      <%@ include file="db-connect.jsp" %>
      <sql:query var="comments" dataSource="${tgdb}">
        SELECT * FROM incaseriesconfigcomments WHERE incaseriesconfigid='<%=configID%>'
      </sql:query>
      <c:forEach var="row" items="${comments.rows}">
        <c:set var="author" value="${row.incaauthor}"/>
        <c:set var="date" value="${row.incaentered}"/>
        <c:set var="comment" value="${row.incacomment}"/>
        <% xml += "\n\t<row>\n\t\t<comment>" + pageContext.getAttribute("comment") + "</comment>";
           xml += "\n\t\t<author>" + pageContext.getAttribute("author") + "</author>";
           xml += "\n\t\t<date>" + pageContext.getAttribute("date") + "</date>\n\t</row>"; %>
      </c:forEach>
      <% xml += "\n</comments>\n</combo>\n";
    } else {
      %><inca:getSeries
        configID="<%=configID%>" retAttrName="series"
      /><%
      xml = (String)pageContext.getAttribute("series");
    }

    if ( (xsl != null) && (!xsl.equals("")) ){
      %>
      <xslt:applyXSL xmlString="<%=xml%>" xslData="<%=xslPath%>">
        <xslt:setParameter name="url"><%=urlStr%></xslt:setParameter>
      </xslt:applyXSL>
      <%
    }else{
      out.println(
        "Please add an input parameter with the full " +
        "path to the xsl file you will use to format the " +
        "following xml <br>" +
        "(e.g. \"http://this.jsp?xsl=/path/to/xsl/file.xsl\"): " +
        "<br/><br/><pre>"
      );
      %>
          <inca:printXML xml="<%=xml%>"/>
          </pre>
      <%
    }
  }
%>

</html>
