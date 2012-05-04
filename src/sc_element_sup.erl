-module(sc_element_sup).
-behaviour(supervisor).

-export([start_link/0, start_child/2]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

start_child(Key, Value) ->
    supervisor:start_child(?SERVER, [Key, Value]).

init([]) ->
    RestartStrategy = simple_one_for_one,
    MaxRestarts = 0,
    MaxSeconds = 1,
    
    SupFlags = {RestartStrategy, MaxRestarts, MaxSeconds},
    Restart = temporary,
    Type = worker,
    Shutdown = brutal_kill,
    
    AChild = {sc_element,
	      {sc_element, start_link, []},
	      Restart, Shutdown, Type, [sc_element]},
    {ok, {SupFlags, [AChild]}}.
