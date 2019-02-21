alias g='grep --color'
alias l='ls -lF --color'
alias la='l -a'
# sort by mod time (t), newest last (r)
alias lt='l -tr'
alias ltf='l -tr --full-time'
# list and sort by creation time
alias lc='l -trc'
alias lcf='l -trc --full-time'
alias psg='ps -e x -o ppid -o pid -o pgid -o tty -o vsz -o rss -o etime -o cputime -o rgroup -o ni -o fname -o args | grep'
alias psgc='psg cache_dirs'
alias pst='ps -fja'
alias ptuniq='pstree -p | sed "s/[0-9]//g" | uniq'
alias df='df -h'
alias pmem='ps aux | awk "{sum +=\$6}; END {print sum}"'
# diff -ruNp dir1 dir2 | less 
alias mdiff='diff -ruNp'
