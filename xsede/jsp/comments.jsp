<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="sql.tld" prefix="sql" %>
<%@ taglib uri="c.tld" prefix="c" %>
<%@ taglib uri="inca.tld" prefix="inca" %>
<%@page import="java.net.URL"%>


<html>
<head>
    <link href="css/inca.css" rel="stylesheet" type="text/css"/>
</head>

<%
  String series = request.getParameter("series");
  String host = request.getParameter("host");
  String nickname = request.getParameter("nickname");
  String comment = request.getParameter("comment");
  String author = request.getParameter("author");
  String login = request.getParameter("login");
  String protocol = request.getScheme().toString();



%>
<%@ include file="tgpw.jsp" %>

<% if ( !protocol.equals("https") ) { %>
    <h3>This page requires SSL.</h3>
<% } else {
    if ( author == null || comment == null ||
        (author.equals("") && comment.equals("")) ||
        !login.equals(tgpw) || login == null  ){ %>
        <table cellpadding="4">
            <tr><td><h3>Comment for the "<%=nickname%>" series on <%=host%></h3>
                <p>Please email <a href="mailto:inca@sdsc.edu">inca@sdsc.edu</a>
                with problems using this form.</p>
            </td></tr>
            <form method="post" action="comments.jsp">
            <tr><td class="header">Comment:</td></tr>
            <tr><td><textarea name="comment" cols="50" rows="10"><%=comment%></textarea><br/></td></tr>
            <tr><td class="header">Name or email:</td></tr>
            <tr><td><input name="author" type="text" size="50" value="<%=author%>"><br/></td></tr>
            <tr><td class="header">Password to submit comment:</td></tr>
            <tr><td>(hint: same password as https://repo.teragrid.org)<br/>
                <input name="login" type="password" size="50"><br/></td></tr>
            <tr><td>
                    <input type="hidden" name="series" value="<%=series%>"/>
                    <input type="hidden" name="host" value="<%=host%>"/>
                    <input type="hidden" name="nickname" value="<%=nickname%>"/>
                    <input type="submit" name="Submit" value="add comment"/>
            </td></tr>
            </form>
        </table>
    <% } else {
        java.util.Date date = new java.util.Date();
        java.text.SimpleDateFormat fmt = new java.text.SimpleDateFormat("MM-dd-yy, K:mm a (zz)");
        String entered = fmt.format(date);
        out.println("<p>The following comment has been added.  Please email " +
                "<a href=\"mailto:inca@sdsc.edu\">inca@sdsc.edu</a> with " +
                "any problems.  <br><br><b>Date:</b> " + entered +
                "<br><br><b>Author:</b> " + author +
                "<br><br><b>Comment:</b> <pre>" + comment + "</pre></p>");

        String email = "echo \"Author: " + author + "\n\nComment: " + comment + "\" | mail -s \"New TG Status Page Comment\" inca@sdsc.edu";
        String[] shmail = {"/bin/sh", "-c", email};
        Runtime.getRuntime().exec(shmail);  %>
        <%@ include file="db-connect.jsp" %>
        <sql:update var="insertcomments" dataSource="${tgdb}">
            INSERT INTO incaseriesconfigcomments (incaentered,
            incaseriesconfigid, incaauthor, incacomment)
            VALUES ('<%=entered%>', '<%=series%>', ?, ?);
            <sql:param value="${param['author']}"/>
            <sql:param value="${param['comment']}"/>
        </sql:update>
<%     }
   }%>
</html>
