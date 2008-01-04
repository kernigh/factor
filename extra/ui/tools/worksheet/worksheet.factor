! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: ui ui.gadgets.panes ui.gadgets.scrollers
ui.gadgets.editors ui.gadgets ui.gestures ui.commands kernel io
io.streams.duplex io.styles threads continuations listener
ui.tools.worksheet.editor hashtables sequences ;
IN: ui.tools.worksheet

TUPLE: worksheet history ;

: <worksheet> ( -- gadget )
    <scrolling-pane> V{ } clone
    { set-delegate set-worksheet-history } worksheet construct ;

TUPLE: worksheet-stream ;

: <worksheet-stream> ( worksheet -- stream )
    <pane-stream> worksheet-stream construct-delegate ;

: write-input ( string stream -- )
    [
        dup <input> presented associate
        [ write ] with-nesting
        nl
    ] with-stream* ;

: add-worksheet-editor ( stream -- editor )
    <worksheet-editor>
    dup rot write-gadget
    dup request-focus
    dup scroll>bottom ;

: add-history ( string stream -- )
    pane-stream-pane worksheet-history push ;

: finish-worksheet-editor ( editor stream -- )
    >r dup unparent editor-string r>
    2dup add-history write-input ;

: with-worksheet-editor ( stream quot -- obj )
    over >r
    >r add-worksheet-editor r> keep
    r> finish-worksheet-editor ; inline

M: worksheet-stream stream-readln ( stream -- line )
    [ stream-readln ] with-worksheet-editor ;

M: worksheet-stream stream-read-quot ( stream -- quot )
    [ stream-read-quot ] with-worksheet-editor ;

M: worksheet-stream stream-read-partial ( count stream -- quot )
    [ stream-read-partial ] with-worksheet-editor ;

M: worksheet-stream stream-read ( count stream -- quot )
    [ stream-read ] with-worksheet-editor ;

: worksheet-window ( -- )
    <worksheet> dup <scroller> "Listener" open-window
    <worksheet-stream> [ [ listener ] in-thread ] with-stream* ;
