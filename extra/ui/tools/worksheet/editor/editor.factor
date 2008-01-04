! Copyright (C) 2006, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays assocs combinators continuations documents
ui.tools.debugger hashtables io io.styles kernel math
math.vectors models namespaces parser prettyprint quotations
sequences strings threads listener tuples ui.commands ui.gadgets
ui.gadgets.editors ui.gadgets.presentations ui.gadgets.worlds
ui.gestures definitions ;
IN: ui.tools.worksheet.editor

TUPLE: worksheet-editor continuation quot help ;

: worksheet-editor-use ( interactor -- seq )
    use
    swap worksheet-editor-continuation continuation-name
    assoc-stack ;

: init-caret-help ( worksheet-editor -- )
    dup editor-caret 100 <delay> swap set-worksheet-editor-help ;

: <worksheet-editor> ( -- gadget )
    <source-editor>
    worksheet-editor construct-editor
    [ init-caret-help ] keep ;

M: worksheet-editor graft*
    dup delegate graft*
    dup worksheet-editor-help add-connection ;

M: worksheet-editor ungraft*
    dup dup worksheet-editor-help remove-connection
    delegate ungraft* ;

: word-at-loc ( loc worksheet-editor -- word )
    over [
        [ gadget-model T{ one-word-elt } elt-string ] keep
        worksheet-editor-use assoc-stack
    ] [
        2drop f
    ] if ;

M: worksheet-editor model-changed
    2dup worksheet-editor-help eq? [
        swap model-value over word-at-loc swap show-summary
    ] [
        delegate model-changed
    ] if ;

: worksheet-editor-continue ( obj worksheet-editor -- )
    worksheet-editor-continuation schedule-thread-with ;

: worksheet-editor-eof ( worksheet-editor -- )
    f swap worksheet-editor-continue ;

: evaluate-input ( worksheet-editor -- )
    [
        [ control-value ] keep worksheet-editor-continue
    ] curry in-thread ;

: worksheet-editor-yield ( worksheet-editor -- obj )
    [ set-worksheet-editor-continuation stop ] curry callcc1 ;

M: worksheet-editor stream-readln
    worksheet-editor-yield first ;

M: worksheet-editor stream-read
    swap dup zero? [
        2drop ""
    ] [
        >r stream-readln dup length r> min head
    ] if ;

M: worksheet-editor stream-read-partial
    stream-read ;

: go-to-error ( worksheet-editor error -- )
    dup parse-error-line 1- swap parse-error-col 2array
    over set-caret
    mark>caret ;

: handle-parse-error ( worksheet-editor error -- )
    dup parse-error? [ 2dup go-to-error delegate ] when
    nip debugger-window ;

: try-parse ( lines -- quot/error/f )
    [
        parse-lines-interactive
    ] [
        nip dup delegate unexpected-eof? [ drop f ] when
    ] recover ;

: handle-interactive ( lines worksheet-editor -- quot/f ? )
    swap try-parse {
        { [ dup quotation? ] [ nip t ] }
        { [ dup not ] [ drop "\n" swap user-input f f ] }
        { [ t ] [ handle-parse-error f f ] }
    } cond ;

M: worksheet-editor stream-read-quot
    [ worksheet-editor-yield ] keep
    over quotation? [ drop ] [
        [ handle-interactive ] keep
        swap [ drop ] [ nip stream-read-quot ] if
    ] if ;

M: worksheet-editor pref-dim*
    delegate pref-dim* { 100 0 } vmax ;

: clear-input gadget-model clear-doc ;

worksheet-editor "worksheet-editor" f {
    { T{ key-down f f "RET" } evaluate-input }
    { T{ key-down f { C+ } "k" } clear-input }
} define-command-map
