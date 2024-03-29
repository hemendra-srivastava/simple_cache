-module(sc_element).
-behaviour(gen_server).
-export([start_link/1, start_link/2, create/1, fetch/1, replace/2, delete/1]).

-export([init/1, handle_call/3, handle_cast/2, terminate/2, handle_info/2, code_change/3]).

-define(SERVER, ?MODULE).
-define(DEFAULT_LEASE_TIME, 60*60*24).

-record(state, {value, lease_time, start_time}).

start_link(Value) ->
    start_link(Value, ?DEFAULT_LEASE_TIME).

start_link(Value, LeaseTime) ->
    gen_server:start_link(?MODULE, [Value, LeaseTime], []).

create(Value, LeaseTime) ->
    sc_element_sup:start_child(Value, LeaseTime).
create(Value) ->
    create(Value, ?DEFAULT_LEASE_TIME).

replace(Pid, Value) ->
    gen_server:cast(Pid, {replace, Value}).

fetch(Pid) ->
    gen_server:call(Pid, fetch).

delete(Pid) ->
    gen_server:cast(Pid, delete).

init([Value, LeaseTime]) ->
       StartTime = calendar:datetime_to_gregorian_seconds(calendar:local_time()),
       {ok, #state{value = Value, lease_time = LeaseTime, start_time = StartTime}, time_left(StartTime, LeaseTime)}.

handle_cast({replace, Value}, State) ->
    #state{lease_time = LeaseTime, start_time = StartTime} = State,
    TimeLeft = time_left(StartTime, LeaseTime),
    {noreply, State#state{value=Value}, TimeLeft};
handle_cast(delete, State) ->
    {stop, normal, State}.

handle_call(fetch, _From, State) ->
    #state{value = Value, lease_time = LeaseTime, start_time = StartTime} = State,
    TimeLeft = time_left(StartTime, LeaseTime),
    {reply, {ok, Value}, State, TimeLeft}.

terminate(_Reason, _State) ->
    sc_store:delete(self()),
    ok.

handle_info(_Msg, State) ->
    {noreply, State}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

time_left(_StartTime, infinity) ->
    infinity;
time_left(StartTime, LeaseTime) ->
    CurTime = calendar:datetime_to_gregorian_seconds(calendar:local_time()),
    TimeDone = CurTime - StartTime,
    case LeaseTime - TimeDone of
	Time when Time =< 0 ->
	    0;
	Time ->
	    Time*1000
    end.
