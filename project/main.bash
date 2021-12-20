#!/bin/bash

#Todo:
# Application name layout
# Colors to sub menu names
# Suppress command outputs
# Add custom errors
#

yesno(){
    while true; do
        read -p '> ' yn
        case $yn in
            [Yy]* ) return 1;;
            [Nn]* ) return 0;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

netinfo(){
    clear
    echo "Network information"
    echo 
    echo "Computer name:  $HOSTNAME"
    echo
    devices=( $( ip link | awk '/: / && !/: lo/ {print $2}' | sed 'y/:/ /' ) )
    echo "Network devices: "
    echo
    for device in ${devices[@]}; do
        echo "$device: "
        echo "  IP address:           $( ip addr show $device | awk '/inet / {print $2}' )"
        echo "  Mac adddress:         $( ip addr show $device | awk '/link\// {print $2}' )"
        echo "  Default gateway:      $( ip r | awk "/default via / && /$device/ {print \$3}" )"
        echo "  Device status:        $( ip link show $device | awk '/: / && !/: lo/ {print $9}' )"
        echo
    done
}

selectuser(){
    for (( i=0; i < ${#users[@]}; i++ )); do
        echo "$i: ${users[i]}"
    done
    re='^[0-9]+$'
    read -p 'Select or enter user name: ' selecteduser
    if [[ $selecteduser =~ $re ]]; then
        selecteduser=${users[selecteduser]}
    fi

}

printuserprops(){
    props=( $( cat "/etc/passwd" | grep $selecteduser | sed "y/:/\n/" ) )
    groups=( $( cat /etc/group | grep $selecteduser | cut -d ":" -f 1 ) )
    echo "User properties: $selecteduser"
    echo
    echo "User:           ${props[0]}"
    echo "Password:       ${props[1]}"
    echo "User ID:        ${props[2]}"
    echo "Group ID:       ${props[3]}"
    echo "Comment:        ${props[4]}"
    echo "Directory:      ${props[5]}"
    echo "Shell:          ${props[6]}"
    echo
    echo "Groups: ${groups[@]}"
}

deleteuser(){
    echo "Are you sure you want to delete the user: $selecteduser?[y/n]"
    yesno
    if [[ $? -eq 1 ]]; then
        echo "Deleting user: $selecteduser ..."
        userdel -r $selecteduser &> /dev/null
        errorcode=$?
        if [[ $errorcode -eq 0 ]]; then
            echo "User $selecteduser deleted."
        else
            #Handle errors here
            echo "Error: $errorcode"
        fi
    fi
}

createuser(){
    echo "New username: "
    read -p '> ' newuser

    echo "Shell (Leave empty to use /bin/bash):"
    read -p '> ' shell
    if [[ "$shell" == "" ]]; then
        shell="/bin/bash"
    else
        if [[ ! -f "$shell" ]]; then
            echo "Shell does not exist. "
            return 1;
        fi
    fi
    echo "Create home directory? [y/n]"
    ch="--no-create-home"
    yesno
    if [[ $? -eq 1 ]]; then
        echo "Enter absolute path or empty for default:"
        read -p '> ' homedir
        if [[ ! "$homedir" == "" ]]; then
            if [[ ! -f "$homedir" ]]; then
                echo "Directory does not exist. "
                echo "Do you want to create it? [y/n]"
                yesno
                if [[ $? -eq 1 ]]; then
                    mkdir -p $homedir &> /dev/null
                    if [[ $? -ne 0 ]]; then
                        echo "Failed to create directory. "
                        return 2;
                    fi
                else
                    return 3;
                fi
            fi
        fi
        ch="--home "$homedir""
    fi
    echo "Comments: "
    read -p '> ' comments

    if ! [[ "$homedir" == "" ]]; then
        adduser $newuser --gecos "$comments" --shell "$shell" $ch
    else
        adduser $newuser --gecos "$comments" --shell "$shell"
    fi
}

usermanage(){
    while true; do
        clear
        
        echo "User management"
        echo 
        echo "What do you want to do?"
        echo
        echo "[a] Add user. "
        echo "[l] List login-users. "
        echo "[p] Display user properties. "
        echo "[m] Modify user. "
        echo "[d] Delete user. "
        echo "[e] Go back. "
        read -p '> ' selection
        uidmin=$(grep "^UID_MIN" /etc/login.defs)
        uidmax=$(grep "^UID_MAX" /etc/login.defs)
        users=( $( awk -F':' -v "min=${uidmin##UID_MIN}" -v "max=${uidmax##UID_MAX}" '{ if ( $3 >= min && $3 <= max  && $7 != "/sbin/nologin" ) print $0 }' "/etc/passwd" | cut -d ":" -f 1) )

        #list users
        if [[ "$selection" == "l" ]]; then
            for user in ${users[@]}; do
                echo $user
            done
        #User properties
        elif [[ "$selection" == "p" ]]; then
            selectuser
            if [[ ! " ${users[*]} " =~ " ${selecteduser} " ]]; then
                echo "invalid input."
            else
                printuserprops
            fi
        #Modify user
        elif [[ "$selection" == "m" ]]; then
            selectuser
            if [[ ! " ${users[*]} " =~ " ${selecteduser} " ]]; then
                echo "invalid input."
            else
                echo
            fi
        #Delete user
        elif [[ "$selection" == "d" ]]; then
            selectuser
            if [[ ! " ${users[*]} " =~ " ${selecteduser} " ]]; then
                echo "invalid input."
            else
                deleteuser
            fi
        #Add user
        elif [[ "$selection" == "a" ]]; then
            createuser
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo "User create sucsessfully. "
            else
                #Fix custom error message here
                echo "Failed to create user. "
            fi
        elif [[ "$selection" == "e" ]]; then
            break
        else
            echo "invalid input."
        fi
        read -p "Press enter to continue..." temp
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
        read -p "Press enter to continue..." temp
    done
}

dirmanage(){
    while true; do
    clear
    echo "Directory management"
    echo
    echo "What do you want to do?"
    echo
    echo  "[1] Create Directory"
    echo " [2] List Directory content"
    echo " [3]List and change attribute of directory"
    echo " [4]Delete Directory"
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
    echo "[1] Owner of directory"
    echo "[2] Group of directory"
    echo "[3] Permissions of Directory"
    echo "[4] Sticky bit"
    echo "[5] Setgid"
    echo "[6] Last modified"
    echo 
    echo -n "Please select number 1-6>"
     read -p  selection
fi
    if [[ "$selection" == "1" ]]; then
    echo -n "Please enter id of the new owner>"
    read owner
    echo -n "Enter directory name>"
    read dirname
    chown $owner $dirname
    echo " Ownership changed!"
    elif [[ "$selection" == "2" ]]; then
 echo -n "Please enter new group name>"
    read group
    echo -n "Enter directory name>"
    read dirname
    chown :$group $dirname

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
    read owner
    echo -n "Group>"
    read group
    echo -n "Others>"
    read others
echo 
chmod $owner$group$others $name
echo "Permissions changed!"
    elif [[ "$selection" == "4" ]]; then
    echo

    elif [[ "$selection" == "5" ]]; then
echo
    elif [[ "$selection" == "6" ]]; then
    echo


    elif [[ "$selection" == "4" ]]; then
    echo -n "Enter directory name to delete>"
    read $DIRNAME
    rmdir $DIRNAME
    echo " Directory deleted!"
    else
    echo "invalid input!"
    fi
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
        read -p "Press enter to continue..." temp
    done
}

#Main entry point for the application
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi
mainmenu