iSPI: Investigating Search Patterns in Interfaces
=================================================

This is the code for an experiment to investigate how people search for objects in interfaces.
(Where do they look? What patterns do they follow?)

The experiment was originally designed for the Brown University class [CS 295J][]: Cognition, Human-Computer Interaction and Visual Analysis.

There are a couple of versions of the experiment (see the different branches of the repo).

You can see it live and try it out (and help us collect data!) at:
http://ispi.cs.brown.edu/

[CS 295J]: http://cs.brown.edu/courses/csci2950-j.html


Dependencies
------------
To run the code, you will need:

- [node.js](http://nodejs.org/) (tested with versions 0.4.11 through 0.6.4)
- [redis](http://redis.io/) (tested with versions 2.4.4+)

The following node modules are also necessary.
They can be most easily obtained using [npm](http://npmjs.org/).

- [socket.io](http://socket.io/) (tested with 0.8+)
- [connect](http://senchalabs.github.com/connect/) (tested with 1.8.5)
- [redis](https://github.com/mranney/node_redis) (tested with 0.7.1)

Additionally, you will need [CoffeeScript](http://jashkenas.github.com/coffee-script/) to compile the code.
