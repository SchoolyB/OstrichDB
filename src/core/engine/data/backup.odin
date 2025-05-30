package data

import "../../../utils"
import "../../const"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic the implements the BACKUP commmand, allowing
            users to create backups of collections.
*********************************************************/


CREATE_BACKUP_COLLECTION :: proc(dest: string, src: string) -> bool {
	using const
	using utils
	//retirve the data from the src collection file
	srcPath := utils.concat_standard_collection_name(src)
	f, readSuccess := os.read_entire_file(srcPath)
	if !readSuccess {
		error1 := new_err(
			.CANNOT_READ_FILE,
			get_err_msg(.CANNOT_READ_FILE),
			#file,
			#procedure,
			#line,
		)
		throw_custom_err(error1, "Could not read collection file for backup")
		log_err("Could not read collection file for backup", #procedure)
		return false
	}

	data := f
	defer delete(data)

	//create a backup file dest and write the src content to it
	destNameAndPath := fmt.tprintf("%s%s", BACKUP_PATH, dest)
	destFullPath := fmt.tprintf("%s%s", destNameAndPath, OST_EXT)

	c, creationSuccess := os.open(destFullPath, os.O_CREATE | os.O_RDWR, 0o666)
	defer os.close(c)
	if creationSuccess != 0 {
		error1 := new_err(
			.CANNOT_CREATE_FILE,
			get_err_msg(.CANNOT_CREATE_FILE),
			#file,
			#procedure,
			#line,
		)
		throw_custom_err(error1, "Could not create collection file for backup")
		log_err("Could not create backup collection file", #procedure)
		return false
	}
	w, writeSuccess := os.write(c, data)
	if writeSuccess != 0 {
		error1 := new_err(
			.CANNOT_WRITE_TO_FILE,
			get_err_msg(.CANNOT_WRITE_TO_FILE),
			#file,
			#procedure,
			#line,
		)
		throw_custom_err(error1, "Could not write to collection file for backup")
		log_err("Could not write to collection file for backup", #procedure)
		return false
	}

	return true
}

CHOOSE_BACKUP_NAME :: proc() -> string {
	using utils
	fmt.printfln("What would you like to name your collection backup?")
	input := utils.get_input(false)
	return strings.clone(input)
}

//TODO: create a proc that deletes a backup of a collection
//TODO: create a proc that deletes all backups in the backups directory

//TODO: create a proc that restores a collection from a backup:
//this one will need some work. I see it as when a backup is created there needs to be some kind of identifier that lets the program know
//that "this backup is the backup for collection x" so when the user chooses to restore a backup, the backup
//will replace collection x. The tricky part will be when there are multiple backups for the same collection.
// perhaps a new metadata field gets added to a backup file to identify it as the backup for a specific collection.
//then the proc that handles the restore will check for that field and do its job. then remove the field so it doesn't interfere with future backups.
