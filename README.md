Infection
======

##### Limitations

The project, as currently implemented, has several limitations.
One of the most glaring (linear space constraints) comes from the Realm framework, which I used as the data storage mechanism for the project (in part to try out new technology, and in part because it promised to solve some of these problems). Due to current limitations in Realm's faulting and fetching mechanism, there is no way to filter a property of an array objects without them being faulted into memory.
Another limitation is the inability of the `limitedInfection` method to find an optimal solution. Unlike the first limitation, this is one which I do not anticipate solving easily, as it is a generalization of the knapsack problem.