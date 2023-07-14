#!/bin/sh

BLANK='#00000000'
CLEAR='#ffffff22'
DEFAULT='#8651c9'
TEXT='#8651c9'
TEST='#ff0000'
TEXT_WRONG='#ff0000'
WRONG='#282D3F'
VERIFYING='#8651c9'

i3lock \
--insidever-color=$CLEAR     \
--ringver-color=$VERIFYING   \
\
--insidewrong-color=$BLANK   \
--ringwrong-color=$TEXT_WRONG     \
\
--inside-color=$BLANK        \
--ring-color=$DEFAULT        \
--line-color=$BLANK          \
--separator-color=$DEFAULT   \
\
--verif-color=$TEXT          \
--wrong-color=$TEXT_WRONG          \
--time-color=$TEXT           \
--date-color=$TEXT           \
--layout-color=$TEXT         \
--keyhl-color=$WRONG         \
--bshl-color=$WRONG          \
\
--screen 1                   \
--blur 3                     \
--clock                      \
--indicator                  \
--time-str="%H:%M:%S"        \
--date-str="%A, %Y-%m-%d"       \
#--keylayout 1                \
