#!/bin/bash

# Group p31

##### AUTHORS #####
# Filip Starkenberg, fsg18002@student.mdh.se
# Fatima Mahmoud, fmd21001@student.mdh.se

##### VERSION #####
version="1.0.1"

##### Descrition #####
# Display system information. 
# Add, view and manage users, groups and directories. 

##### Future work #####
# Users shuld be able to cancel curent 'task' by pressing Escape or similar. Currently only way to do that is by terminating the application with Ctrl+c.  
# Less use of 'global' variables. Code is verry hard to follow currently. More function arguments. 



#Todo:
# 
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

#Yes or no question. Returns 1 when yes, 0 when no. 
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

# Displays network information
netinfo(){
    header
    echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}Network information${NC}]"
    echo 
    echo -e "Computer name:  ${CYAN}$HOSTNAME${NC}"
    echo
    # Get all network devices
    devices=( $( ip link | awk '/: / && !/: lo/ {print $2}' | sed 'y/:/ /' ) )
    echo "Network device(s): "
    echo
    for device in ${devices[@]}; do
        echo -e "${YELLOW}$device:${NC}"
        echo -e "${CYAN}  IP address:${NC}           $( ip addr show $device | awk '/inet / {print $2}' )"
        echo -e "${CYAN}  Mac adddress:${NC}         $( ip addr show $device | awk '/link\// {print $2}' )"
        echo -e "${CYAN}  Default gateway:${NC}      $( ip r | awk "/default via / && /$device/ {print \$3}" )"
        echo -e "${CYAN}  Device status:${NC}        $( ip link show $device | awk '/: / && !/: lo/ {print $9}' )"
        echo
    done
    read -rsn1 -p "Press enter to continue..." temp
}

