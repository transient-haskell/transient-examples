Transient examples
==================

Latest examples for [transient](https://github.com/transient-haskell/transient), ]transient-universe](https://github.com/transient-haskell/transient-universe) and [ghcjs-hplay](https://github.com/transient-haskell/ghcjs-hplay)

Some features, like the REST API are only available in the test branches of the github repositories

Most of the examples compile and execute straight ahead without need to install the libraries. You need [docker](http://docker.com) installed

To execute the transient main examples (non distributed examples)

     ./MainSamples.hs

To execute the main distributed example, a web application with widgets for map-reduce and distributed chat, using two nodes:

     ./distributedApps.hs  -p start/<docker ip>/8080
     ./distributedApps.hs  -p start/<docker ip>/8081/add/<docker ip>/8080/y

(acces to any of the nodes invoking http://<docker ip>/port


To execute the REST API example:

     ./api.hs  -p start/<docker ip>/8080

To execute the map-reduce example:

     ./DistrbDataSets.hs
