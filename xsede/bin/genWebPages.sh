#!/bin/sh

err=""
date=`date`
webdir=/misc/inca/install-2r5/var/jetty1/webapp/

s=$webdir/summary.html
stmp=$webdir/summary.html.tmp

i=$webdir/inst.html
itmp=$webdir/inst.html.tmp

c3=$webdir/ctssv3-expanded.html
c3tmp=$webdir/ctssv3-expanded.html.tmp
c3graph=$webdir/ctssv3-graph.html
c3graphtmp=$webdir/ctssv3-graph.html.tmp
c3map=$webdir/ctssv3-map.html
c3maptmp=$webdir/ctssv3-map.html.tmp
c3jsp="http://sapa.sdsc.edu:8080/inca/xslt.jsp?resourceID=teragrid-login&suiteName=ctss"
c3xml="&xmlFile=ctssv3.xml"
c3url=$c3jsp$c3xml

c4=$webdir/ctssv4.html
c4tmp=$webdir/ctssv4.html.tmp
c4test=$webdir/ctssv4-test.html
c4testtmp=$webdir/ctssv4-test.html.tmp
c4graph=$webdir/ctssv4-graph.html
c4graphtmp=$webdir/ctssv4-graph.html.tmp
c4map=$webdir/ctssv4-map.html
c4maptmp=$webdir/ctssv4-map.html.tmp
c4jsp="http://sapa.sdsc.edu:8080/inca/xslt.jsp?suiteName=core.teragrid.org-4.0.0,data-management.teragrid.org-4.0.0,data-movement.teragrid.org-4.1.0,remote-compute.teragrid.org-3.0.0,remote-compute.teragrid.org-4.0.0,login.teragrid.org-4.0.0,app-support.teragrid.org-4.0.0,parallel-app.teragrid.org-4.0.0,workflow.teragrid.org-4.0.0,vtss.teragrid.org-3.0.0&resourceID=core.teragrid.org-4.0.0,data-management.teragrid.org-4.0.0,data-movement.teragrid.org-4.1.0,remote-compute.teragrid.org-3.0.0,remote-compute.teragrid.org-4.0.0,login.teragrid.org-4.0.0,app-support.teragrid.org-4.0.0,parallel-app.teragrid.org-4.0.0,workflow.teragrid.org-4.0.0,vtss.teragrid.org-3.0.0"
c4xml="&xmlFile=core.teragrid.org-4.0.0.xml,data-management.teragrid.org-4.0.0.xml,data-movement.teragrid.org-4.1.0.xml,remote-compute.teragrid.org-3.0.0.xml,remote-compute.teragrid.org-4.0.0.xml,login.teragrid.org-4.0.0.xml,app-support.teragrid.org-4.0.0.xml,parallel-app.teragrid.org-4.0.0.xml,workflow.teragrid.org-4.0.0.xml,vtss.teragrid.org-3.0.0.xml"
c4url=$c4jsp$c4xml

# get instance
START=$(date +%s)
wget -o /dev/null -O $itmp "http://sapa.sdsc.edu:8080/inca/xslt.jsp?xsl=instance.xsl&instanceID=2135390&configID=1150026"
END=$(date +%s)
if ( test $? -ne 0 ); then
  ierr="$err instance "
  err=$ierr
fi
if (test -f $itmp && grep "inca-powered-by.jpg" $itmp > /dev/null); then
  mv $itmp $i
else
  ierr="$err instance-logo "
  err=$ierr
fi
DIFF=$(expr $END - $START)
echo $END: $DIFF >> ${HOME}/logs/instanceTime.log

countPostgres=`ps awwx | grep postgres | wc -l`
echo $countPostgres >> ${HOME}/logs/postgresCount.log
maxPostgres=60
if ( test $countPostgres -gt $maxPostgres ); then
  date | mail -s "postgres count is $countPostgres (over $maxPostgres processes)" inca@sdsc.edu
fi

# get summary page
echo "$date = $?" >> ${HOME}/logs/genWebPages.log
wget -o /dev/null -O $stmp "http://sapa.sdsc.edu:8080/inca/xslt.jsp?xmlFile=ctssv3.xml&xsl=summary.xsl&resourceID=teragrid-login&suiteName=ctss"
if ( test $? -ne 0 ); then
  sumerr="$err summary "
  err=$sumerr
fi
if (test -f $stmp && grep "inca-powered-by.jpg" $stmp > /dev/null); then
  mv $stmp $s
else
  sumerr="$err summary-logo "
  err=$sumerr
