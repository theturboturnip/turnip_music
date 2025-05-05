// The Player exposes a Queue
// 
// A Queue is based in a (user-defined?) state machine made of QueueGenerators.
// Each QueueGenerator emits Songs into the Queue,
// and may at some point yield to the next QueueGenerator in the state machine.
// The QueueGenerator may also at any time clear() its upcoming items from the Queue 
// and reset them with new ones (e.g. a geolocation-based generator may detect the user is in a new location
// and repopulate the queue with new songs for that location).
