#!/bin/bash

#Todo:
# Application name layout
# Colors to sub menu names
# 
#
#
#
netinfo(){
    while true; do
        clear
        
        echo "Network information"
        echo 
        echo "What do you want to do?"
        echo
        echo "[n] Display computer Name (host name)"
        echo "[i] Display IP address. "
        echo "[m] Display MAC address. "
        echo "[g] Display Gateway. "
        echo "[s] Display interface Status."
        echo "[e] Go back. "
        read -p '> ' selection

        if [[ "$selection" == "n" ]]; then
        echo
            echo "The computers name is: "
            hostname
            echo
        elif [[ "$selection" == "i" ]]; then
            echo "IP address:"
	        ip addr | awk '/inet / && !/ lo/  {print $2} /: / && !/: lo/ {print $2}'
        elif [[ "$selection" == "m" ]]; then
            echo "Mac adddress:"
	        ip addr | awk '/link\// && !/loopback/ {print $2} /: / && !/: lo/ {print $2}'
        elif [[ "$selection" == "g" ]]; then
            echo
        elif [[ "$selection" == "s" ]]; then
            echo
        elif [[ "$selection" == "e" ]]; then
            break
        else
            echo "invalid input."
        fi
        read -p "Press enter to return to menu..." temp
    done
}

usermanage(){
    while true; do
        clear
        
        echo "User management"
        echo 
        echo "What do you want to do?"
        echo
        echo "[x] xxx"
        echo "[x] xxx"
        echo "[x] xxx"
        echo "[x] xxx"
        echo "[x] xxx"
        echo "[e] Go back. "
        read -p '> ' selection

        if [[ "$selection" == "x" ]]; then
            echo
        elif [[ "$selection" == "x" ]]; then
            echo 
        elif [[ "$selection" == "x" ]]; then
            echo 
        elif [[ "$selection" == "x" ]]; then
            echo
        elif [[ "$selection" == "x" ]]; then
            echo
        elif [[ "$selection" == "e" ]]; then
            break
        else
            echo "invalid input."
        fi
        read -p "Press enter to return to menu..." temp
    done
}

groupmanage(){
    while true; do
        clear
        
        echo "Group management"
        echo 
        echo "What do you want to do?"
        echo
        echo "[x] xxx"
        echo "[x] xxx"
        echo "[x] xxx"
        echo "[x] xxx"
        echo "[x] xxx"
        echo "[e] Go back. "
        read -p '> ' selection

        if [[ "$selection" == "x" ]]; then
            echo
        elif [[ "$selection" == "x" ]]; then
            echo 
        elif [[ "$selection" == "x" ]]; then
            echo 
        elif [[ "$selection" == "x" ]]; then
            echo
        elif [[ "$selection" == "x" ]]; then
            echo
        elif [[ "$selection" == "e" ]]; then
            break
        else
            echo "invalid input."
        fi
        read -p "Press enter to return to menu..." temp
    done
}

dirmanage(){
    while true; do
        clear
        
        echo "Directory management"
        echo 
        echo "What do you want to do?"
        echo
        echo "[x] xxx"
        echo "[x] xxx"
        echo "[x] xxx"
        echo "[x] xxx"
        echo "[x] xxx"
        echo "[e] Go back. "
        read -p '> ' selection

        if [[ "$selection" == "x" ]]; then
            echo
        elif [[ "$selection" == "x" ]]; then
            echo 
        elif [[ "$selection" == "x" ]]; then
            echo 
        elif [[ "$selection" == "x" ]]; then
            echo
        elif [[ "$selection" == "x" ]]; then
            echo
        elif [[ "$selection" == "e" ]]; then
            break
        else
            echo "invalid input."
        fi
        read -p "Press enter to return to menu..." temp
    done
}

mainmenu(){
    while true; do
        clear

        echo "Welcome to this application!"
        echo 
        echo "What do you want to do?"
        echo
        echo "[n] Network information... "
        echo "[u] User management... "
        echo "[g] Group management... "
        echo "[d] Directory management... "
        echo "[e] Exit."
        read -p '> ' selection

        if [[ "$selection" == "n" ]]; then
            netinfo
        elif [[ "$selection" == "u" ]]; then
            usermanage
        elif [[ "$selection" == "g" ]]; then
            groupmanage
        elif [[ "$selection" == "d" ]]; then
            dirmanage
        elif [[ "$selection" == "e" ]]; then
            break
        else
            echo "invalid input."
        fi
        read -p "Press enter to return to menu..." temp
    done
}

#Main entry point for the application
mainmenu