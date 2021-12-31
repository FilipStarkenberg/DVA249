#!/bin/bash

#Todo:
# Application name layout
# Colors to sub menu names
# Add custom errors
# 
# 

logpath="/var/log/systemmanager/"
logfilename="output.log"

header(){
    clear
    echo "########################################################"
    echo "                  SYSTEM MANAGER v1.0.0                 "
    echo "########################################################"
    echo
}


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
    header
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
    read -p "Press enter to continue..." temp
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

selectgroup(){
    for (( i=0; i < ${#groups[@]}; i++ )); do
        echo "$i: ${groups[i]}"
    done
    re='^[0-9]+$'
    read -p 'Select or enter group name: ' selectedgroup
    if [[ $selectedgroup =~ $re ]]; then
        selectedgroup=${groups[selectedgroup]}
    fi
}

printuserprops(){
    groups=( $( cat /etc/group | grep $selecteduser | cut -d ":" -f 1 ) )
    echo "User properties: $selecteduser"
    echo
    echo "User:           $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 1 )"
    echo "Password:       $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 2 )"
    echo "User ID:        $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 3 )"
    echo "Group ID:       $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 4 )"
    echo "Comment:        $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 5 )"
    echo "Directory:      $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 6 )"
    echo "Shell:          $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 7 )"
    echo
    echo "Groups:  ${groups[@]}"
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
        adduser $newuser --gecos "$comments" --shell "$shell" $ch &> /dev/null
        errorcode=$?
        if [[ $errorcode -eq 0 ]]; then
            echo "User $selecteduser deleted."
        else
            #Handle errors here
            echo "Error: $errorcode"
        fi
    else
        adduser $newuser --gecos "$comments" --shell "$shell" &> /dev/null
        errorcode=$?
        if [[ $errorcode -eq 0 ]]; then
            echo "User $selecteduser deleted."
        else
            #Handle errors here
            echo "Error: $errorcode"
        fi
    fi
}

modifyuserid(){
    echo "Enter new user ID. Must be between $uidmin and $uidmax. "
    read -p '> ' newuserid
    re='^[0-9]+$'
    if ! [[ $newuserid =~ $re ]]; then
        echo "Please enter an integer. "
        return 1
    fi
    if [[ $newuserid < $uidmin || $newuserid > $uidmax ]]; then
        echo "User ID must be between $uidmin and $uidmax. "
        return 2
    fi
    existingids=( $( cat /etc/passwd | cut -d ":" -f 3 ) )
    if [[ " ${existingids[*]} " =~ " ${newuserid} " ]]; then
        echo "ID is alredy ocupied."
    else
        usermod -u "$newuserid" $selecteduser &> /dev/null
        errorcode=$?
        if [[ $errorcode -eq 0 ]]; then
            echo "User $selecteduser deleted."
        else
            #Handle errors here
            echo "Error: $errorcode"
        fi
    fi
}

modifyuser(){
    while true; do
        header
        
        echo "Currently modifying user: $selecteduser"
        echo 
        echo "What do you want to do?"
        echo
        echo "[u] Change username. "
        echo "[p] Change password. "
        echo "[i] Change user id. "
        echo "[g] Change primary group id. "
        echo "[c] Change comment. "
        echo "[d] Change home directory. "
        echo "[s] Change shell. "
        echo "[e] Go back. "
        read -p '> ' selection

        if [[ "$selection" == "u" ]]; then
            clear
            echo "Enter new username: "
            read -p '> ' newusername
            usermod -l $newusername $selecteduser &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo "User $selecteduser deleted."
            else
                #Handle errors here
                echo "Error: $errorcode"
            fi
            selecteduser=$newusername
        elif [[ "$selection" == "p" ]]; then
            clear
            passwd $selecteduser 
        elif [[ "$selection" == "i" ]]; then
            modifyuserid
        elif [[ "$selection" == "g" ]]; then
            echo "Enter new primary group: "
            read -p '> ' newgroup
            usermod -g "$newgroup" $selecteduser &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo "User $selecteduser deleted."
            else
                #Handle errors here
                echo "Error: $errorcode"
            fi
        elif [[ "$selection" == "c" ]]; then
            echo "Enter new comment: "
            read -p '> ' newcomment
            usermod -c "$newcomment" $selecteduser &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo "User $selecteduser deleted."
            else
                #Handle errors here
                echo "Error: $errorcode"
            fi
        elif [[ "$selection" == "d" ]]; then
            echo "Enter new home directory. "
            read -p '> ' newhome
            usermod -d "$newhome" -m $selecteduser &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo "User $selecteduser deleted."
            else
                #Handle errors here
                echo "Error: $errorcode"
            fi
        elif [[ "$selection" == "s" ]]; then
            echo "Enter path to new shell: "
            read -p '> ' newshell
            if [[ ! -f $newshell ]]; then
                echo "'$newshell' does not exist. "
            else
                usermod -s "$newshell" $selecteduser &> /dev/null
                errorcode=$?
                if [[ $errorcode -eq 0 ]]; then
                    echo "User $selecteduser deleted."
                else
                    #Handle errors here
                    echo "Error: $errorcode"
                fi
            fi
        elif [[ "$selection" == "e" ]]; then
            break
        else
            echo "invalid input."
        fi
        echo
        read -p "Press enter to continue..." temp
    done
}

getgroups(){
    gidmin=$(grep "^GID_MIN" /etc/login.defs)
    gidmax=$(grep "^GID_MAX" /etc/login.defs)
    gidmin=$( echo "${gidmin##GID_MIN}" | sed -e 's/^[[:space:]]*//' )
    gidmax=$( echo "${gidmax##GID_MAX}" | sed -e 's/^[[:space:]]*//' )

    groups=( $( awk -F':' -v "min=$gidmin" -v "max=$gidmax" '{ if ( $3 >= min && $3 <= max) print $0 }' "/etc/group" | cut -d ":" -f 1) )
}

getusers(){
    uidmin=$(grep "^UID_MIN" /etc/login.defs)
    uidmax=$(grep "^UID_MAX" /etc/login.defs)
    uidmin=$( echo "${uidmin##UID_MIN}" | sed -e 's/^[[:space:]]*//' )
    uidmax=$( echo "${uidmax##UID_MAX}" | sed -e 's/^[[:space:]]*//' )

    users=( $( awk -F':' -v "min=$uidmin" -v "max=$uidmax" '{ if ( $3 >= min && $3 <= max  && $7 != "/sbin/nologin" ) print $0 }' "/etc/passwd" | cut -d ":" -f 1) )
}

usermanage(){
    while true; do
        header
        
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

        getusers

        read -p '> ' selection
        
        #list users
        if [[ "$selection" == "l" ]]; then
            header
            echo "Users: "
            for user in ${users[@]}; do
                echo "    $user"
            done
        #User properties
        elif [[ "$selection" == "p" ]]; then
            header
            selectuser
            header
            if [[ ! " ${users[*]} " =~ " ${selecteduser} " ]]; then
                echo "Please select an existing user. "
            else
                printuserprops
            fi
        #Modify user
        elif [[ "$selection" == "m" ]]; then
            header
            selectuser
            header
            if [[ ! " ${users[*]} " =~ " ${selecteduser} " ]]; then
                echo "Please select an existing user. "
            else
                modifyuser
            fi
        #Delete user
        elif [[ "$selection" == "d" ]]; then
            header
            selectuser
            header
            if [[ ! " ${users[*]} " =~ " ${selecteduser} " ]]; then
                echo "Please select an existing user."
            else
                deleteuser
            fi
        #Add user
        elif [[ "$selection" == "a" ]]; then
            header
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

deletegroup(){
    echo "Are you sure you want to delete the group: $selectedgroup?[y/n]"
    yesno
    if [[ $? -eq 1 ]]; then
        echo "Deleting group: $selectedgroup ..."
        groupdel $selectedgroup &> /dev/null
        errorcode=$?
        if [[ $errorcode -eq 0 ]]; then
            echo "Group $selectedgroup deleted."
        else
            #Handle errors here
            echo "Error: $errorcode"
        fi
    fi
}


groupmanage(){
    while true; do
        header
        
        echo "Group management"
        echo 
        echo "What do you want to do?"
        echo
        echo "[c] Ceate new group. "
        echo "[l] List all groups, not system groups. "
        echo "[v] List all users in a group. "
        echo "[a] Add user to group. "
        echo "[r] Remove user from group. "
        echo "[d] Delete group. "
        echo "[e] Go back. "

        getusers
        getgroups

        read -p '> ' selection

        #Create new group
        if [[ "$selection" == "c" ]]; then
            echo "Enter new group name: "
            read -p '> ' newgroupname
            addgroup $newgroupname &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo "Group $newgroupname created."
            else
                #Handle errors here
                echo "Error: $errorcode"
            fi
        #List all groups
        elif [[ "$selection" == "l" ]]; then
            header
            echo "Groups: "
            for group in ${groups[@]}; do
                echo "    $group"
            done 
        #List all users in a group
        elif [[ "$selection" == "v" ]]; then
            header
            selectgroup
            header
            groupid=$(cat /etc/group | awk "/$selectedgroup:/ {print}" | cut -d ":" -f 3)
            usersingroup=( $( cat /etc/passwd | sed 'y/:/ /' | awk -v "gid=$groupid" '$4 == gid {print}' | cut -d ":" -f 1 ) )
            usersingroup+=( $( cat /etc/group | awk "/$selectedgroup:/ {print}" | cut -d ":" -f 4 | sed 'y/,/ /' ) )
            
            echo "Users in group: $selectedgroup"
            for user in ${usersingroup[@]}; do
                echo "    $user"
            done
            echo
        #Add an existing user to an existing group
        elif [[ "$selection" == "a" ]]; then
            header
            selectgroup
            header
            selectuser
            adduser $selecteduser $selectedgroup &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo "$selecteduser added to $selectedgroup."
            else
                #Handle errors here
                echo "Error: $errorcode"
            fi
        #Remove existing user from existing group
        elif [[ "$selection" == "r" ]]; then
            header
            selectgroup
            header
            groupid=$(cat /etc/group | awk "/$selectedgroup:/ {print}" | cut -d ":" -f 3)
            usersingroup=( $( cat /etc/passwd | sed 'y/:/ /' | awk -v "gid=$groupid" '$4 == gid {print}' | cut -d ":" -f 1 ) )
            usersingroup+=( $( cat /etc/group | awk "/$selectedgroup:/ {print}" | cut -d ":" -f 4 | sed 'y/,/ /' ) )
            users=( ${usersingroup[@]} )
            selectuser
            deluser $selecteduser $selectedgroup &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo "$selecteduser removed from $selectedgroup."
            else
                #Handle errors here
                echo "Error: $errorcode"
            fi
        elif [[ "$selection" == "d" ]]; then
            header
            selectgroup
            header
            if [[ ! " ${groups[*]} " =~ " ${selectedgroup} " ]]; then
                echo "Please select an existing user."
            else
                deletegroup
            fi
        elif [[ "$selection" == "e" ]]; then
            break
        else
            echo "invalid input."
        fi
        read -p "Press enter to continue..." temp
    done
}
#hi
dirmanage(){
    while true; do
        header
        echo "Directory management"
        echo
        echo "What do you want to do?"
        echo
        echo "[c] Create Directory"
        echo "[l] List Directory content"
        echo "[a] List and change attribute of directory"
        echo "[d] Delete Directory"
        echo
        echo -n " > "
        read selection

        if [[ "$selection" == "c" ]]; then
            echo -n "input name of the new directory> "
            read DIRNAME
            mkdir $DIRNAME
            echo "Directory created!"
            read -p "Press enter to continue>" temp
        elif  [[ "$selection" == "l" ]]; then
            echo -n "enter name of Directory to list>"
            read DIRNAME 
            echo "$DIRNAME content: "
            ls $DIRNAME
            read -p "Press enter to continue>" temp

        elif [[ "$selection" == "a" ]]; then
            echo "What do you want to list/change?"
            echo
            echo "[o] Owner of directory"
            echo "[g] Group of directory"
            echo "[p] Permissions of Directory"
            echo "[s] Sticky bit"
            echo "[g] Setgid"
            echo "[m] Last modified"
            echo 
            echo -n " > "
            read  Selection
    
            if [[ "$Selection" == "o" ]]; then
                echo -n "Please enter id of the new owner>"
                read owner
                echo -n "Enter directory name>"
                read dirname
                chown $owner $dirname
                echo " Ownership changed!"
            elif [[ "$Selection" == "g" ]]; then
                echo -n "Please enter new group name>"
                read group
                echo -n "Enter directory name>"
                read dirname
                chown :$group $dirname
                echo "Group changed!"
            elif [[ "$Selection" == "p" ]]; then
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
                read -p "Press enter to continue>" temp

            elif [[ "$Selection" == "s" ]]; then
                echo

            elif [[ "$Selection" == "g" ]]; then
                echo
            elif [[ "$Selection" == "m" ]]; then
                echo
            else
                echo "Invalid input!"
            fi


        elif [[ "$selection" == "d" ]]; then
            echo -n "Enter directory name to delete> "
            read $dirname
            rmdir $dirname
            echo " Directory deleted!"
            read -p "Press enter to continue>" temp

        else
            echo "Invalid input!"
    fi
    done
}

mainmenu(){
    while true; do
        header
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
    done
}

#Main entry point for the application
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

mainmenu