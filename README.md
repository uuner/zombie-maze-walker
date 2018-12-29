# Zombie-maze-walker

The objective of the game is to exit the maze avoiding the zombies.

To play the game with the default maze open a terminal window 
and run the script:

```
./zombie-maze-walker.sh
```

To play with some other maze pass the name of maze file
in its first argument. For example:
```
./zombie-maze-walker.sh smallmaze.txt
```

## Requirements

The game should run on any system with bash and GNU sed
and standard Unix tools.

## Screenshot

```
+--+--+--+--+--+
|  |     |     |
+  +  +  +--+  +
|  |  |   Z  > |
+  +Z +--+  +  +
|  |  |  |  |  |
+  +  +  +  +  +
|     |     |  |
+--+--+--+--+  +
|               
+--+--+--+--+--+
```

## Building a custom maze

You can build your own maze. The game assumes the maze is of rectangular shape,
so keep the length of all lines equal. The character is represented by one of 
``><^v`` characters. Zombies are one of the ``udlr`` letters. The exit must
be on the outer border.