fi


# get ctssv3 expanded page with old results marked
echo "$date = $?" >> ${HOME}/logs/genWebPages.log
curl -o $c3tmp $c3url"&xsl=swStack.xsl" > /dev/null 2>&1
if ( test $? -ne 0 ); then
  ctsseerr="$err ctssv3 "
  err=$ctsseerr
fi
if (test -f $c3tmp && grep "inca-powered-by.jpg" $c3tmp > /dev/null); then
  mv $c3tmp $c3
else
  ctsseerr="$err ctssv3-logo "
  err=$ctsseerr
fi
# get ctssv3 graph page
echo "$date = $?" >> ${HOME}/logs/genWebPages.log
wget -o /dev/null -O $c3graphtmp $c3url"&xsl=graph.xsl"
if ( test $? -ne 0 ); then
  ctssGerr="$err ctssv3-graph "
  err=$ctssGerr
fi
if (test -f $c3graphtmp && grep "inca-powered-by.jpg" $c3graphtmp > /dev/null); then
  mv $c3graphtmp $c3graph
else
  ctssGerr="$err ctssv3-graph "
  err=$ctssGerr
fi
# get ctssv3 map page
echo "$date = $?" >> ${HOME}/logs/genWebPages.log
wget -o /dev/null -O $c3maptmp $c3jsp"&xmlFile=google.xml&xsl=google.xsl"
if ( test $? -ne 0 ); then
  ctssMerr="$err ctssv3-map "
  err=$ctssMerr
fi
if (test -f $c3maptmp && grep "inca-powered-by.jpg" $c3maptmp > /dev/null); then
  mv $c3maptmp $c3map
else
  ctssMerr="$err ctssv3-map "
  err=$ctssMerr
fi

# get ctssv4 expanded page with old results marked
echo "$date = $?" >> ${HOME}/logs/genWebPages.log
wget -o /dev/null -O $c4tmp $c4url"&xsl=ctssv4.xsl"
if ( test $? -ne 0 ); then
  ctsseerr="$err ctssv4 "
  err=$ctsseerr
fi
if (test -f $c4tmp && grep "inca-powered-by.jpg" $c4tmp > /dev/null); then
  mv $c4tmp $c4
else
  ctsseerr="$err ctssv4-logo "
  err=$ctsseerr
fi

# get ctssv4 test kit
echo "$date = $?" >> ${HOME}/logs/genWebPages.log
wget -o /dev/null -O $c4testtmp "http://sapa.sdsc.edu:8080/inca/xslt.jsp?supportLevel=testing&suiteName=remote-compute.teragrid.org-4.0.0,login.teragrid.org-4.0.0&resourceID=remote-compute.teragrid.org-4.0.0,login.teragrid.org-4.0.0&xmlFile=remote-compute.teragrid.org-4.0.0.xml,login.teragrid.org-4.0.0.xml&xsl=ctssv4.xsl"
if ( test $? -ne 0 ); then
  ctss4testerr="$err ctssv4-test "
  err=$ctss4testerr
fi
if (test -f $c4testtmp && grep "inca-powered-by.jpg" $c4testtmp > /dev/null); then
  mv $c4testtmp $c4test
else
  ctss4testerr="$err ctssv4-test-logo "
  err=$ctss4testerr
fi
if [ "$err" != "" ]; then
  date | mail -s "can't generate $err page" inca@sdsc.edu
fi

# get ctssv4 graph page
echo "$date = $?" >> ${HOME}/logs/genWebPages.log
wget -o /dev/null -O $c4graphtmp $c4url"&xsl=graph.xsl"
if ( test $? -ne 0 ); then
  ctss4err="$err ctssv4-graph "
  err=$ctss4err
fi
if (test -f $c4graphtmp && grep "inca-powered-by.jpg" $c4graphtmp > /dev/null); then
  mv $c4graphtmp $c4graph
else
  ctss4err="$err ctssv4-graph "
  err=$ctss4err
fi
# get ctssv4 map page
echo "$date = $?" >> ${HOME}/logs/genWebPages.log
wget -o /dev/null -O $c4maptmp $c4jsp"&xmlFile=google.xml&xsl=google.xsl"
if ( test $? -ne 0 ); then
  ctss4err="$err ctssv4-map "
  err=$ctss4err
fi
if (test -f $c4maptmp && grep "inca-powered-by.jpg" $c4maptmp > /dev/null); then
  mv $c4maptmp $c4map
else
  ctss4err="$err ctssv4-map "
  err=$ctss4err
fi
