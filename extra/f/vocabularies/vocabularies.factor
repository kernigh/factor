! Copyright (C) 2011 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs kernel strings f.dictionary ;
IN: f.vocabularies

TUPLE: vocabulary < identity-tuple name words ;

: <vocabulary> ( name -- vocabulary )
    vocabulary new
        swap >>name
        H{ } clone >>words ;

: add-word-to-vocabulary ( word vocabulary -- )
    [ [ ] [ name>> ] bi ] [ words>> ] bi* set-at ;

GENERIC: vocabulary-name ( object -- string )
M: vocabulary vocabulary-name name>> ;
M: string vocabulary-name ;

GENERIC: vocabulary-words ( object -- sequence )
M: f vocabulary-words ;
M: object vocabulary-words lookup-vocabulary vocabulary-words ;
M: vocabulary vocabulary-words words>> ;

