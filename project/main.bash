#!/bin/bash

mainmenu(){
    clear
    echo "Welcome to this application!"
    echo 
    echo "What do you want to do?"
    echo "[n] Network information... "
    echo "[u] User management... "
    echo "[g] Group management... "
    echo "[d] Directory management... "
    read -p '> ' mainselect
}

while true; do
    mainmenu
    echo $mainselect
    read -p "Press enter to continue..." temp
done