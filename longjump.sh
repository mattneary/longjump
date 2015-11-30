#!/bin/bash
dir=$(mktemp -d "/tmp/longjump.XXXXX.XXXXX")
fifo="$dir/fifo"
mkfifo "$fifo"

tmux_session=`tmux display-message -p '#S'`

has_buffers() {
  tmux list-windows -t "$tmux_session" -F '#{window_index}' | while read window; do
    tmux list-panes -t "test:$window" -F '#{pane_index} #{pane_pid}' | while read pane; do
      pid=`echo "$pane" | cut -d' ' -f 2`
      tasks=`pgrep -P $pid`
      for task in $tasks; do
        vim=`ps $task | sed 1d | grep '[A-Z]+' | grep 'Vim' | cut -d' ' -f 1`
        if [ $vim ]; then
          return 1
        fi
      done
    done
  done
  return 0
}

buffers() {
  (while : ; do
    read x < "$fifo";
    if [ "$x" = "done" ]; then
      exit 0
    else
      echo "$x"
    fi
  done) &
  tmux list-windows -t "$tmux_session" -F '#{window_index}' | while read window; do
    tmux list-panes -t "test:$window" -F '#{pane_index} #{pane_pid}' | while read pane; do
      pane_num=`echo "$pane" | cut -d' ' -f 1`
      pid=`echo "$pane" | cut -d' ' -f 2`
      tasks=`pgrep -P $pid`
      for task in $tasks; do
        vim=`ps $task | sed 1d | grep '[A-Z]+' | grep 'Vim' | cut -d' ' -f 1`
        if [ $vim ]; then
          tmux send-keys -t "test:$window.$pane_num" Escape ":call BroadcastBuffers('$window', '$pane_num', '$fifo')" Enter
        fi
      done
    done
  done
}

if ! has_buffers; then
  echo "None"
else
  selection=$(buffers | selecta)
  tmux_window=`echo "$selection" | cut -f 1`
  tmux_pane=`echo "$selection" | cut -f 2`
  vim_pane=`echo "$selection" | cut -f 3`
  tmux select-window -t $tmux_window
  tmux select-pane -t $tmux_pane
  tmux send-keys Escape ":b$vim_pane" Enter
fi

