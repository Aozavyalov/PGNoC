# Torus connection generator algorithm

This table writed for torus with 25 nodes and 5 nodes in line (h_size):
```
-0--21--------------3----
2-0---1--------------3---
-2-0---1--------------3--
--2-0---1--------------3-
0--2-----1--------------3
3-----0--21--------------
-3---2-0---1-------------
--3---2-0---1------------
---3---2-0---1-----------
----30--2-----1----------
-----3-----0--21---------
------3---2-0---1--------
-------3---2-0---1-------
--------3---2-0---1------
---------30--2-----1-----
----------3-----0--21----
-----------3---2-0---1---
------------3---2-0---1--
-------------3---2-0---1-
--------------30--2-----1
1--------------3-----0--2
-1--------------3---2-0--
--1--------------3---2-0-
---1--------------3---2-0
----1--------------30--2-
```
Row means a source node index(sw_src), column - a destination node index(sw_dst). Number means port, that connect source node with destination.

Table is symmetrical, so we can connect 0 port with 2 and 2 to 0 at the same time. Also it works with 1 and 3 ports.
_________________________

## Conditions of connections

0 to 2: (sw_dst == sw_src + 1 and sw_src % h_size != h_size - 1) or (sw_src % h_size == h_size - 1 and sw_src-sw_dst-h_size+1 == 0)

1 to 3: sw_dst == sw_src + h_size or nodes_num - sw_src + sw_dst == h_size

Conditions can be pasted to a python script to check if it works.
