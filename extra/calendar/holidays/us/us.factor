! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs calendar calendar.holidays
calendar.holidays.private combinators combinators.short-circuit
fry kernel lexer math namespaces parser sequences 
vocabs words ;
IN: calendar.holidays.us

SINGLETONS: us us-federal ;

<PRIVATE

: adjust-federal-holiday ( timestamp -- timestamp' )
    {
        { [ dup saturday? ] [ 1 days time- ] }
        { [ dup sunday? ] [ 1 days time+ ] }
        [ ]
    } cond ;

PRIVATE>

M: us-federal holidays
    region-holidays
    ! [ execute( timestamp -- timestamp' ) adjust-federal-holiday ] with map ;
    [
        [ execute( timestamp -- timestamp' ) adjust-federal-holiday ]
        [ drop ] 2bi same-day?
    ] with filter ;


: us-post-office-open? ( timestamp -- ? )
    { [ sunday? not ] [ us-federal holiday? not ] } 1&& ;

HOLIDAY: new-years-day january 1 >>day ;
HOLIDAY-NAME: new-years-day world "New Year's Day"
HOLIDAY-NAME: new-years-day us-federal "New Year's Day"
HOLIDAY-NAME: new-years-day us "New Year's Day"

HOLIDAY: martin-luther-king-day january 3 monday-of-month ;
HOLIDAY-NAME: martin-luther-king-day us-federal "Martin Luther King Day"
HOLIDAY-NAME: martin-luther-king-day us "Martin Luther King Day"

HOLIDAY: inauguration-day january 20 >>day [ dup 4 neg rem + ] change-year ;
HOLIDAY-NAME: inauguration-day us "Inauguration Day"

HOLIDAY: washingtons-birthday february 3 monday-of-month ;
HOLIDAY-NAME: washingtons-birthday us-federal "Washington's Birthday"
HOLIDAY-NAME: washingtons-birthday us "Washington's Birthday"

HOLIDAY: memorial-day may last-monday-of-month ;
HOLIDAY-NAME: memorial-day us-federal "Memorial Day"
HOLIDAY-NAME: memorial-day us "Memorial Day"

HOLIDAY: independence-day july 4 >>day ;
HOLIDAY-NAME: independence-day us-federal "Independence Day"
HOLIDAY-NAME: independence-day us "Independence Day"

HOLIDAY: labor-day september 1 monday-of-month ;
HOLIDAY-NAME: labor-day us-federal "Labor Day"
HOLIDAY-NAME: labor-day us "Labor Day"

HOLIDAY: columbus-day october 2 monday-of-month ;
HOLIDAY-NAME: columbus-day us-federal "Columbus Day"
HOLIDAY-NAME: columbus-day us "Columbus Day"

! Armistice Day is a world holiday with a different name in the US
HOLIDAY-NAME: armistice-day us-federal "Veterans Day"
HOLIDAY-NAME: armistice-day us "Veterans Day"

HOLIDAY: thanksgiving-day november 4 thursday-of-month ;
HOLIDAY-NAME: thanksgiving-day us-federal "Thanksgiving Day"
HOLIDAY-NAME: thanksgiving-day us "Thanksgiving Day"

HOLIDAY: christmas-day december 25 >>day ;
HOLIDAY-NAME: christmas-day world "Christmas Day"
HOLIDAY-NAME: christmas-day us-federal "Christmas Day"
HOLIDAY-NAME: christmas-day us "Christmas Day"

HOLIDAY: belly-laugh-day january 24 >>day ;
HOLIDAY-NAME: belly-laugh-day us "Belly Laugh Day"

HOLIDAY: groundhog-day february 2 >>day ;
HOLIDAY-NAME: groundhog-day us "Groundhog Day"

HOLIDAY: lincolns-birthday february 12 >>day ;
HOLIDAY-NAME: lincolns-birthday us "Lincoln's Birthday"

HOLIDAY: valentines-day february 14 >>day ;
HOLIDAY-NAME: valentines-day us "Valentine's Day"

HOLIDAY: st-patricks-day march 17 >>day ;
HOLIDAY-NAME: st-patricks-day us "Saint Patrick's Day"

HOLIDAY: ash-wednesday easter 46 days time- ;
HOLIDAY-NAME: ash-wednesday us "Ash Wednesday"

ALIAS: first-day-of-lent ash-wednesday

HOLIDAY: fat-tuesday ash-wednesday 1 days time- ;
HOLIDAY-NAME: fat-tuesday us "Fat Tuesday"

HOLIDAY: good-friday easter 2 days time- ;
HOLIDAY-NAME: good-friday us "Good Friday"

HOLIDAY: tax-day april 15 >>day ;
HOLIDAY-NAME: tax-day us "Tax Day"

HOLIDAY: earth-day april 22 >>day ;
HOLIDAY-NAME: earth-day us "Earth Day"

HOLIDAY: administrative-professionals-day april last-saturday-of-month wednesday ;
HOLIDAY-NAME: administrative-professionals-day us "Administrative Professionals' Day"

HOLIDAY: cinco-de-mayo may 5 >>day ;
HOLIDAY-NAME: cinco-de-mayo us "Cinco de Mayo"

HOLIDAY: mothers-day may 2 sunday-of-month ;
HOLIDAY-NAME: mothers-day us "Mothers' Day"

HOLIDAY: armed-forces-day may 3 saturday-of-month ;
HOLIDAY-NAME: armed-forces-day us "Armed Forces Day"

HOLIDAY: flag-day june 14 >>day ;
HOLIDAY-NAME: flag-day us "Flag Day"

HOLIDAY: parents-day july 4 sunday-of-month ;
HOLIDAY-NAME: parents-day us "Parents' Day"

HOLIDAY: grandparents-day labor-day 1 weeks time+ ;
HOLIDAY-NAME: grandparents-day us "Grandparents' Day"

HOLIDAY: patriot-day september 11 >>day ;
HOLIDAY-NAME: patriot-day us "Patriot Day"

HOLIDAY: stepfamily-day september 16 >>day ;
HOLIDAY-NAME: stepfamily-day us "Stepfamily Day"

HOLIDAY: citizenship-day september 17 >>day ;
HOLIDAY-NAME: citizenship-day us "Citizenship Day"

HOLIDAY: boss-day october 16 >>day ;
HOLIDAY-NAME: boss-day us "Boss Day"

HOLIDAY: sweetest-day october 3 saturday-of-month ;
HOLIDAY-NAME: sweetest-day us "Sweetest Day"

HOLIDAY: halloween october 31 >>day ;
HOLIDAY-NAME: halloween us "Halloween"

HOLIDAY: election-day november 1 monday-of-month 1 days time+ ;
HOLIDAY-NAME: election-day us "Election Day"

HOLIDAY: black-friday thanksgiving-day 1 days time+ ;
HOLIDAY-NAME: black-friday us "Black Friday"

HOLIDAY: pearl-harbor-remembrance-day december 7 >>day ;
HOLIDAY-NAME: pearl-harbor-remembrance-day us "Pearl Harbor Remembrance Day"

HOLIDAY: new-years-eve december 31 >>day ;
HOLIDAY-NAME: new-years-eve us "New Year's Eve"
