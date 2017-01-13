#!bin/sh
function trapper(){
  trap '' INT QUIT TSTP TERM HUB
}
function menu(){
        cat <<-EOF
==============Host List==============
        1-172.16.1.7/24
        2-172.16.1.8/24
        0-Exit system
=====================================
        EOF
}
function host(){
    case "$1" in
      1)
        ssh $USER@172.16.1.7
      ;;
      2)
        ssh $USER@172.16.1.8
      ;;
      0)
        exit 0
      esac
}
function main(){
   while true
     do
        trapper
        clear
        menu
        read -p "Pls input your choice:" num
        host $num
     done
}
main
