#!/usr/bin/env bash

MAZEFILE=`dirname $0`/maze.txt
REPLAY=false

while getopts "f:ri" opt; do
  case "$opt" in
    r)   REPLAY=true
         LOG=$(tempfile) || exit;;
    f)   MAZEFILE="$OPTARG";;
    i)   INVERTWALLS='s/[^><^vuldr ]/[7m&[m/g';;
    [?]) cat <<- EOF
		Usage: $0 [OPTION] [-f mazefile]"
		  -f filename 
		        use the custom maze file. Default: maze.txt
		  -r    replay mode. Print the replay command at the end.
		  -i    invert wall colors.
		EOF
         exit 1;;
  esac
done

if [ ! -f "$MAZEFILE" ]; then
  echo Maze file "$MAZEFILE" was not found.
  exit 1
fi

IFS=''

while read line; do
  new=$(wc -c <<< "$line")
  if [[ -n "$prev" ]] && [[ ! "$new" = "$prev" ]]; then
    echo "Lines of the maze must have equal length. Please fix."
    exit 1
  fi
  prev=$new
done < "$MAZEFILE"

MAZE=$(sed 's#[/\\]#\\&#g;s#^#s/$/#;s#$#~/#;$s#~/$#/#' "$MAZEFILE")

GAMEFILE=$(tempfile) || exit
trap '{ $REPLAY && echo To rerun "\"sed -nf $GAMEFILE < $LOG\"" || rm -f $GAMEFILE; }' EXIT

WIDTH=$(read line < $MAZEFILE; echo -n "$line" | wc -c)

cat << EOF > $GAMEFILE

#!/bin/sed -nf

1{
s/.*//
$MAZE
h; b display
}

/^\(\[A\)\|w/{x; s/[><v]/^/; x; b next;}
/^\(\[B\)\|s/{x; s/[><^]/v/; x; b next;}
/^\(\[D\)\|a/{x; s/[>^v]/</; x; b next;}
/^\(\[C\)\|d/{x; s/[<v^]/>/; x; b next;}

:next

x
# Losing condition #1 - you walk into a zombie
/\([udlr]\(.\{$WIDTH\}\)\^\)\|\(v\(.\{$WIDTH\}\)[udlr]\)\|\(>[udlr]\|[udlr]<\)/{
s/$/&~ZOMBIE SAYS YUM!!!/
x
b display
}
# character movements
s/ \(.\{$WIDTH\}\)\^/^\1 /
s/v\(.\{$WIDTH\}\) / \1v/
s/> / >/
s/ </< /

# Losing condition #2 - a zombie walks into you
/\([><v^].\{$WIDTH\}u\)\|\(d.\{$WIDTH\}[><v^]\)\|\(r[><v^]\)\|\([><v^]l\)/{
s/$/&~YUM BRAINZZZ!!!/
x
b display
}

# nemesis movements
# turning around
s/\(\([^ ].\{$WIDTH\}\)\|\(^.\{,$WIDTH\}\)\)u/\1d/g
s/d\(\(.\{$WIDTH\}[^ ]\|\(.\{,$WIDTH\}\)$\)\)/u\1/g
s/r\([^ ]\|~\|$\)/l\1/g
s/\([^ ]\|~\|^\)l/\1r/g

# moving
s/ \(.\{$WIDTH\}\)u/u\1 /g
s/d\(.\{$WIDTH\}\) / \1d/g
s/r / r/g
s/ l/l /g

# winning condition
/\(^[^~]*\^\)\|\(v[^~]*$\)\|\(>~\)\|\(~<\)\|\(^<\)\|\(>$\)/s/$/~YOU WON!!! HAVE A COOKIE/

x
:display
g
s/~/\\
/g

$INVERTWALLS
s/[><^v]/[1;36m&[m/g
s/[udlr]/[1;32mZ[m/g

i\\
[2J[H
p
/!/q

EOF
#-------------
# Play phase 

mytime="`date +%s`"

export LC_ALL="C"
(while true; do
  read -s -t 1 -n 1 TMP
  RES=$?
  CMD="$TMP"
  if [ "$CMD" == '' ]; then
    read -s -n 1 TMP; CMD="$CMD$TMP"
    if [ "$CMD" == '[' ]; then
      read -s -n 1 TMP; CMD="$CMD$TMP"
    fi
  fi
  if [ $RES -eq 0 ]; then
    echo "$CMD"
    continue
  fi
  mytimenew="`date +%s`"
  if [ "$mytimenew" != "$mytime" ]; then
    echo
    mytime=$mytimenew
  fi
done) | ( $REPLAY && tee "$LOG" || cat ) | sed -nf $GAMEFILE
