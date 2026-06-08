#!/bin/bash

# This script offers an interactive menu that the user can use to execute actions
# # These actions include deleting files, folders, checking n commands of the log_file, etc.

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
backup_restore_dir="${PWD}/RESTORED_CONTENT"
backup_used_dir="${PWD}/USED"
declare -i zip_file_id
zip_file_id=0
menu_options=("MODIFY FILE TREE" "BACKUP FILES(ZIP)" "RESTORE BACKUPS" "OBTAIN PREVIOUS ACTIONS" "CHANGE SCRIPT'S WORKING DIRECTORY" "RENAME FILE" "QUIT")
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
    echo  $(date '+%Y-%m-%d %H:%M:%S') [${action}] "${resource}" >> "${log_file}"

}



check_updated_tree()
{
    
    # This first while is used to detect the files that were deleted
    while IFS= read -r linea; do

        if ! grep -qFx "$linea" "${cur_file}"; then
            #If this first condition is met, this means that the file or directory
            # no longer exists, so we delete it
            rm -rf "$linea"
            log_command "DELETE" "${linea}"
        fi
    done < ${prev_file}

    # We develop a second while to detect the added files or directories
    while IFS= read -r linea; do
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

  
    if [ "${number_commands}" -eq 0 ]; then
        echo The log file is empty, there are no commands to select
    else
        
        echo There are ${number_commands} registered in the log file
        read -p "Introduce the number of commands you wish to retrieve: " user_input
        
        # While the user's input is not a number or greater than the number of commands, we request a new value
        while ! [[ "${user_input}" =~ ^[0-9]+$ ]] ||  [ $user_input -gt $number_commands ];do
            # We request a new number until the introduced value is within the range
            echo The introduced number cannot be greater than the number of stored commands!
            echo There are ${number_commands} registered in the log file.
            read -p "Introduce the number of commands you wish to retrieve: " user_input
        done

        # We finally show the last user_input lines
        tail -n ${user_input} "${log_file}"
    fi
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
        cd "${dir}"
        echo Directory successfully changed
        echo " "
        echo Current Directory is ${PWD}
        echo " "
        log_command "CHANGE DIRECTORY" "${dir}"
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
    while [ -f "${backup_file}${zip_file_id}.zip" ]; do
        zip_file_id+=1
    done

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
    declare -a selected_files
    mapfile -t selected_files < <(grep -Fx -f <(ls -p -1) "${zip_file}")

    # Once we have the files to compress we just execute the zip command
    zip -r  "${backup_file}${zip_file_id}.zip" "${selected_files[@]}"
    rm -f "${zip_file}"
    log_command "BACKUP" "${backup_file}${zip_file_id}.zip"

}

