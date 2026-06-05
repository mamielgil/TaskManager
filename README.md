This is a script was developed as a final project for Microcredencial Universitaria Programación de la Shell de Linux, a course
offered at the Universidad Carlos III de Madrid.

# Explanation

When executing this script, the user will be presented with a menu with 5 options.

## 1. MODIFY FILE TREE
    
When the user inputs a 1 in the menu, a text editor will be displayed with the current files and directories of the PWD.
By default, the script attempts to open the vi text editor and, if it fails, the nano editor. If neither of them are found, then
an error is shown and the user is returned to the option menu.
   
Within the text editor, the user can modify the current files and directories by directly typing in the editor. 
### Creating and deleting files

**To create a file**, the user must write the desired filename in a new line of the editor and then save the changes.
The script detects that a new name was added and creates a new file for it.

**To delete a file**, the user must delete the entire name of the filename. The script detects that there is a missing filename and it deletes it from the directory.

### Creating and deleting directories

The MODIFY FILE TREE also allows to create and delete directories in a very similar way to files.

**To create a directory**, the user must write the desired name for the directory and end such name with a /. **IF IT DOES NOT END WITH A /, IT WILL BE CONSIDERED A FILE**.

**To delete a directory**, it is done exactly in the same way as files, that is, deleting the entire name of the directory

## 2. BACKUP FILES(ZIP)

This options opens a text editor where the user can **specify the files they wish to be compressed**.
The user can keep the file as it is to compress  all the files of the current working directory.
Alternatively, if filesnames are deleted from the opened editor, those files will not be considered for the compression.
The first editor considered is vi, if not, nano is used. If neither of them are available, an error message will be displayed.

The generated ZIP file will be found within the directory where the script was executed from. **The ZIP file is called backup{number}.zip**
This way, subsequent backups will not overwrite the previous ones.

## 3.OBTAIN PREVIOUS ACTIONS

During the execution of the shell, a file called **task_manager.log** is generated and written upon. This file stores all the actions performed with the shell.
This way the user can track which files and directories were deleted or created and when. Apart from being able to access this file manually by terminating the script's execution,
the script provides an option to display the last n messages from said log file.

## 4. CHANGING SCRIPT'S WORKING DIRECTORY

This option allows to move between directories of your device so that you can add and remove files/directories in any path. In this option, a menu is displayed
with all the accessible directories from the current path. Then, after by specifying an number from the list, the script's working directory is moved to the new location.

## 5. QUIT

This option is used to terminate the execution of the script. When the number 5 is inputted within the options menu, the script finishes.




