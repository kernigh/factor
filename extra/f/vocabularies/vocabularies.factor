! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs kernel strings f.dictionary f.words ;
IN: f.vocabularies

TUPLE: vocabulary < identity-tuple name words ;

: <vocabulary> ( name -- vocabulary )
    vocabulary new
        swap >>name
        H{ } clone >>words ;

: add-word-to-vocabulary ( word vocabulary -- )
    [ [ ] [ name>> ] bi ] [ words>> ] bi* set-at ;

: add-parsing-word ( vocabulary name quot -- )
    <parsing-word> dup vocabulary>> add-word-to-vocabulary ;

GENERIC: vocabulary-name ( object -- string )
M: vocabulary vocabulary-name name>> ;
M: string vocabulary-name ;

GENERIC: vocabulary-words ( object -- sequence )
M: f vocabulary-words ;
M: object vocabulary-words lookup-vocabulary vocabulary-words ;
M: vocabulary vocabulary-words words>> ;
