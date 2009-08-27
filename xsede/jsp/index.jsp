<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="inca" tagdir="/WEB-INF/tags/inca" %>


<jsp:include page="header.jsp"/>
<script language="JavaScript" type="text/JavaScript">
<!--
function MM_preloadImages() { //v3.0
  var d=document; if(d.images){ if(!d.MM_p) d.MM_p=new Array();
    var i,j=d.MM_p.length,a=MM_preloadImages.arguments; for(i=0; i<a.length; i++)
    if (a[i].indexOf("#")!=0){ d.MM_p[j]=new Image; d.MM_p[j++].src=a[i];}}
}

function MM_swapImgRestore() { //v3.0
  var i,x,a=document.MM_sr; for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) x.src=x.oSrc;
}

function MM_findObj(n, d) { //v4.01
  var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {
    d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}
  if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];
  for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layers[i].document);
  if(!x && d.getElementById) x=d.getElementById(n); return x;
}

function MM_swapImage() { //v3.0
  var i,j=0,x,a=MM_swapImage.arguments; document.MM_sr=new Array; for(i=0;i<(a.length-2);i+=3)
   if ((x=MM_findObj(a[i]))!=null){document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];}
}
//-->
</script>
<body onLoad="MM_preloadImages('../img/homepage/related-test-histories.jpg','../img/homepage/weekly-status-report.jpg','../img/homepage/error-history-summary.jpg','../img/homepage/resource-status-history.jpg','../img/homepage/test-status-by-package-and-resource.jpg','../img/homepage/cumulative-test-status-by-resource.jpg','../img/homepage/individual-test-result-details.jpg','../img/homepage/individual-test-history.jpg')">

<table xmlns:sdf="java.text.SimpleDateFormat" xmlns:date="java.util.Date" xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes" width="100%" border="0"><tr align="left"><td><h1 class="body">Inca Status Pages for TeraGrid</h1></td></tr></table>

                        <p><strong> New!</strong> System administrators can execute tests from &quot;Individual Test Result Details&quot; pages by clicking on the &quot;Run Now&quot; button. (April 2009)</p>
                        <p>Status pages show TeraGrid's health as monitored using <a href="http://inca.sdsc.edu/">Inca</a>.  All pages are linked from the drop down menu at the top right of this page. </p>
                        <img src="../img/homepage/wheel-of-views.jpg" alt="Inca Status Pages" name="Image1" border="0" usemap="#Map" id="Image1">
                        <map name="Map">
                          <area shape="rect" coords="121,342,260,480" href="http://cuzco.sdsc.edu:8085/cgi-bin/lead.cgi" alt="Related Test Histories" onMouseOver="MM_swapImage('Image1','','../img/homepage/related-test-histories.jpg',1)" onMouseOut="MM_swapImgRestore()">
                          <area shape="rect" coords="433,20,579,163" href="summary.jsp" alt="Weekly Status Report" onMouseOver="MM_swapImage('Image1','','../img/homepage/weekly-status-report.jpg',1)" onMouseOut="MM_swapImgRestore()">
                          <area shape="rect" coords="116,171,263,318" href="status.jsp?xsl=seriesSummary.xsl&xml=weekSummary.xml&queryNames=incaQueryStatus" alt="Error History Summary" onMouseOver="MM_swapImage('Image1','','../img/homepage/error-history-summary.jpg',1)" onMouseOut="MM_swapImgRestore()">
                          <area shape="rect" coords="221,21,376,161" href="../html/reports/summaryHistoryByResource/" alt="Resource Status History" onMouseOver="MM_swapImage('Image1','','../img/homepage/resource-status-history.jpg',1)" onMouseOut="MM_swapImgRestore()">
                          <area shape="rect" coords="656,261,802,417" href="../html/ctssv4.html" alt="Test Status by Package & Resource" onMouseOver="MM_swapImage('Image1','','../img/homepage/test-status-by-package-and-resource.jpg',1)" onMouseOut="MM_swapImgRestore()">
                          <area shape="rect" coords="621,62,772,224" href="http://sapa.sdsc.edu:8080/inca/html/ctssv3-map.html" alt="Cumulative Test Status by Resource" onMouseOver="MM_swapImage('Image1','','../img/homepage/cumulative-test-status-by-resource.jpg',1)" onMouseOut="MM_swapImgRestore()">
                          <area shape="rect" coords="505,430,678,568" alt="Individual Test Result Details" onMouseOver="MM_swapImage('Image1','','../img/homepage/individual-test-result-details.jpg',1)" onMouseOut="MM_swapImgRestore()">
                          <area shape="rect" coords="297,427,451,570" alt="Individual Test History" onMouseOver="MM_swapImage('Image1','','../img/homepage/individual-test-history.jpg',1)" onMouseOut="MM_swapImgRestore()">
</map>
                        <br/>


                        <jsp:include page="footer.jsp"/>
