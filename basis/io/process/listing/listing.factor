! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs kernel math math.statistics sequences
system ;
IN: io.process.listing

TUPLE: process-entry id parent-id ;

HOOK: process-group* os ( id -- seq )
GENERIC: process-group ( obj -- seq )
M: process-entry process-group id>> process-group* ;
M: integer process-group process-group* ;

HOOK: terminate-process* os ( obj -- )
GENERIC: terminate-process ( obj -- )
M: process-entry terminate-process id>> terminate-process* ;
M: integer terminate-process terminate-process* ;

: all-descendants ( process-entry/id -- seq )
    [ ] [ process-group ] bi remove ;

: kill-process-group ( process-entry/id -- )
    process-group [ terminate-process ] each ;
    
: kill-all-descendants ( process-entry/id -- )
    all-descendants [ terminate-process ] each ;
    
HOOK: all-running-processes os ( -- seq )

: all-process-trees ( -- seq )
    all-running-processes [ dup process-group ] H{ } map>assoc ;
    
: process-id-trees ( -- id-hash parent-id-hash )
    all-running-processes
    [ [ [ [ ] [ id>> ] bi ] dip push-at ] sequence>hashtable ]
    [ [ [ [ ] [ parent-id>> ] bi ] dip push-at ] sequence>hashtable ] bi ;