# Select user form existing users
selectuser(){
    while true; do
    header
        for (( i=0; i < ${#users[@]}; i++ )); do
            echo -e "[${YELLOW}$i${NC}] - ${users[i]}"
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

# Select group from exising groups
selectgroup(){
    while true; do
    header
        for (( i=0; i < ${#groups[@]}; i++ )); do
            echo -e "[${YELLOW}$i${NC}] - ${groups[i]}"
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


# Print properties for $selecteduser
printuserprops(){
    groups=( $( cat /etc/group | grep $selecteduser | cut -d ":" -f 1 ) )
    echo -e "User properties: ${YELLOW}$selecteduser${NC}"
    echo
    echo -e "${YELLOW}User name:${NC}      $( cat /etc/passwd | egrep "^$selecteduser:" | cut -d ":" -f 1 )"
    echo -e "${YELLOW}Password:${NC}       $( cat /etc/passwd | egrep "^$selecteduser:" | cut -d ":" -f 2 )"
    echo -e "${YELLOW}User ID:${NC}        $( cat /etc/passwd | egrep "^$selecteduser:" | cut -d ":" -f 3 )"
    echo -e "${YELLOW}Group ID:${NC}       $( cat /etc/passwd | egrep "^$selecteduser:" | cut -d ":" -f 4 )"
    echo -e "${YELLOW}Directory:${NC}      $( cat /etc/passwd | egrep "^$selecteduser:" | cut -d ":" -f 6 )"
    echo -e "${YELLOW}Comment:${NC}        $( cat /etc/passwd | egrep "^$selecteduser:" | cut -d ":" -f 5 )"
    echo -e "${YELLOW}Shell:${NC}          $( cat /etc/passwd | egrep "^$selecteduser:" | cut -d ":" -f 7 )"
    echo
    echo -e "${YELLOW}Groups:${NC} ${groups[@]}"
}

# Delets $selecteduser
deleteuser(){
    echo -e "Are you sure you want to delete the user: ${YELLOW}$selecteduser${NC}?[y/n]"
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

# Helper function for createuser
displaynewuserdata(){
    echo "Creating new user"
    clear
    echo -e "${YELLOW}User name:${NC}      $1"
    echo -e "${YELLOW}Comment:${NC}        $2"
    echo -e "${YELLOW}Directory:${NC}      $3"
    echo -e "${YELLOW}Shell:${NC}          $4"
    echo
}

# Creates a new user
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

# Change a user id
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
            echo -e "Chnged user ID for ${YELLOW}$selecteduser${NC} to ${YELLOW}$newuserid${NC}."
        else
            echo "Unable to change user id. Unknown error. "
        fi
    fi
}

# Change user home directory
changehomedir(){
    echo "Existing home directories: "
    echo -e "${YELLOW}"
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
        echo -e "Switched home for ${YELLOW}$selecteduser${NC} to ${YELLOW}$newhome${NC}."
    else
        #Handle errors here
        echo "  Unknown error. Code: $errorcode"
    fi
}

# Change shell for user
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
        echo -e "Switched shell for ${YELLOW}$selecteduser${NC} to ${YELLOW}$newshell${NC}"
    else
        #Handle errors here
        echo "Unknown error. Code: $errorcode"
    fi
}

# Menu loop when modifying a user
modifyuser(){
    while true; do
        header
        echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}User management${NC}] > [${PURPLE}Modify user${NC}]"
        echo 
        echo -e "Currently modifying user: ${YELLOW}$selecteduser${NC}"
        echo 
        echo -e "What do you want to do?"
        echo
        echo -e "[${YELLOW}u${NC}] - Change username. "
        echo -e "[${YELLOW}p${NC}] - Change password. "
        echo -e "[${YELLOW}i${NC}] - Change user id. "
        echo -e "[${YELLOW}g${NC}] - Change primary group. "
        echo -e "[${YELLOW}c${NC}] - Edit comment. "
        echo -e "[${YELLOW}d${NC}] - Change home directory. "
        echo -e "[${YELLOW}s${NC}] - Change shell. "
        echo -e "[${YELLOW}e${NC}] - Go back. "
        read -rsn1 -p '> ' selection

        #Change username
        if [[ "$selection" == "u" ]]; then
            header
            echo "Enter new username: "
            read -p '> ' newusername
            usermod -l $newusername $selecteduser &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo -e "Changed username form ${YELLOW}$selecteduser${NC} to ${YELLOW}$newusername${NC}. "
                selecteduser=$newusername
            else
            echo "Unable to change username:"
                if [[ $errorcode -eq 9 ]]; then
                    echo -e "  Username ${YELLOW}$newusername${NC} is ocupided. "
                else
                    echo "  Unknown error. Code: $errorcode"
                fi
            fi
        # Change password
        elif [[ "$selection" == "p" ]]; then
            header
            echo "Changing password for: ${YELLOW}$selecteduser${NC}"
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
                echo -e "Switched primary group for ${YELLOW}$selecteduser${NC} to ${YELLOW}$newgroup${NC}."
            else
                echo "Unable to change primary group:"
                if [[ $errorcode -eq 6 ]]; then
                    echo -e "  Group ${YELLOW}$newgroup${NC} does not exist. "
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
                echo -e "Set comment for ${YELLOW}$selecteduser${NC} to ${YELLOW}$newcomment${NC}"
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

# Get user groups
getgroups(){
    gidmin=$(grep "^GID_MIN" /etc/login.defs)
    gidmax=$(grep "^GID_MAX" /etc/login.defs)
    gidmin=$( echo "${gidmin##GID_MIN}" | sed -e 's/^[[:space:]]*//' )
    gidmax=$( echo "${gidmax##GID_MAX}" | sed -e 's/^[[:space:]]*//' )

    groups=( $( awk -F':' -v "min=$gidmin" -v "max=$gidmax" '{ if ( $3 >= min && $3 <= max) print $0 }' "/etc/group" | cut -d ":" -f 1) )
}

# Get login users
getusers(){
    uidmin=$(grep "^UID_MIN" /etc/login.defs)
    uidmax=$(grep "^UID_MAX" /etc/login.defs)
    uidmin=$( echo "${uidmin##UID_MIN}" | sed -e 's/^[[:space:]]*//' )
    uidmax=$( echo "${uidmax##UID_MAX}" | sed -e 's/^[[:space:]]*//' )

    users=( $( awk -F':' -v "min=$uidmin" -v "max=$uidmax" '{ if ( $3 >= min && $3 <= max  && $7 != "/sbin/nologin" ) print $0 }' "/etc/passwd" | cut -d ":" -f 1) )
}

# Menu for managing users
usermanage(){
    while true; do
        header
        echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}User management${NC}]"
        echo
        echo -e "What do you want to do?"
        echo
        echo -e "[${YELLOW}a${NC}] - Add user. "
        echo -e "[${YELLOW}l${NC}] - List login-users. "
        echo -e "[${YELLOW}p${NC}] - Display user properties. "
        echo -e "[${YELLOW}m${NC}] - Modify user. "
        echo -e "[${YELLOW}d${NC}] - Delete user. "
        echo -e "[${YELLOW}e${NC}] - Go back. "

        getusers

        read -rsn1 -p '> ' selection
        
        #list users
        if [[ "$selection" == "l" ]]; then
            header
            echo -e "${YELLOW}Users:${NC}"
            for user in ${users[@]}; do
                echo -e "    ${CYAN}$user${NC}"
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

# Delete $selectedgroup
deletegroup(){
    echo -e "Are you sure you want to delete the group: ${YELLOW}$selectedgroup${NC}?[y/n]"
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

# Create a group
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

# List all users in a group
listusersingroup(){
    groupid=$(cat /etc/group | awk "/$selectedgroup:/ {print}" | cut -d ":" -f 3)
    usersingroup=( $( cat /etc/passwd | sed 'y/:/ /' | awk -v "gid=$groupid" '$4 == gid {print $0}' | cut -d " " -f 1 ) )
    usersingroup+=( $( cat /etc/group | awk "/$selectedgroup:/ {print}" | cut -d ":" -f 4 | sed 'y/,/ /' ) )
    
    echo -e "Users in group ${YELLOW}$selectedgroup${NC}:"
    for user in ${usersingroup[@]}; do
        echo -e "    ${CYAN}$user${NC}"
    done
    echo
}

# Add an exising user to an existing group
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

# Remove an exising user from an existing group
removeuserfromgroup(){
    groupid=$(cat /etc/group | awk "/$selectedgroup:/ {print}" | cut -d ":" -f 3)
    usersingroup=( $( cat /etc/passwd | sed 'y/:/ /' | awk -v "gid=$groupid" '$4 == gid {print}' | cut -d " " -f 1 ) )
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

# Menu for group management
groupmanage(){
    while true; do
        header
        
        echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}Group management${NC}]"
        echo 
        echo -e "What do you want to do?"
        echo
        echo -e "[${YELLOW}c${NC}] - Ceate new group. "
        echo -e "[${YELLOW}l${NC}] - List all groups, not system groups. "
        echo -e "[${YELLOW}v${NC}] - List all users in a group. "
        echo -e "[${YELLOW}a${NC}] - Add user to group. "
        echo -e "[${YELLOW}r${NC}] - Remove user from group. "
        echo -e "[${YELLOW}d${NC}] - Delete group. "
        echo -e "[${YELLOW}e${NC}] - Go back. "

        getusers
        getgroups

        read -rsn1 -p '> ' selection

        #Create new group
        if [[ "$selection" == "c" ]]; then
            creategroup
        #List all groups
        elif [[ "$selection" == "l" ]]; then
            header
            echo -e "${YELLOW}Groups:${NC}"
            for group in ${groups[@]}; do
                echo -e "    ${CYAN}$group${NC}"
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
            echo -e "[${YELLOW}$i${NC}] - ${dirs[i]}" | sed "s/ [.][.]$/ Parent directory/" | sed "s/ [.]$/ This directory/"
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
# List attributes for a directory
# Params
# 1: directory
listdirattr(){
    header
    ownerperms=( )
    groupperms=( )
    otherperms=( )
    setuid="No"
    setgid="No"
    sticky="No"
    perms=$( ls -ld "$selecteddir" | awk "{print \$1}" )
    if [[ $( echo $perms | cut -b 2 ) != "-" ]]; then
        ownerperms+=( "Read" )
    fi
    if [[ $( echo $perms | cut -b 3 ) != "-" ]]; then
        ownerperms+=( "Write" )
    fi
    if [[ $( echo $perms | cut -b 4 ) != "-" ]]; then
        re='[s|S]'
        if [[ $( echo $perms | cut -b 4 ) =~ $re ]]; then
            setuid="Yes"
        fi
        re='[s|x]'
        if [[ $( echo $perms | cut -b 4 ) =~ $re ]]; then
            ownerperms+=( "Execute" )
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
        ownerperms+=( "Write" )
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
    echo -e "Listing propertiers for: ${YELLOW}$( readlink -f $selecteddir )${NC}"
    echo
    echo -e "${YELLOW}Owner:${NC}          $( ls -ld "$selecteddir" | awk "{print \$3}" )"
    echo -e "${YELLOW}Group:${NC}          $( ls -ld "$selecteddir" | awk "{print \$4}" )"
    echo -e "${YELLOW}Last modified:${NC}  $( ls -ld "$selecteddir" | awk "{print \$6,\$7,\$8}" )"
    echo
    echo -e "Permissions: "
    echo -e "  ${YELLOW}Owner:${NC}   ${ownerperms[@]}"
    echo -e "  ${YELLOW}Group:${NC}  ${groupperms[@]}"
    echo -e "  ${YELLOW}Other:${NC}  ${otherperms[@]}"
    echo -e "  ${YELLOW}Setuid:${NC} $setuid"
    echo -e "  ${YELLOW}Setgid:${NC} $setgid"
    echo -e "  ${YELLOW}Sticky:${NC} $sticky"
    read -p "Press enter to continue..." temp
}

# Menu for managing directories
dirmanage(){
    while true; do
        header
        echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}Directory management${NC}]"
        echo
        echo -e "You are currently in ${YELLOW}$PWD${NC}"
        echo
        echo "What do you want to do?"
        echo
        echo -e "[${YELLOW}w${NC}] - Change working directory. "
        echo -e "[${YELLOW}v${NC}] - View directory properties. "
        echo -e "[${YELLOW}c${NC}] - Create Directory. "
        echo -e "[${YELLOW}l${NC}] - List Directory content. "
        echo -e "[${YELLOW}a${NC}] - Change attribute of directory. "
        echo -e "[${YELLOW}d${NC}] - Delete Directory. "
        echo -e "[${YELLOW}e${NC}] - Go back"
        echo
        read -rsn1 -p '> ' selection

        #Create new Directory
        if [[ "$selection" == "c" ]]; then
            header
            read -p "Enter new directory name to create: " dirname
            mkdir $dirname &> /dev/null
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo " Directory created succesfully! "
            else
                echo "Failed to create Directory!"
            fi
            read -p "Press enter to continue..." temp
        # Change working directory
        elif  [[ "$selection" == "w" ]]; then
            selectdir "$PWD"
            cd $selecteddir
        # View directory attributs
        elif  [[ "$selection" == "v" ]]; then
            listdirattr "$PWD"
        #List Directory content
        elif  [[ "$selection" == "l" ]]; then
            header
            echo -e "Content of: ${YELLOW}$PWD${NC}"
            echo
            ls -1oghF --si --time-style=+"%Y-%m-%d %T" --color=auto $PWD
            errorcode=$?
            if [[ $errorcode -eq 0 ]]; then
                echo
            else
                echo "Failed to list content of Directory"
            fi
            read -p "Press enter to continue..." temp
            
        #Change attribute of Directory 
        elif [[ "$selection" == "a" ]]; then
            while true; do
                header
                echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}Directory management${NC}] > [${PURPLE}Attribute manager${NC}]"
                echo
                echo -e "You are currently modifying: ${YELLOW}$PWD${NC}"
                echo
                echo "What do you want to change?"
                echo
                echo -e "[${YELLOW}o${NC}] - Owner of directory"
                echo -e "[${YELLOW}g${NC}] - Group of directory"
                echo -e "[${YELLOW}p${NC}] - Permissions of Directory"
                echo -e "[${YELLOW}t${NC}] - Toggle sticky bit"
                echo -e "[${YELLOW}s${NC}] - Toggle setgid"
                echo -e "[${YELLOW}e${NC}] - Go back"
                echo
                read -rsn1 -p '> ' selection

                #Change owner of Directory
                if [[ "$selection" == "o" ]]; then
                    getusers
                    selectuser
                    chown $selecteduser $PWD &> /dev/null
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
                    chown :$selectedgroup $PWD &> /dev/null
                    errorcode=$?
                    if [[ $errorcode -eq 0 ]]; then
                        echo "Group changed!"
                    else
                        echo "Failed to change group of Directory!"
                    fi
                    read -p "Press enter to continue>" temp

                #Change permissions of Directory
                elif [[ "$selection" == "p" ]]; then
                    echo "Change permissions:"

                    echo "[0] - No permissions."
                    echo "[1] - Execute only"
                    echo "[2] - Write only"
                    echo "[4] - Read only"
                    echo "[5] - Read & Execute"
                    echo "[6] - Read & Write"
                    echo "[7] - Read, Write & Execute"
                    echo
                    echo "Please enter permissions as a number for:"
                    # Owner
                    while true; do
                        echo -n ""
                        read -rsn1 -p "Owner: " owner
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
                    read -rsn1 -p "Group: " group
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
                    read -rsn1 -p "Others: " others
                    re='^[0-9]+$'
                        if [[ $others =~ $re ]]; then
                            if [[ $others -gt -1 && $others -lt 8 && $others -ne 3 ]]; then
                                break
                            fi
                        fi
                        echo "Inncorrect input"
                    done
                    
                    chmod $owner$group$others $PWD &> /dev/null
                    errorcode=$?
                    if [[ $errorcode -eq 0 ]]; then
                        echo "Permissions changed!"
                    else
                        echo "Failed to change permissions!"
                    fi
                    read -p "Press enter to continue..." temp

                #Sticky bit
                elif [[ "$selection" == "t" ]]; then
                    perms=$( ls -ld "$PWD" | awk "{print \$1}" )
                    re='[t|T]'
                    if [[ $( echo $perms | cut -b 10 ) =~ $re ]]; then
                        chmod -t $PWD &> /dev/null
                        errorcode=$?
                        if [[ $errorcode -eq 0 ]]; then
                            echo "Sticky bit for $PWD: off"
                        else 
                            echo "Failed to remove Setgid!"
                        fi
                    else
                        chmod +t $PWD &> /dev/null
                        errorcode=$?
                        if  [[ $errorcode -eq 0 ]]; then
                            echo "Sticky bit for $PWD: on"
                        else
                            echo "Failed to set Setgid!"
                        fi
                    fi
                    read -p "Press enter to continue..." temp
                #Setgid
                elif [[ "$selection" == "s" ]]; then
                    perms=$( ls -ld "$PWD" | awk "{print \$1}" )
                    re='[s|S]'
                    if [[ $( echo $perms | cut -b 7 ) =~ $re ]]; then
                        chmod g-s $PWD &> /dev/null
                        errorcode=$?
                        if [[ $errorcode -eq 0 ]]; then
                            echo "Setgid for $PWD: off"
                        else 
                            echo "Failed to remove Setgid!"
                        fi
                    else
                        chmod g+s $PWD &> /dev/null
                        errorcode=$?
                        if  [[ $errorcode -eq 0 ]]; then
                            echo "Setgid for $PWD: on"
                        else
                            echo "Failed to set Setgid!"
                        fi
                    fi
                    
                    read -p "Press enter to continue..." temp
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
            read -p "Press enter to continue..." temp
        
        #Go back
        elif [[ "$selection" == "e" ]]; then
            break
        else
            echo "Invalid input!"
        fi
    done
}

packagemanager(){
    while true; do
        header
        echo -e "[${PURPLE}Main menu${NC}] > [${PURPLE}Package manager${NC}]"
        echo 
        echo -e "What do you want to do?"
        echo
        echo -e "[${YELLOW}u${NC}] - Update. "
        echo -e "[${YELLOW}s${NC}] - Search all packages. "
        echo -e "[${YELLOW}l${NC}] - Search installed packages. "
        echo -e "[${YELLOW}i${NC}] - Install package. "
        echo -e "[${YELLOW}r${NC}] - Remove package. "
        echo -e "[${YELLOW}e${NC}] - Go back."

        read -rsn1 -p '> ' selection

        if [[ "$selection" == "u" ]]; then
            echo "This will update all installed packages. Proceed? [y/n]"
            yesno
            if [[ $? -eq 1 ]]; then
                echo -e "${PURPLE}System manager:${NC} ${YELLOW}Executing command: apt update${NC}"
                apt update
                echo -e "${PURPLE}System manager:${NC} ${YELLOW}Executing command: apt upgrade${NC}"
                apt upgrade
                echo -e "${PURPLE}System manager:${NC} ${YELLOW}Executing command: apt autoremove${NC}"
                apt autoremove
            fi
            read -p "Press enter to continue..." temp
        elif [[ "$selection" == "s" ]]; then
            echo "Enter search pattern:"
            read -p '> ' searchpattern
            apt list | egrep "$searchpattern"
            read -p "Press enter to continue..." temp
        elif [[ "$selection" == "l" ]]; then
            echo "Enter search pattern:"
            read -p '> ' searchpattern
            apt list --installed | egrep "$searchpattern"
            read -p "Press enter to continue..." temp
        elif [[ "$selection" == "i" ]]; then
            echo "Enter package name:"
            read -p '> ' packagename
            apt install $packagename
            if [[ $? -ne 0 ]]; then
                echo "Try snap instead? [y/n]"
                yesno
                if [[ $? -eq 1 ]]; then
                    snap install $packagename --classic
                fi
            fi
            read -p "Press enter to continue..." temp
        elif [[ "$selection" == "r" ]]; then
            echo "Enter package name:"
            read -p '> ' packagename
            apt remvoe $packagename
            echo -e "${PURPLE}System manager:${NC} ${YELLOW}Executing command: apt autoremove${NC}"
            apt autoremove
            read -p "Press enter to continue..." temp
        elif [[ "$selection" == "e" ]]; then
            break
        else
            echo "invalid input."
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
        echo -e "[${YELLOW}n${NC}] - Network information... "
        echo -e "[${YELLOW}u${NC}] - User management... "
        echo -e "[${YELLOW}g${NC}] - Group management... "
        echo -e "[${YELLOW}d${NC}] - Directory management... "
        echo -e "[${YELLOW}p${NC}] - Package manager..."
        echo -e "[${YELLOW}e${NC}] - Exit."

        read -rsn1 -p '> ' selection

        if [[ "$selection" == "n" ]]; then
            netinfo
        elif [[ "$selection" == "u" ]]; then
            usermanage
        elif [[ "$selection" == "g" ]]; then
            groupmanage
        elif [[ "$selection" == "d" ]]; then
            dirmanage
        elif [[ "$selection" == "p" ]]; then
            packagemanager
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