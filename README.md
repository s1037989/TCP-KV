### TCP-KV

TCP-KV is a simple Key-Value TCP server.  It is intended to be a simple IPC
mechanism and run on the same host as the processes that need the KV store.
One of the main features of TCP-KV is that it monitors a list of processes
and exits if any of them disappear, and also monitors another list of
processes and kills the list any time that TCP-KV exits.
