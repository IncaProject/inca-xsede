# Configuration script for docbook source.  Usage:
#    configure [--with-html=<dir>]

AC_INIT(Makefile.inc.in)
AC_PROG_MAKE_SET
TOP_DIR=`pwd`

dnl #########################################################################
dnl Check for docbook.dsl file (i.e., DSSSL templates)
dnl #########################################################################
AC_ARG_WITH(templates,
	[  --with-templates        location of Norman Walsh's DocBook templates],
	[DSSSL_PATH=${withval}],
	[DSSSL_PATH=""]
)
if test "${DSSSL_PATH}" = ""; then
	STYLESHEETS=`locate docbook.dsl`
	for sheet in ${STYLESHEETS}; do
		file=`echo $sheet | grep html`
		dir=`echo $file | sed 's/\/html\/docbook.dsl//'`
		if test "${dir}" != ""; then
			DSSSL_PATH=${dir};
		fi
	done 
	if test "${DSSSL_PATH}" = ""; then
		echo "Unable to locate docbook DSSSL templates";
		echo "Run with --with-templates=<docbook.dsl path> option";
		exit;
	fi
fi

dnl #########################################################################
dnl Check for docbook-toys
dnl #########################################################################

AC_ARG_WITH(dbtools,
	[  --with-dbtools          location of docbook conversion tools (db2pdf,db2html or docbook2pdf, docbook2html)],
	[DBTOOLS=${withval}],
	[DBTOOLS=$PATH]
)
AC_PATH_PROGS(DB2HTML,db2html docbook2html,no,$DBTOOLS)
if test "$DB2HTML" = "no";then
	AC_MSG_WARN(unable to locate 'db2html' or 'docbook2html' in path.)
fi
AC_PATH_PROGS(DB2PDF,db2pdf docbook2pdf,no,$DBTOOLS)
if test "$DB2PDF" = "no";then
	AC_MSG_WARN(unable to locate 'db2pdf' or 'docbook2pdf' in path.)
fi
AC_PATH_PROGS(DB2RTF,db2rtf docbook2rtf,no,$DBTOOLS)
if test "$DB2RTF" = "no";then
	AC_MSG_WARN(unable to locate 'db2rtf' or 'docbook2rtf' in path.)
fi
if test "$DB2RTF" = "no" || test "$DB2HTML" = "no" || test "$DB2PDF" = "no";then
	AC_MSG_ERROR(Unable to locate all required doc tools.  Run with the --with-dbtools=<path> option)
fi

VERSION=`${DB2HTML} -v | grep jw`
if test "${VERSION}" = "";  then
	STYLE_OPTION="-s"
	HTML_MODE=""
	PDF_MODE=""
	#OUTPUT=""
else
	STYLE_OPTION="-d"
	HTML_MODE="\#html"
	PDF_MODE="\#print"
	#OUTPUT='-o $*'
fi

dnl #########################################################################
dnl get a list of possible documents
dnl #########################################################################
DOCLIST=`ls src | grep .sgml`
TARGETS=`echo ${DOCLIST} | sed 's/\.sgml//g' | sed 's/\entities//g'` 

dnl #########################################################################
dnl Write files
dnl #########################################################################
AC_SUBST(DSSSL_PATH)
AC_SUBST(DB2HTML)
AC_SUBST(DB2PDF)
AC_SUBST(DB2RTF)
AC_SUBST(STYLE_OPTION)
AC_SUBST(HTML_MODE)
AC_SUBST(PDF_MODE)
AC_SUBST(TOP_DIR)
#AC_SUBST(OUTPUT)
AC_SUBST(TARGETS)

AC_OUTPUT(Makefile.inc config/ldp.dsl)
