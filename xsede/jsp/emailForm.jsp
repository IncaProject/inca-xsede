<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="inca" tagdir="/WEB-INF/tags/inca" %>


<html>
<head>
  <link href="../css/inca.css" rel="stylesheet" type="text/css"/>
</head>

<body>
<c:set var="usage">
  Description:  Emails inca with form contents
</c:set>

<inca:getUrl var="url"/>
<inca:getUrl var="queryStr" query="1"/>
<br/><p>Thank you for requesting a custom query.  The following query parameters have been emailed 
to inca administrators:</p>
<table border="1" cellpadding="10">
  <tr><td><b>Stored query name</b></td><td>${param.qname}</td></tr>
  <tr><td><b>Fetch every (secs)</b></td><td>${param.period}</td></tr>
  <tr><td><b>Series hql</b></td><td>${param.qparams}</td></tr>
  <tr><td><b>Submitted by</b></td><td>${param.email}</td></tr>
</table>
<p>Please email inca@sdsc.edu with any questions or problems with your custom query.</p>

<c:set var="emailBody">
  The following params were requested:
  <c:forEach items="${param}" var="par" varStatus="i">
    ${par.key}: ${par.value}
  </c:forEach>

TO APPROVE, visit ${url}/jsp/query.jsp?${queryStr}
</c:set>
<c:set var="email" value="echo \"${emailBody}\" | mail -s \"TeraGrid Custom Query Request\" inca@sdsc.edu"/>
<% String emailStr = (String)pageContext.getAttribute("email");
   String[] shmail = {"/bin/sh", "-c", emailStr};
   Runtime.getRuntime().exec(shmail); %>
</body>
</html> 
