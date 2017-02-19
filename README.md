examples
========

Most of the examples execute. You need [docker](http://docker.com) installed

To execute the transient main examples (non distributed)

> ./MainSamples.hs

To execute the distributed example, a web application with widgets for map-reduce and distributed chat, using two nodes:

> ./distributedApps.hs  -p start/<docker ip>/8080
> ./distributedApps.hs  -p start/<docker ip>/8081/add/<docker ip>/8080/y

(acces to any of the nodes invoking http://<docker ip>/port


To execute the REST API example:

> ./api.hs  -p start/<docker ip>/8080

To execute the map-reduce example:

> ./DistrbDataSets.hs
