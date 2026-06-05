#!/bin/bash

# This script offers an interactive menu that the user can use to execute actions
# # These actions include deleting files, folders, checking n commands of the log_file, etc.

# MORE IDEAS TO ADD
# 1. RESTORE BACKUP -> LISTS ALL CURRENT BACKUPS AND ALLOWS TO RESTORE THE BACKUPS, RESOLVING FILES AND DIRECTORIES CONFLICTS
# 2. RENAME FILES -> LISTS ALL FILES OF THE CURRENT DIRECTORIES AND ALLOWS YOU TO SELECT A SPECIFIC ONE AND INPUT THE NEW NAME


# We first ensure that no parameter was passed to the script when it was executed

if [ $# -ne 0 ]
then
    echo The script execution does not admit any parameters
    exit 1
fi

declare -a menu_options
prev_file=".prev_dir_content.txt"
cur_file=".updated_dir_content.txt"
log_file="${PWD}/task_manager.log"
zip_file=".file_to_zip"
backup_file="${PWD}/backup"
declare -i zip_file_id
zip_file_id=0
menu_options=("MODIFY FILE TREE" "BACKUP FILES(ZIP)" "OBTAIN PREVIOUS ACTIONS" "CHANGE SCRIPT'S WORKING DIRECTORY" "QUIT")
QUIT=${menu_options[-1]}

if [ ! -f "${log_file}" ]; then
    # This means the log file does not exist, so we create it
    touch "${log_file}"
fi

log_command()
{
    # This function has two params: [ACTION] affected_file
    # It appends the given action and affected file to the log file
    action="$1"
    resource="$2"

    # We print the action carried out with the associated date
    echo  $(date '+%Y-%m-%d %H:%M:%S') [${action}] ${resource} >> "${log_file}"

}



check_updated_tree()
{
    
    # This first while is used to detect the files that were deleted
    while IFS= ;read -r linea; do

        if ! grep -qFx "$linea" "${cur_file}"; then
            #If this first condition is met, this means that the file or directory
            # no longer exists, so we delete it
            rm -rf "$linea"
            log_command "DELETE" "${linea}"
        fi
    done < ${prev_file}

    # We develop a second while to detect the added files or directories
    while IFS= ;read -r linea; do
            if ! grep -qFx "$linea" "${prev_file}"; then
                # This means the line was not found on the previous file. Therefore,
                # it corresponds to a new file/directory we must create
                
                if [[ ${linea:(-1)} == '/' ]]; then
                    # This means it is a directory, we create it without the /
                    mkdir -p "${linea%/}" 2>/dev/null
            
                else
                    # This means it is a file
                    touch "$linea" 2>/dev/null
                fi
                
                # We only register the command if the previous touch command was executed with no errors
                if [ $? -eq 0 ];then
                    log_command "CREATE" "${linea}"
                fi
            fi
    done < ${cur_file}

    # We finally delete the intermidiate files created
    rm -f "${prev_file}" "${cur_file}"
}



handle_file_tree()
{
    
    # In this case, we create a file with the content of the current directory
    touch ${prev_file}
    ls -p -1 > ${prev_file}
    # We create a copied file that the user is going to be allowed to modify
    cp ${prev_file} ${cur_file}
            
    # We check if the vi editor exists
    if command  -v vi > /dev/null; then
        vi "${cur_file}"
        check_updated_tree

    elif  command -v nano > /dev/null; then
        nano "${cur_file}"
        check_updated_tree
    else
        echo No text editor could be opened, returning to the OPTION menu
    
    fi    
}

handle_log_file_print()
{
    # In this case, we take wish the user to specify the amount of commands they wish to retrieve
    number_commands=$(wc -l < ${log_file})

    echo There are ${number_commands} registered in the log file
    read -p "Introduce the number of commands you wish to retrieve: " user_input

    while [ $user_input -gt $number_commands ];do
        # We request a new number until the introduced value is within the range
        echo The introduced number cannot be greater than the number of stored commands!
        echo There are ${number_commands} registered in the log file.
        read -p "Introduce the number of commands you wish to retrieve: " user_input
    done

    # We finally show the last user_input lines
    tail -n ${user_input} "${log_file}"
}

handle_change_directory()
{
  declare -a current_directory_list
  
  # We obtain all the directories
  current_directory_list=($(ls -p | grep '/'))
  current_directory_list+=("." "..")
  
  # We print the found directories as a menu so the user can change between them
  PS3="Select the directory to move to: ";COLUMNS=1; select dir in  ${current_directory_list[@]};
  do
      case $dir in
      *)
        # We change the script's working directory
        # The user can keep working with the script from another director
        ## We change the script's working directory
        #The user can keep working with the script from another directoryy
        cd ${dir}
        echo Directory successfully changed
        echo " "
        echo Current Directory is ${PWD}
        echo " "
        break
        ;;
    esac
done
PS3="Select a number from the OPTION menu: "

}

handle_backup_zip()
{
    # We follow a similar methodology to the creating and deleting files
    # We show in a text editor the different folders and files and we just
    # create the zip of the remaining names
    
    # We first check if the file exists. If it already does, we change
    # the zip_file_id to avoid affecting the previous backups
    if [ -f "${backup_file}${zip_file_id}.zip" ]; then
        zip_file_id+=1
    fi

    ls -p -1 > "${zip_file}"
    
    # We display the contents to the user
    if command -v vi > /dev/null; then

        # If vi is installed it is opened with this editor
        vi "${zip_file}"
        select_to_compress_files

    elif command -v nano > /dev/null; then
        # If vi is not available, we try to open it with nano
        nano "${zip_file}"
        select_to_compress_files
    
    else
        echo "No text editor could be opened, returning to the OPTION menu"
    fi

}

select_to_compress_files()
{
    # This function was developed to ensure that only existing files
    # from the current directory are compressed. In other words, that
    # the user does not add a non existing file or directory during the editing.
    # This way we avoid possible compressing issues
    selected_files=$(grep -Fx -f <(ls -p -1) "${zip_file}")

    # Once we have the files to compress we just execute the zip command
    zip -r  "${backup_file}${zip_file_id}.zip" $(echo "$selected_files" | tr '\n' ' ')
    rm -f "${zip_file}"
    log_command "BACKUP" "${backup_file}${zip_file_id}.zip"

}

echo " "
echo The current directory is ${PWD}
echo " "

PS3="Select a number from the OPTION menu: "
COLUMNS=1; select option in "${menu_options[@]}";
do
    case $option in 
        "$QUIT")
            
            echo The execution has been terminated
            break
            ;;

        "MODIFY FILE TREE")
            # We call the function that handles the files
            handle_file_tree              
            ;;

        "OBTAIN PREVIOUS ACTIONS")
            handle_log_file_print
            ;;

        "BACKUP FILES(ZIP)")
            handle_backup_zip
            ;;

        "CHANGE SCRIPT'S WORKING DIRECTORY")
            handle_change_directory
            ;;
    esac
done

