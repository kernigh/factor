! Copyright (C) 2009, 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays combinators db db.orm furnace.actions
furnace.db html.forms http.server.dispatchers
http.server.responses io.encodings.utf8 io.files io.pathnames
kernel mason.notify.server mason.platform mason.report
math.order present sequences sorting splitting urls validators
xml.syntax xml.writer
accessors furnace.auth furnace.db
http.server.dispatchers mason.server webapps.mason.grids
webapps.mason.make-release webapps.mason.package
FROM: assocs => at keys values ;
IN: webapps.mason

TUPLE: mason-app < dispatcher ;

SYMBOL: can-make-releases?

can-make-releases? define-capability

: <mason-app> ( -- dispatcher )
    mason-app new-dispatcher
    <build-report-action>
        "report" add-responder

    <download-package-action>
        { mason-app "download-package" } >>template
        "package" add-responder

    <download-release-action>
        { mason-app "download-release" } >>template
        "release" add-responder

    <downloads-action>
        { mason-app "downloads" } >>template
        "downloads" add-responder

    <make-release-action>
        { mason-app "make-release" } >>template
        <protected>
            "make releases" >>description
            { can-make-releases? } >>capabilities
        "make-release" add-responder

    <status-update-action>
        "status-update" add-responder ;
