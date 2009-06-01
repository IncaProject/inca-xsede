<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="inca" tagdir="/WEB-INF/tags/inca" %>


<jsp:include page="header.jsp"/>
<c:set var="usage">
  Description:  Adds series comments to DB

  Usage: addKnowledgeBase.jsp?nickname=tgresid-version-4.2.0&amp;reporter=cluster.admin.tgresid.version[&amp;error=error message&amp;author=Kate Ericson&amp;email=kericson@sdsc.edu&amp;text=new content to add to knowledge base]

  where

  nickname = series nickname (e.g. tgresid-version-4.2.0)

  reporter = reporter name (e.g. cluster.admin.tgresid.version)

  error = error message for the series

  author = the person adding to the knowledge base

  email = email of the person adding to the knowledge base
  
  text = the text to add to the knowledge base
</c:set>
<c:set var="error">
  ${empty param.nickname ? 'Missing param nickname' : '' }
  ${empty param.reporter ? 'Missing param reporter' : '' }
</c:set>
<c:if test="${error != ''}">
  <jsp:forward page="error.jsp">
    <jsp:param name="msg" value="${error}" />
    <jsp:param name="usage" value="${usage}" />
  </jsp:forward>
</c:if>

<c:choose>
  <c:when test="${empty param.author or empty param.text or empty param.email or
		param.author == '' or param.text == '' or param.email == ''}">
    <table cellpadding="4">
      <tr><td>
        <h3>New knowledge base text for the "${param.nickname}" series</h3>
        <p>Please email ${initParam.dbEmail} with problems using this form.</p>
      </td></tr>
      <form method="post" action="addKnowledgeBase.jsp">
        <tr><td class="header">Text:</td></tr>
        <tr>
          <td>
            <c:set var="printError">Error message:
------------
${param.error}
------------
            </c:set>
            <c:set var="errorMessage">${empty param.error ? '': printError}</c:set>
            <textarea name="text" cols="50" rows="20">${empty param.text ?  errorMessage : param.text}</textarea><br/>
          </td>
        </tr>
        <tr><td class="header">Name:</td></tr>
        <tr>
          <td>
            <input name="author" type="text" size="50" value="${param.author}">
            <br/>
          </td>
        </tr>
        <tr><td class="header">Email:</td></tr>
        <tr>
          <td>
            <input name="email" type="text" size="50" value="${param.email}">
            <br/>
          </td>
        </tr>
        <tr><td>
          <input type="hidden" name="nickname" value="${param.nickname}"/>
          <input type="hidden" name="reporter" value="${param.reporter}"/>
          <input type="hidden" name="error" value="${param.error}"/>
          <input type="submit" value="add to knowledge base"/>
        </td></tr>
      </form>
    </table>
  </c:when>
  <c:otherwise>
    <inca:date var="date" dateFormat="MM-dd-yy, K:mm a (zz)"/>
    <p>The following knowlwdge base text has been submitted.  Please email
        ${initParam.dbEmail} with any problems.
      <br><br><b>Date:</b> ${date}
      <br><br><b>Author:</b> ${param.author}
      <br><br><b>Email:</b> ${param.email}
      <br><br><b>Text:</b> <pre> ${param.text} </pre></p>
    <c:set var="subject" 
           value="New knowledge base text for ${param.nickname} from Inca form"/>
    <c:set var="email" value="echo \"AUTHOR: ${param.author}

EMAIL: ${param.email}


KEYWORDS: ${param.nickname} ${param.reporter} ${param.error}


TEXT: ${param.text} \" | mail -s \"${subject}\" \"${initParam.kbEmail}\""/>

    <% String emailStr = (String)pageContext.getAttribute("email");
      String[] shmail = {"/bin/sh", "-c", emailStr};
      Runtime.getRuntime().exec(shmail); %>
  </c:otherwise>
</c:choose>
<jsp:include page="footer.jsp"/>