handle_rename_file()
{
# We are going to list all the files of the current directory and then, the user will be asked for a name
# if the name matches any of the existing files, the user will be asked again about a new name. If not an error
# will be displayed. Moreover, we are going to allow renaming without being able to change the extension of the file

# First we list all the files of the current directory. We show all the elements of the script's working directory. We remove
# the entries with a slash so that only files are displayed
files_current_directory="$(ls -p | grep -v '/')"

echo "${files_current_directory}"

# We store the file specified by the user
read -r  -p "Introduce the file (including extension) you wish to rename/Introduce -1 to abort: " user_input
echo " "

while [ ! -f "${user_input}" ] && [ "${user_input}" != "-1" ];do
    # This means the file does not exist
    echo The introduced file was incorrect, try again!
    echo " "
    read -r -p "Introduce the file (including extension) you wish to rename/Introduce -1 to abort: " user_input
done

if [ ${user_input} = "-1" ];then
    echo Aborting the renaming operation!
    echo " "

else
    # We store the extension of the file to be renamed
    file_to_rename_extension=${user_input##*.}
   
   # If there was no extension, we set the variable to an empty string
    if [ "${file_to_rename_extension}" = "${user_input}" ]; then
        file_to_rename_extension=""
    fi
    
    echo The previous filename was: ${user_input}
    read -r -p "Please introduce a new name (without including the extension, if it exists): " new_name
    
    while [ -z "${new_name}" ]; do
        echo A non empty name must be specified
        read -r -p "Please introduce a new name (without including the extension): " new_name
    done

    # We perform the same operation but with different params depending on whether the file had an extension or not
    if [ -z "${file_to_rename_extension}" ]; then
        
       mv "${user_input}" "${new_name}"
        log_command "RENAME FILE" "${user_input} -> ${new_name}"
    
    else
        mv "${user_input}" "${new_name}.${file_to_rename_extension}"
        log_command "RENAME FILE" "${user_input} -> ${new_name}.${file_to_rename_extension}"
    fi
fi

}


handle_restore_backups()
{
# In this case, we are going to create a  directory where the backed up files are going to be place. Then, all the backup zip files will be  unpacked.
# Afterwards, any possible file conflict is resolved by keeping the most recent version. The user can later take that backup and place the folders wherever they wish.

# THE BACKUPS THAT WERE USED are stored in a folder called USED

# We first check if any backup zip files actually exist. We obtain
# all the possible files and then give them to grep which will generate
# an error code if no matches were found
if ! ls "${backup_file}"*.zip 2>/dev/null | grep -q ".";then
    echo "No backup files found. Aborting the restore operation!"
    echo " "
else
    # We fist create the directory, if it does not exist. If it exists, the error is not displayed
    mkdir "${backup_restore_dir}" 2>/dev/null

    # We create a folder to archive used zips so that they are not unzipped again
    mkdir "${backup_used_dir}" 2>/dev/null
    
    # Temporary directory to extract each zip before resolving conflicts
    temp_dir="${backup_restore_dir}/.tmp_dir"

    # We store all zips into an array
    declare -a backup_file_list
    backup_file_list=($(ls "${backup_file}"*.zip 2>/dev/null))

    echo "Found ${#backup_file_list[@]} backup(s) to restore."
    echo " "
    
    for backup_zip_path in "${backup_file_list[@]}";do
        zip_name=$(basename "${backup_zip_path}")

        # We remove and clean the temporary directory which is full with the information of the previous unzipped backup file
        rm -rf "${temp_dir}" 2>/dev/null

        # We create it again
        mkdir "${temp_dir}"

        # We extract the current zip into temp folder
        unzip -q "${backup_zip_path}" -d "${temp_dir}"

        if [ $? -ne 0 ]; then
            echo Failed to restore "${zip_name}", skipping
            echo " "
            continue
        fi

        # We now analyze every extracted file and resolve possible conflicts
        # We set -d '' so that it reads all the content line by line(file by file)
        while IFS= read -r -d '' extracted_file; do
            
            # Obtain the path to be created at the RESTORED_CONTENT DIR
            relative_path="${extracted_file#${temp_dir}/}"

            # We construct the destionation path to this unzipped data
            destination="${backup_restore_dir}/${relative_path}"

            # -e means that the file exists(can be any type of file)
            if [ ! -e  "${destination}" ];then
                # The file does not exist so we copy it
                mkdir -p "$(dirname "${destination}")"

               # -a flag to keep the original files' metadata
                cp -a "${extracted_file}" "${destination}"
            
            else
                # In this case there is a conflict as the file already exists
                # in the backup folder. This means it was backed up by a previous zip.
                # We compare their modification dates and keep the latest one
                
                if [ "${extracted_file}" -nt "${destination}" ];then
                   
                   # -a flag to keep the original files' metadata
                    cp -a "${extracted_file}" "${destination}"
                
                fi
            fi

        # We iterate over all the files and use the print0 flag to terminate all the filenames by \0
        done < <(find "${temp_dir}" -type f -print0)
        mv "${backup_zip_path}" "${backup_used_dir}/${zip_name}"
        log_command "RESTORE" "${zip_name}"
        
        # We cleanup the temporary directory
        rm -rf "${temp_dir}"
    done
    echo Backup completed. Backups which were successfully applied at USED dir.
    echo Retrieved contents at RESTORED_CONTENT folder 

fi

}

echo " "
echo The current directory is ${PWD}
echo " "

PS3="Select a number from the OPTION menu: "
COLUMNS=1; select option in "${menu_options[@]}";
do
    case $option in 
        "$QUIT")
           
            echo " "
            echo The execution has been terminated
            break
            ;;

        "MODIFY FILE TREE")
            
            echo " "
            # We call the function that handles the files
            handle_file_tree              
            ;;

        "OBTAIN PREVIOUS ACTIONS")
            
            echo " "
            handle_log_file_print
            ;;

        "BACKUP FILES(ZIP)")
            
            echo " "
            handle_backup_zip
            ;;

        "RESTORE BACKUPS")
            
            echo " "
            handle_restore_backups
            ;;

        "CHANGE SCRIPT'S WORKING DIRECTORY")
            
            echo " "
            handle_change_directory
            ;;

        "RENAME FILE")
            
            echo " "
            handle_rename_file
            ;;
    esac
done

