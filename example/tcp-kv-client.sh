#!/usr/bin/env bash

sleep() {
  local IFS
  [[ -n "${_pause_fd:-}" ]] || exec {_pause_fd}<> <(:)
  read ${1:+-t "$1"} -u $_pause_fd || :
}

tcp_kv() {
  unset -v tcp_kv
  exec 5<>/dev/tcp/localhost/7777 || return 1
  echo -e "$*" >&5
  IFS= read -t 1 -u 5 tcp_kv
  [ -n "$tcp_kv" ] && return 0 || return 1
}

pipe_kv() {
  unset -v pipe_kv
  local pipe=$1; shift
  exec 5>$pipe.1
  exec 6<$pipe.2
  echo -e "$*" >&5
  IFS= read -r -t 1 -u 6 len
  ((!len)) && return 1
  #echo "len: $len"
  IFS= read -d '' -t 1 -n $len -u 6 pipe_kv
  exec 5>&-
  exec 6<&-
  [ -n "$pipe_kv" ] && return 0 || return 1
}

sleep=${1:-3600}; shift
pipe_pid=${1:-$$}; shift

start=$EPOCHREALTIME
tcp_kv "pipes |$pipe_pid"
pipe=$tcp_kv
printf "pipes |$pipe_pid => %s (%s)\n" "$tcp_kv" $(echo "scale=5; $EPOCHREALTIME - $start" | bc)

start_sleep=$EPOCHSECONDS
sleep $sleep &
sleep_pid=$!
trap "kill $sleep_pid &>/dev/null" INT TERM ABRT QUIT KILL
start=$EPOCHREALTIME
pipe_kv "$pipe" "pids >$sleep_pid" || exit
printf "pids >$sleep_pid => %s (%s)\n" "$pipe_kv" $(echo "scale=5; $EPOCHREALTIME - $start" | bc)
start=$EPOCHREALTIME
pipe_kv "$pipe" "pids <>$pipe_pid" || exit
printf "pids <>$pipe_pid => %s (%s)\n" "$pipe_kv" $(echo "scale=5; $EPOCHREALTIME - $start" | bc)
echo -n "in: "
while kill -0 $sleep_pid &>/dev/null; do
  read -t .1 in
  [ $? -eq 0 ] || continue
  start=$EPOCHREALTIME
  pipe_kv "$pipe" "$in"
  end=$EPOCHREALTIME
  in_res="$pipe_kv"
  pipe_kv "$pipe" "eval $end - $start"
  printf "KV: %s => %s (%s)\n" "$in" "$in_res" "$pipe_kv"
  echo -n "in: "
done

end_sleep=$EPOCHSECONDS
if (($end_sleep - $start_sleep < $sleep)); then
  echo "$sleep_pid exited abnormally"
else
  echo "$sleep_pid exited normally"
fi