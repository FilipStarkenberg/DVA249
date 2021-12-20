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
    echo
}
#hello
groupmanage(){
    echo
}

dirmanage(){
    echo "Directory management"
    echo
    echo "What do you want to do?"
    echo
    [1] echo "Create Directory"
    [2] echo "List Directory content"
    [3] echo "List and change attribute of directory"
    [4] echo "Delete Directory"
    echo
    echo -n "Please select number 1-4>"
    read -p  selection

    if [[ "$selection" == "1" ]]; then
      echo -n "input name of the directory>"
      read DIRNAME
      mkdir $DIRNAME
      echo "Directory created!"
      
    elif  [[ "$selection" == "2" ]]; then
    echo -n "enter name of Directory to list>"
    read DIRNAME 
    echo "$DIRNAME content: "
    cd $DIRNAME && ls

    elif [[ "$selection" == "3" ]]; then
    echo "What do you want to list/change?"
    echo
    [1] Owner of directory
    [2] Group of directory
    [3] Permissions of Directory
    [4] Sticky bit
    [5] Setgid
    [6] Last modified
echo 
echo -n "Please select number 1-6>"
 read -p  selection

    if [[ "$selection" == "1" ]]; then
    echo -n "Please enter id of the new owner and filename>"
    read $1,$2
    chown $1 $2
    echo " Ownership changed!"
    elif [[ "$selection" == "2" ]]; then
echo -n "Please enter new group id and filename>"
read $1, $2
chown :$1 $2
echo "Group changed!"
    elif [[ "$selection" == "3" ]]; then
    echo -n "Enter directory name you want to change permissions for>"
    read filename
    echo "Change permissions:"
    echo "for:"
    echo "read only = 4"
    echo "write only = 2"
    echo "execute only = 1"
    echo "read and execute = 5"
    echo "read and write = 6"
    echo "read, write and execute = 7"
    echo
    echo "Please enter permissions as a number for:"
    echo -n "Owner/user>"
    read $1
    echo -n "Group>"
    read $2
    echo -n "Others>"
    read $3
echo 
chmod $1$2$3 $name
echo "Permissions changed!"
    elif [[ "$selection" == "4" ]]; then

    elif [[ "$selection" == "5" ]]; then

    elif [[ "$selection" == "6" ]]; then


    elif [[ "$selection" == "4" ]]; then
    echo -n "Enter directory name to delete>"
    read $DIRNAME
    rmdir $DIRNAME
    echo " Directory deleted!"
    else
    echo "invalid input!"
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