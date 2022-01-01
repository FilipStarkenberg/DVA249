#!/bin/bash

#Todo:
# Add custom errors

######### COLORS! ############

BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'  # No Color

##############################


logpath="/var/log/systemmanager/"
logfilename="output.log"

header(){
    clear
    echo -e "--------------------------------------------------------"
    echo -e "                 ${YELLOW}SYSTEM MANAGER v1.0.0${NC}"
    echo -e "--------------------------------------------------------"
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
    echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}Network information${NC}]"
    echo 
    echo -e "Computer name:  ${CYAN}$HOSTNAME${NC}"
    echo
    devices=( $( ip link | awk '/: / && !/: lo/ {print $2}' | sed 'y/:/ /' ) )
    echo "Network device(s): "
    echo
    for device in ${devices[@]}; do
        echo -e "${RED}$device:${NC}"
        echo -e "${LIGHTRED}  IP address:${NC}           $( ip addr show $device | awk '/inet / {print $2}' )"
        echo -e "${LIGHTRED}  Mac adddress:${NC}         $( ip addr show $device | awk '/link\// {print $2}' )"
        echo -e "${LIGHTRED}  Default gateway:${NC}      $( ip r | awk "/default via / && /$device/ {print \$3}" )"
        echo -e "${LIGHTRED}  Device status:${NC}        $( ip link show $device | awk '/: / && !/: lo/ {print $9}' )"
        echo
    done
    read -p "Press enter to continue..." temp
}

