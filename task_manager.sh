#!/bin/bash

# Este script permite especificar una tarea a realizar y se le pasa el parámetro y se crea

# Primero comprobamos que no se haya pasado ningún parámetro al ejecutar el script

if [ $# -ne 0 ]
then
    echo The script execution does not admit any parameters
    exit 1
fi

# A continuacion mostramos al usuario las opciones que se pueden realizar


# IDEAS
# PARA CREATE/DELETE FILES se quiere mostrar el directorio actual y si el usuario añade un nombre
# o borrar algún nombre, el contenido se borra
# PARA EL LOG QUE PERMITA FILTRAR PARA POR EJEMPLO OBTENER LAS ULTIMAS 10 ACCIONES Y TAL
#
#
declare -a menu_options
declare -i resultado_exec
prev_file=".prev_dir_content.txt"
cur_file=".updated_dir_content.txt"
resultado_exec=-1
menu_options=("MODIFY FILE TREE" "BACKUP FILES(ZIP)" "OBTAIN PREVIOUS COMMANDS" "QUIT")
PS3="Selected-Action: "
QUIT=${menu_options[-1]}

check_updated_tree(){
    
    # This first while is used to detect the files that were deleted
    while IFS= ;read -r linea; do

        if ! grep -qFx "$linea" "${cur_file}"; then
            #If this first condition is met, this means that the file or directory
            # no longer exists, so we delete it
            rm -rf "$linea"
        fi
    done < ${prev_file}

    # We develop a second while to detect the added files or directories
    while IFS= ;read -r linea; do
            if ! grep -qFx "$linea" "${prev_file}"; then
                # This means the line was not found on the previous file. Therefore,
                # it corresponds to a new file/directory we must create
                
                if [[ ${linea:(-1)} == '/' ]]; then
                    # This means it is a directory, we create it without the /
                    mkdir -p "${linea%/}"
                
                else
                    # This means it is a file
                    touch "$linea"
                    
                fi

            fi
    done < ${cur_file}

    # We finally delete the intermidiate files created
    rm -f "${prev_file}" "${cur_file}"
}



handle_file_tree(){
    
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
        echo No text editor could be opened, returning to the option menu
    
    fi    
}


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
    esac

done

