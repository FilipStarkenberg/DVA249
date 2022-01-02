#!/bin/bash

# Group p31

##### AUTHORS #####
# Filip Starkenberg, fsg18002@student.mdh.se
# Fatima 

##### VERSION #####
version="1.0.0"

##### Descrition #####
# Display system information. 
# Add, view and manage users, groups and directories. 

##### Future work #####
# Users shuld be able to cancel curent 'task' by pressing Escape or similar. Currently only way to do that is by terminating the application with Ctrl+c.  
# Less use of 'global' variables. Code is verry hard to follow currently. More function arguments. 



#Todo:
# Add custom errors
# 
# 
# 
# 



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

header(){
    clear
    echo -e "--------------------------------------------------------"
    echo -e "                 ${YELLOW}SYSTEM MANAGER v$version${NC}"
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
    while true; do
    header
        for (( i=0; i < ${#users[@]}; i++ )); do
            echo -e "[${RED}$i${NC}] - ${users[i]}"
        done
        re='^[0-9]+$'
        read -p 'Select or enter user name: ' selecteduser
        if [[ $selecteduser =~ $re ]]; then
            if [[ $selecteduser -ge  ${#users[@]} ]]; then
                echo "Incorrect input"
            else
                selecteduser=${users[selecteduser]}
                break
            fi
        else
            break
        fi
    done
}

selectgroup(){
    while true; do
    header
        for (( i=0; i < ${#groups[@]}; i++ )); do
            echo -e "[${RED}$i${NC}] - ${groups[i]}"
        done
        re='^[0-9]+$'
        read -p 'Select or enter group name: ' selectedgroup
        if [[ $selectedgroup =~ $re ]]; then
            if [[ $selectedgroup >  ${#groups[@]} ]]; then
                echo "Incorrect input"
            else
                selectedgroup=${groups[selectedgroup]}
                break
            fi
        else
            break
        fi
    done
}

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
    if [[ $newuserid -lt $uidmin || $newuserid -gt $uidmax ]]; then
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
        echo "  Unknown error. Code: $errorcode"
    fi
}

changeshell(){
    echo "Enter path to new shell: "
    read -p '> ' newshell
    if [[ ! -f $newshell ]]; then
        echo "'$newshell' does not exist. "
        return 1
    fi
    if [[ ! -x $newshell ]];then
        echo "'$newshell' is not an executable. "
        return 2
    fi
    usermod -s "$newshell" $selecteduser &> /dev/null
    errorcode=$?
    if [[ $errorcode -eq 0 ]]; then
        echo -e "Switched shell for ${RED}$selecteduser${NC} to ${RED}$newshell${NC}"
    else
        #Handle errors here
        echo "Unknown error. Code: $errorcode"
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
        echo -e "[${RED}c${NC}] - Edit comment. "
        echo -e "[${RED}d${NC}] - Change home directory. "
        echo -e "[${RED}s${NC}] - Change shell. "
        echo -e "[${RED}e${NC}] - Go back. "
        read -p '> ' selection

        #Change username
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
        # Change password
        elif [[ "$selection" == "p" ]]; then
            header
            echo "Changing password for: ${RED}$selecteduser${NC}"
            echo
            passwd $selecteduser 
        # Change user ID
        elif [[ "$selection" == "i" ]]; then
            modifyuserid
        # Change primary group
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
        # Edit comment
        elif [[ "$selection" == "c" ]]; then
            header
            oldcomment=$( cat "/etc/passwd" | grep $selecteduser | cut -d ":" -f 5 )
            echo "Edit comment and press enter to confirm: "
            read -e -i "$oldcomment" -p '> ' newcomment
            usermod -c "$newcomment" $selecteduser &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo -e "Set comment for ${RED}$selecteduser${NC} to ${RED}$newcomment${NC}"
            else
                #Handle errors here
                echo "Unknown error. Code: $errorcode"
            fi
        elif [[ "$selection" == "d" ]]; then
            header
            changehomedir
        elif [[ "$selection" == "s" ]]; then
            header
            changeshell
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
            if [[ $errorcode -eq 6 ]]; then
                echo "  Specified group does not exist. "
            elif [[ $errorcode -eq 8 ]]; then
                echo "  Can not remove user's primary group. "
            elif [[ $errorcode -eq 10 ]]; then
                echo "  Unable to update group file. "
            else
                echo "Unknown error. Code: $errorcode"
            fi
            
        fi
    fi
}

creategroup(){
    echo "Enter new group name: "
    read -p '> ' newgroupname
    addgroup $newgroupname &> /dev/null
    errorcode=$?
    if [[ $errorcode -eq 0 ]]; then
        echo "Group $newgroupname created."
    else
        if [[ $errorcode -eq 10 ]]; then
            echo "  Unable to update group file. "
        else
            echo "Unknown error. Code: $errorcode"
        fi
    fi
}

listusersingroup(){
    groupid=$(cat /etc/group | awk "/$selectedgroup:/ {print}" | cut -d ":" -f 3)
            usersingroup=( $( cat /etc/passwd | sed 'y/:/ /' | awk -v "gid=$groupid" '$4 == gid {print}' | cut -d ":" -f 1 ) )
            usersingroup+=( $( cat /etc/group | awk "/$selectedgroup:/ {print}" | cut -d ":" -f 4 | sed 'y/,/ /' ) )
            
            echo -e "Users in group ${RED}$selectedgroup${NC}:"
            for user in ${usersingroup[@]}; do
                echo -e "    ${LIGHTRED}$user${NC}"
            done
            echo
}

addusertogroup(){
    adduser $selecteduser $selectedgroup &> /dev/null
    errorcode=$?
    if [[ $errorcode -eq 0 ]]; then
        echo "$selecteduser added to $selectedgroup."
    else
        if [[ $errorcode -eq 6 ]]; then
            echo "  Specified group does not exist. "
        elif [[ $errorcode -eq 10 ]]; then
            echo "  Unable to update group file. "
        else
            echo "Unknown error. Code: $errorcode"
        fi
    fi
}

removeuserfromgroup(){
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
        if [[ $errorcode -eq 7 ]]; then
            echo "  You cannot remove a user from its primary group. "
        elif [[ $errorcode -eq 6 ]]; then
            echo "  The user does not belong to the specified group. "
        else
            echo "Unknown error. Code: $errorcode"
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
            creategroup
        #List all groups
        elif [[ "$selection" == "l" ]]; then
            header
            echo -e "${RED}Groups:${NC}"
            for group in ${groups[@]}; do
                echo -e "    ${LIGHTRED}$group${NC}"
            done 
        #List all users in a group
        elif [[ "$selection" == "v" ]]; then
            
            selectgroup
            header
            listusersingroup
        #Add an existing user to an existing group
        elif [[ "$selection" == "a" ]]; then
            
            selectgroup
            header
            selectuser
            addusertogroup
        #Remove existing user from existing group
        elif [[ "$selection" == "r" ]]; then
            
            selectgroup
            header
            removeuserfromgroup
        #Delete group
        elif [[ "$selection" == "d" ]]; then
            
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

# Params
# 1: directory
selectdir(){
    while true; do
    header
        dirs=( $(ls -la "$1" | egrep "^d" | awk '{print $9}') )
        for (( i=0; i < ${#dirs[@]}; i++ )); do
            echo -e "[${RED}$i${NC}] - ${dirs[i]}" | sed "s/ [.][.]$/ Parent directory/" | sed "s/ [.]$/ This directory/"
        done
        re='^[0-9]+$'
        read -p 'Select directory: ' selecteddir
        if [[ $selecteddir =~ $re ]]; then
            if [[ $selecteddir -ge  ${#dirs[@]} ]]; then
                echo "Incorrect input. "
            else
                selecteddir=${dirs[selecteddir]}
                break
            fi
        else
            echo "Please enter an integer. "
        fi
    done
}

# Params
# 1: directory
listdirattr(){
    header
    selectdir "$1"
    header
    userperms=( )
    groupperms=( )
    otherperms=( )
    setuid="No"
    setgid="No"
    sticky="No"
    perms=$( ls -ld "$selecteddir" | awk "{print \$1}" )
    if [[ $( echo $perms | cut -b 2 ) != "-" ]]; then
        userperms+=( "Read" )
    fi
    if [[ $( echo $perms | cut -b 3 ) != "-" ]]; then
        userperms+=( "Write" )
    fi
    if [[ $( echo $perms | cut -b 4 ) != "-" ]]; then
        re='[s|S]'
        if [[ $( echo $perms | cut -b 4 ) =~ $re ]]; then
            setuid="Yes"
        fi
        re='[s|x]'
        if [[ $( echo $perms | cut -b 4 ) =~ $re ]]; then
            userperms+=( "Execute" )
        fi
    fi
    if [[ $( echo $perms | cut -b 5 ) != "-" ]]; then
        groupperms+=( "Read" )
    fi
    if [[ $( echo $perms | cut -b 6 ) != "-" ]]; then
        groupperms+=( "Write" )
    fi
    if [[ $( echo $perms | cut -b 7 ) != "-" ]]; then
        re='[s|S]'
        if [[ $( echo $perms | cut -b 7 ) =~ $re ]]; then
            setgid="Yes"
        fi
        re='[s|x]'
        if [[ $( echo $perms | cut -b 7 ) =~ $re ]]; then
            groupperms+=( "Execute" )
        fi
    fi
    if [[ $( echo $perms | cut -b 8 ) != "-" ]]; then
        otherperms+=( "Read" )
    fi
    if [[ $( echo $perms | cut -b 9 ) != "-" ]]; then
        userperms+=( "Write" )
    fi
    if [[ $( echo $perms | cut -b 10 ) != "-" ]]; then
        re='[t|T]'
        if [[ $( echo $perms | cut -b 10 ) =~ $re ]]; then
            sticky="Yes"
        fi
        re='[t|x]'
        if [[ $( echo $perms | cut -b 10 ) =~ $re ]]; then
            otherperms+=( "Execute" )
        fi
    fi
    echo -e "Listing propertiers for: ${RED}$( readlink -f $selecteddir )${NC}"
    echo
    echo -e "${RED}Owner:${NC}          $( ls -ld "$selecteddir" | awk "{print \$3}" )"
    echo -e "${RED}Group:${NC}          $( ls -ld "$selecteddir" | awk "{print \$4}" )"
    echo -e "${RED}Last modified:${NC}  $( ls -ld "$selecteddir" | awk "{print \$6,\$7,\$8}" )"
    echo
    echo -e "Permissions: "
    echo -e "  ${RED}User:${NC}   ${userperms[@]}"
    echo -e "  ${RED}Group:${NC}  ${groupperms[@]}"
    echo -e "  ${RED}Other:${NC}  ${otherperms[@]}"
    echo -e "  ${RED}Setuid:${NC} $setuid"
    echo -e "  ${RED}Setgid:${NC} $setgid"
    echo -e "  ${RED}Sticky:${NC} $sticky"
    read -p "Press enter to continue..." temp
}


dirmanage(){
    while true; do
        header
        echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}Directory management${NC}]"
        echo
        echo -e "You are currently in ${RED}$PWD${NC}"
        echo
        echo "What do you want to do?"
        echo
        echo -e "[${RED}w${NC}] - Change working directory. "
        echo -e "[${RED}v${NC}] - View directory properties. "
        echo -e "[${RED}c${NC}] - Create Directory. "
        echo -e "[${RED}l${NC}] - List Directory content. "
        echo -e "[${RED}a${NC}] - Change attribute of directory. "
        echo -e "[${RED}d${NC}] - Delete Directory. "
        echo -e "[${RED}e${NC}] - Go back"
        echo
        echo -n " > "
        read selection

        #Create new Directory
        if [[ "$selection" == "c" ]]; then
            echo -n "Enter new directory name to create> "
            read dirname
            mkdir $dirname &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo " Directory created succesfully! "
            else
                echo "Failed to create Directory!"
            fi
            read -p "Press enter to continue>" temp
        # Change working directory
        elif  [[ "$selection" == "w" ]]; then
            selectdir "$PWD"
            cd $selecteddir
        # View directory attributs
        elif  [[ "$selection" == "v" ]]; then
            listdirattr "$PWD"

        #List Directory content
        elif  [[ "$selection" == "l" ]]; then
            selectdir "$PWD"
            ls -l $selecteddir 2> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo " $selecteddir content: "
            elif [[ $errorcode -eq 1 ]]; then
                echo "Failed to list content of Directory"
                echo "Operation not permitted"
            else
                echo "Failed to list content of Directory"
            fi
            read -p "Press enter to continue>" temp
            
        #Change attribute of Directory 
        elif [[ "$selection" == "a" ]]; then
        while true; do
            header
            echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}Directory management${NC}] > [${PURPLE}Attribute manager${NC}]"
            echo
            echo "What do you want to change?"
            echo
            echo -e "[${RED}o${NC}] - Owner of directory"
            echo -e "[${RED}g${NC}] - Group of directory"
            echo -e "[${RED}p${NC}] - Permissions of Directory"
            echo -e "[${RED}t${NC}] - Sticky bit"
            echo -e "[${RED}s${NC}] - Setgid"
            echo -e "[${RED}e${NC}] - Go back"
            echo
            echo -n " > "
            read  selection

            #Change owner of Directory
            if [[ "$selection" == "o" ]]; then
                getusers
                selectuser
                selectdir $PWD
                chown $selecteduser $selecteddir &> /dev/null
                errorcode=$?
                if [[ $errorcode -eq 0 ]]; then
                    echo "Ownership changed!"
                else
                    echo "Failed to change owner of Directory!"
                fi
                read -p "Press enter to continue>" temp

            #Change group of Directory
            elif [[ "$selection" == "g" ]]; then
                getgroups 
                selectgroup 
                selectdir $PWD
                chown :$selectedgroup $selecteddir &> /dev/null
                errorcode=$?
                if [[ $errorcode -eq 0 ]]; then
                    echo "Group changed!"
                else
                    echo "Failed to change group of Directory!"
                fi
                read -p "Press enter to continue>" temp

            #Change permissions of Directory
            elif [[ "$selection" == "p" ]]; then
                selectdir $PWD
                echo "Change permissions:"
                echo "for:"
                echo "No permissions         = 0"
                echo "Execute only           = 1"
                echo "Write only             = 2"
                echo "Read only              = 4"
                echo "Read & Execute         = 5"
                echo "Read & Write           = 6"
                echo "Read, Write & Execute  = 7"
                echo
                echo "Please enter permissions as a number for:"
                # Owner
                while true; do
                    echo -n "Owner/user> "
                    read owner
                    re='^[0-9]+$'
                    if [[ $owner =~ $re ]]; then
                        if [[ $owner -gt -1 && $owner -lt 8 && $owner -ne 3 ]]; then
                            break
                        fi
                    fi
                    echo "Inncorrect input"
                done

                # Group
                while true; do
                echo -n "Group> "
                read group
                re='^[0-9]+$'
                    if [[ $group =~ $re ]]; then
                        if [[ $group -gt -1 && $group -lt 8 && $group -ne 3 ]]; then
                            break
                        fi
                    fi
                    echo "Inncorrect input"
                done

                # Other
                while true; do
                echo -n "Others> "
                read others
                re='^[0-9]+$'
                    if [[ $others =~ $re ]]; then
                        if [[ $others -gt -1 && $others -lt 8 && $others -ne 3 ]]; then
                            break
                        fi
                    fi
                    echo "Inncorrect input"
                done
                
                chmod $owner$group$others $selecteddir &> /dev/null
                errorcode=$?
                if [[ $errorcode -eq 0 ]]; then
                    echo "Permissions changed!"
                else
                    echo "Failed to change permissions!"
                fi
                read -p "Press enter to continue>" temp

            #Sticky bit
            elif [[ "$selection" == "t" ]]; then
                selectdir $PWD
                echo "For Sticky bit: on input: 1"
                echo "For Sticky bit: off input: 2"
                echo -n "> "
                read choice

                #Set Sticky bit
                if [[ "$choice" == "1" ]]; then
                    chmod +t $selecteddir &> /dev/null
                    errorcode=$?
                    if [[ $errorcode -eq 0 ]]; then
                        echo "Sticky bit for $selecteddir: on"
                    else
                        echo "Failed to set Sticky bit!"
                    fi

                #Remove Sticky bit
                elif [[ "$choice" == "2" ]]; then
                    chmod -t $selecteddir &> /dev/null
                    errorcode=$?
                    if  [[ $errorcode -eq 0 ]]; then
                        echo "Sticky bit for $selecteddir: off"
                    else
                        echo "Failed to remove Sticky bit!"
                    fi
                fi
                read -p "Press enter to continue>" temp

            #Setgid
            elif [[ "$selection" == "s" ]]; then
                selectdir $PWD
                echo "For Setgid: on input: 1"
                echo "For Setgid: off input: 2"
                echo -n "> "
                read choice

                #Set Setgid
                if [[ "$choice" == "1" ]]; then
                    chmod g+s $selecteddir &> /dev/null
                    errorcode=$?
                    if  [[ $errorcode -eq 0 ]]; then
                        echo "Setgid for $selecteddir: on"
                    else
                        echo "Failed to set Setgid!"
                    fi

                #Remove Setgid
                elif [[ "$choice" == "2" ]]; then
                    chmod g-s $selecteddir &> /dev/null
                    errorcode=$?
                    if  [[ $errorcode -eq 0 ]]; then
                        echo "Setgid for $selecteddir: off"
                    else 
                        echo "Failed to remove Setgid!"
                    fi
                fi
                read -p "Press enter to continue>" temp
            elif [[ "$selection" == "e" ]]; then
                break

            else
                echo "Invalid input!"
            fi
            done

        #Delete Directory
        elif [[ "$selection" == "d" ]]; then
            selectdir $PWD
            rmdir $selecteddir &> /dev/null
            errorcode=$?
            if  [[ $errorcode -eq 0 ]]; then
                echo " Directory deleted!"
            else
                echo "Failed to delete Directory!"
            fi
            read -p "Press enter to continue>" temp
        
        #Go back
        elif [[ "$selection" == "e" ]]; then
            break
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