selectuser(){
    for (( i=0; i < ${#users[@]}; i++ )); do
        echo -e "[${RED}$i${NC}] - ${users[i]}"
    done
    re='^[0-9]+$'
    read -p 'Select or enter user name: ' selecteduser
    if [[ $selecteduser =~ $re ]]; then
        selecteduser=${users[selecteduser]}
    fi
}

selectgroup(){
    for (( i=0; i < ${#groups[@]}; i++ )); do
        echo -e "[${RED}$i${NC}] - ${groups[i]}"
    done
    re='^[0-9]+$'
    read -p 'Select or enter group name: ' selectedgroup
    if [[ $selectedgroup =~ $re ]]; then
        selectedgroup=${groups[selectedgroup]}
    fi
}

##Add color
printuserprops(){
    groups=( $( cat /etc/group | grep $selecteduser | cut -d ":" -f 1 ) )
    echo -e "User properties: ${RED}$selecteduser${NC}"
    echo
    echo -e "${RED}User name:${NC}      $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 1 )"
    echo -e "${RED}Password:${NC}       $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 2 )"
    echo -e "${RED}User ID:${NC}        $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 3 )"
    echo -e "${RED}Group ID:${NC}       $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 4 )"
    echo -e "${RED}Comment:${NC}        $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 5 )"
    echo -e "${RED}Directory:${NC}      $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 6 )"
    echo -e "${RED}Shell:${NC}          $( cat /etc/passwd | grep $selecteduser | cut -d ":" -f 7 )"
    echo
    echo -e "Groups:  ${groups[@]}"
}

deleteuser(){
    echo -e "Are you sure you want to delete the user: ${RED}$selecteduser${NC}?[y/n]"
    yesno
    if [[ $? -eq 1 ]]; then
        echo "Deleting user: $selecteduser ..."
        userdel -r $selecteduser &> /dev/null
        errorcode=$?
        if [[ $errorcode -eq 0 ]]; then
            echo "User $selecteduser deleted."
        else
            if [[ $errorcode -eq 6 ]]; then
                echo "  Specified user does not exist. "
            elif [[ $errorcode -eq 8 ]]; then
                echo "  User is currently logged in."
                echo "  Log out user before deleting. "
            elif [[ $errorcode -eq 10 ]]; then
                echo "  Unable to update group file. "
            elif [[ $errorcode -eq 12 ]]; then
                echo "  Unable to delete home directory. "
            else
                echo "  Unknown error. "
            fi
        fi
    fi
}

displaynewuserdata(){
    echo "Creating new user"
    clear
    echo -e "${RED}User name:${NC}      $1"
    echo -e "${RED}Comment:${NC}        $2"
    echo -e "${RED}Directory:${NC}      $3"
    echo -e "${RED}Shell:${NC}          $4"
    echo
}

createuser(){
    displaynewuserdata "" "" "" ""
    echo "New username: "
    read -p '> ' newuser

    if [[ " ${users[*]} " =~ " ${newuser} " ]]; then
        echo "Username is aledy ocupied. "
        return 4
    fi

    displaynewuserdata "$newuser" "" "" ""

    echo "Comment (gecos): "
    read -p '> ' comments

    displaynewuserdata "$newuser" "$comments" "" ""

    echo "Create home directory? [y/n]"
    ch="--no-create-home"
    yesno
    if [[ $? -eq 1 ]]; then
        echo "Enter absolute path or empty for default:"
        read -p '> ' homedir
        if [[ "$homedir" == "" ]]; then
            homedir="/home/$newuser"
        fi
        ch="--home "$homedir""
    fi

    displaynewuserdata "$newuser" "$comments" "$homedir" ""

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
    
    displaynewuserdata "$newuser" "$comments" "$homedir" "$shell"

    adduser $newuser --gecos "$comments" --shell "$shell" $ch

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
            echo -e "Chnged user ID for ${RED}$selecteduser${NC} to ${RED}$newuserid${NC}."
        else
            echo "Unable to change user id. Unknown error. "
        fi
    fi
}

changehomedir(){
    echo "Existing home directories: "
    echo -e "${RED}"
    ls -c1 /home/
    echo -e "${NC}"
    echo "Enter new home directory. "
    read -p '> ' newhome
    re='/'
    if [[ $newhome =~ $re ]]; then
        echo "Name can not contain the character '/'"
        return 1
    fi
    usermod -d "/home/$newhome" -m $selecteduser &> /dev/null
    errorcode=$?
    if [[ $errorcode -eq 0 ]]; then
        echo -e "Switched home for ${RED}$selecteduser${NC} to ${RED}$newhome${NC}."
    else
        #Handle errors here
        echo "Error: $errorcode"
    fi
}

modifyuser(){
    while true; do
        header
        echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}User management${NC}] > [${PURPLE}Modify user${NC}]"
        echo 
        echo -e "Currently modifying user: ${RED}$selecteduser${NC}"
        echo 
        echo -e "What do you want to do?"
        echo
        echo -e "[${RED}u${NC}] - Change username. "
        echo -e "[${RED}p${NC}] - Change password. "
        echo -e "[${RED}i${NC}] - Change user id. "
        echo -e "[${RED}g${NC}] - Change primary group. "
        echo -e "[${RED}c${NC}] - Change comment. "
        echo -e "[${RED}d${NC}] - Change home directory. "
        echo -e "[${RED}s${NC}] - Change shell. "
        echo -e "[${RED}e${NC}] - Go back. "
        read -p '> ' selection

        if [[ "$selection" == "u" ]]; then
            header
            echo "Enter new username: "
            read -p '> ' newusername
            usermod -l $newusername $selecteduser &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo -e "Changed username form ${RED}$selecteduser${NC} to ${RED}$newusername${NC}. "
                selecteduser=$newusername
            else
            echo "Unable to change username:"
                if [[ $errorcode -eq 9 ]]; then
                    echo -e "  Username ${RED}$newusername${NC} is ocupided. "
                else
                    echo "  Unknown error. Code: $errorcode"
                fi
            fi
        elif [[ "$selection" == "p" ]]; then
            header
            passwd $selecteduser 
        elif [[ "$selection" == "i" ]]; then
            modifyuserid
        elif [[ "$selection" == "g" ]]; then
            echo "Enter new primary group: "
            read -p '> ' newgroup
            usermod -g "$newgroup" $selecteduser  &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo -e "Switched primary group for ${RED}$selecteduser${NC} to ${RED}$newgroup${NC}."
            else
                echo "Unable to change primary group:"
                if [[ $errorcode -eq 6 ]]; then
                    echo -e "  Group ${RED}$newgroup${NC} does not exist. "
                else
                    echo "  Unknown error. Code: $errorcode"
                fi
            fi
        elif [[ "$selection" == "c" ]]; then
            header
            echo "Enter new comment: "
            read -p '> ' newcomment
            usermod -c "$newcomment" $selecteduser &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo -e "Set comment for ${RED}$selecteduser${NC} to ${RED}$newcomment${NC}"
            else
                #Handle errors here
                echo "  Unknown error. Code: $errorcode"
            fi
        elif [[ "$selection" == "d" ]]; then
            header
            changehomedir
        elif [[ "$selection" == "s" ]]; then
            header
            echo "Enter path to new shell: "
            read -p '> ' newshell
            if [[ ! -f $newshell ]]; then
                echo "'$newshell' does not exist. "
            else
                usermod -s "$newshell" $selecteduser &> /dev/null
                errorcode=$?
                if [[ $errorcode -eq 0 ]]; then
                    echo -e "Switched shell for ${RED}$selecteduser${NC} to ${RED}$newshell${NC}"
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
        echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}User management${NC}]"
        echo
        echo -e "What do you want to do?"
        echo
        echo -e "[${RED}a${NC}] - Add user. "
        echo -e "[${RED}l${NC}] - List login-users. "
        echo -e "[${RED}p${NC}] - Display user properties. "
        echo -e "[${RED}m${NC}] - Modify user. "
        echo -e "[${RED}d${NC}] - Delete user. "
        echo -e "[${RED}e${NC}] - Go back. "

        getusers

        read -p '> ' selection
        
        #list users
        if [[ "$selection" == "l" ]]; then
            header
            echo -e "${RED}Users:${NC}"
            for user in ${users[@]}; do
                echo -e "    ${LIGHTRED}$user${NC}"
            done
            read -p "Press enter to continue..." temp
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
            read -p "Press enter to continue..." temp
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
            read -p "Press enter to continue..." temp
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
            read -p "Press enter to continue..." temp
        elif [[ "$selection" == "e" ]]; then
            break
        else
            echo "invalid input."
            read -p "Press enter to continue..." temp
        fi
        
    done
}

deletegroup(){
    echo -e "Are you sure you want to delete the group: ${RED}$selectedgroup${NC}?[y/n]"
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
        
        echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}Group management${NC}]"
        echo 
        echo -e "What do you want to do?"
        echo
        echo -e "[${RED}c${NC}] - Ceate new group. "
        echo -e "[${RED}l${NC}] - List all groups, not system groups. "
        echo -e "[${RED}v${NC}] - List all users in a group. "
        echo -e "[${RED}a${NC}] - Add user to group. "
        echo -e "[${RED}r${NC}] - Remove user from group. "
        echo -e "[${RED}d${NC}] - Delete group. "
        echo -e "[${RED}e${NC}] - Go back. "

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
            echo -e "${RED}Groups:${NC}"
            for group in ${groups[@]}; do
                echo -e "    ${LIGHTRED}$group${NC}"
            done 
        #List all users in a group
        elif [[ "$selection" == "v" ]]; then
            header
            selectgroup
            header
            groupid=$(cat /etc/group | awk "/$selectedgroup:/ {print}" | cut -d ":" -f 3)
            usersingroup=( $( cat /etc/passwd | sed 'y/:/ /' | awk -v "gid=$groupid" '$4 == gid {print}' | cut -d ":" -f 1 ) )
            usersingroup+=( $( cat /etc/group | awk "/$selectedgroup:/ {print}" | cut -d ":" -f 4 | sed 'y/,/ /' ) )
            
            echo -e "Users in group ${RED}$selectedgroup${NC}:"
            for user in ${usersingroup[@]}; do
                echo -e "    ${LIGHTRED}$user${NC}"
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
            mkdir $DIRNAME &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo " Directory created succesfully! "
            else
                echo "Failed to create $DIRNAME"
                echo "error: $errorcode"
            fi
            read -p "Press enter to continue>" temp

        elif  [[ "$selection" == "l" ]]; then
            echo -n "enter name of Directory to list> "
            read DIRNAME 
            echo " $DIRNAME content: "
            cd $DIRNAME || ls 
            
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
                sudo chmod $owner$group$others $name
                echo "Permissions changed!"
                read -p "Press enter to continue>" temp

            elif [[ "$Selection" == "s" ]]; then
                echo
                read -p "Press enter to continue>" temp

            elif [[ "$Selection" == "g" ]]; then
                echo
                read -p "Press enter to continue>" temp

            elif [[ "$Selection" == "m" ]]; then
                echo "Enter name of directory > "
                read dirname
                echo " Last modified:"
                ls -lt $dirname
                read -p "Press enter to continue>" temp
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
        echo -e "[${PURPLE}Main menu${NC}]"
        echo 
        echo -e "What do you want to do?"
        echo
        echo -e "[${RED}n${NC}] - Network information... "
        echo -e "[${RED}u${NC}] - User management... "
        echo -e "[${RED}g${NC}] - Group management... "
        echo -e "[${RED}d${NC}] - Directory management... "
        echo -e "[${RED}e${NC}] - Exit."

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
            clear
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