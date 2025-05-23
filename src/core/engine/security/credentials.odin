package security

import "../../../utils"
import "../../const"
import "../../types"
import "../config"
import "../data"
import "../data/metadata"
import "core:c/libc"
import "core:crypto/hash"
import "core:encoding/hex"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic for handling user management,
            including creating, deleting, and updating
            user accounts.
*********************************************************/

//Generates the 'secure' directory for storing user credentials.
GENERATE_SECURE_DIRECTORY :: proc() -> int {
	using utils

	//perform a check to see if the secure directory already exists to prevent errors and overwriting
	_, err := os.stat(const.SECURE_COLLECTION_PATH)
	if err == nil {
		return 0
	}
	createDirSuccess := os.make_directory(const.SECURE_COLLECTION_PATH)
	if createDirSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_CREATE_DIRECTORY,
			get_err_msg(.CANNOT_CREATE_DIRECTORY),
			#file,
			#procedure,
			#line,
		)
		throw_err(error1)
		log_err("Error occured while attempting to generate new secure file", #procedure)
	}
	return 0
}

//Handle initial setup of the admin account on first run of the program
HANDLE_FIRST_TIME_ACCOUNT_SETUP :: proc() -> int {
	using types
	using data
	using const

	buf: [256]byte
	GENERATE_SECURE_DIRECTORY()
	GENERATE_USER_ID()
	fmt.printfln("Welcome to the OstrichDB Database Management System")
	fmt.printfln("Before getting started please setup your admin account")
	fmt.printfln("Please enter a username for the admin account")

	inituserName := CREATE_NEW_USERNAME(true)
	fmt.printfln("Please enter a password for the admin account")
	fmt.printf(
		"Passwords MUST: \n 1. Be least 8 characters \n 2. Contain at least one uppercase letter \n 3. Contain at least one number \n 4. Contain at least one special character \n",
	)
	libc.system("stty -echo")
	initpassword := CREATE_NEW_USER_PASSWORD(true)
	saltAsString := string(user.salt.valAsBytes)
	hashAsString := string(user.hashedPassword.valAsBytes)

	algoMethodAsString := fmt.tprintf("%d", user.store_method)
	user.user_id = data.GENERATE_ID(true) //for secure clustser, the cluster id is the user id

	CREATE_COLLECTION("", .HISTORY_PRIVATE)
	//decrypt the id collection so that new cluster IDs can be added upon engine initialization
	user.username.Value = inituserName
	// //store the id to both clusters in the id collection
	APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", user.user_id), 0)
	APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", user.user_id), 1)


	// //Create a cluster in the history collection that will hold this users command history
	CREATE_CLUSTER_BLOCK(HISTORY_PATH, user.user_id, user.username.Value)


	//Create a secure collection for the user
	inituserName = fmt.tprintf("secure_%s", inituserName)
	CREATE_COLLECTION(inituserName, .SECURE_PRIVATE)
	// GENERATE_MASTER_KEY returns a 32 byte master key that is hex encoded
	mk := GENERATE_MASTER_KEY()
	mkAsString := transmute(string)mk //dont worry about this
	// user.m_k.valAsStr = mkAsString //dont worry about this

	//this value is passed to my encryption and decryption functions. must be 32 bytes
	user.m_k.valAsBytes = DECODE_MASTER_KEY(mk)

	//Store all the user credentials within the secure collection
	STORE_USER_CREDENTIALS(
		inituserName,
		user.username.Value,
		user.user_id,
		"user_name",
		user.username.Value,
	)
	STORE_USER_CREDENTIALS(inituserName, user.username.Value, user.user_id, "role", "admin")
	STORE_USER_CREDENTIALS(inituserName, user.username.Value, user.user_id, "salt", saltAsString)
	STORE_USER_CREDENTIALS(inituserName, user.username.Value, user.user_id, "hash", hashAsString)
	STORE_USER_CREDENTIALS(
		inituserName,
		user.username.Value,
		user.user_id,
		"store_method",
		algoMethodAsString,
	)

	STORE_USER_CREDENTIALS(inituserName, user.username.Value, user.user_id, "m_k", mkAsString)

	engineInit := config.UPDATE_CONFIG_VALUE(ENGINE_INIT, "true")

	switch (engineInit) 
	{
	case true:
		USER_SIGNIN_STATUS = true
	case false:
		fmt.printfln("Error toggling config")
		os.exit(1)
	}

	metadata.UPDATE_METADATA_UPON_CREATION(HISTORY_PATH)
	metadata.UPDATE_METADATA_UPON_CREATION(ID_PATH)
	metadata.UPDATE_METADATA_UPON_CREATION(CONFIG_PATH)
	metadata.UPDATE_METADATA_UPON_CREATION(
		fmt.tprintf("%s%s%s", SECURE_COLLECTION_PATH, inituserName, OST_EXT),
	)

	//Encrypt the the config, history, id, and new users secure collection
	ENCRYPT_COLLECTION(user.username.Value, .SECURE_PRIVATE, system_user.m_k.valAsBytes, false)
	ENCRYPT_COLLECTION("", .CONFIG_PRIVATE, system_user.m_k.valAsBytes, false)
	ENCRYPT_COLLECTION("", .HISTORY_PRIVATE, system_user.m_k.valAsBytes, false)
	ENCRYPT_COLLECTION("", .ID_PRIVATE, system_user.m_k.valAsBytes, false)


	fmt.println("Please re-launch OstrichDB...")
	return 0
}


//Generates and returns a unique id
GENERATE_USER_ID :: proc() -> i64 {
	userID := rand.int63_max(1e16 + 1)
	if data.CHECK_IF_USER_ID_EXISTS(userID) == true {
		utils.log_err("Generated ID already exists in user file", #procedure)
		GENERATE_USER_ID()
	}
	types.user.user_id = userID
	return userID

}

//Prompts user to select a username, ensures it not too long/short or taken, then returns the username
//the isInitializing param will be false when if creating an account post engine initialization,
CREATE_NEW_USERNAME :: proc(isInitializing: bool) -> string {
	using types
	using utils

	show_current_step("Set Up Username", "1", "3")
	buf: [256]byte
	input := utils.get_input(false)


	if len(input) > 0 {
		enteredStr := input

		//trim the string of any whitespace or newline characters at the beginning and end
		enteredStr = strings.trim_right_proc(enteredStr, proc(r: rune) -> bool {
			return r == '\r' || r == '\n'
		})

		//At the first instance of a space in the username, warn then prompt again
		for r in enteredStr {
			if r == ' ' {
				fmt.printfln(
					"%sWARNING:%s The entered username: %s%s%s contains spaces. Please enter a username that does NOT contain spaces.\n",
					utils.YELLOW,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					enteredStr,
					utils.RESET,
				)
				CREATE_NEW_USERNAME(true)
			}
		}

		// Ensure there are no invalid special characters in the username
		for r in enteredStr {
			if r == '!' ||
			   r == '@' ||
			   r == '#' ||
			   r == '$' ||
			   r == '%' ||
			   r == '^' ||
			   r == '&' ||
			   r == '.' ||
			   r == '*' ||
			   r == '_' ||
			   r == '(' ||
			   r == ')' ||
			   r == '+' ||
			   r == '=' ||
			   r == '[' ||
			   r == ']' ||
			   r == '{' ||
			   r == '}' ||
			   r == '|' ||
			   r == ';' ||
			   r == ':' ||
			   r == '"' ||
			   r == '\'' ||
			   r == '<' ||
			   r == '>' ||
			   r == ',' ||
			   r == '/' ||
			   r == '?' {
				fmt.printfln(
					"%sWARNING:%s The entered username: %s%s%s contains special characters. Please enter a username that does NOT contain special characters.",
					utils.YELLOW,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					enteredStr,
					utils.RESET,
				)
				fmt.println("The only valid special character is '-'.\n")
				CREATE_NEW_USERNAME(true)
			}
		}


		if (len(enteredStr) > 32) {
			fmt.printfln(
				"Username is too long. Please enter a username that is 32 characters or less",
			)
			if isInitializing == true {
				CREATE_NEW_USERNAME(true)
			} else if isInitializing == false {
				CREATE_NEW_USERNAME(false)
			}
		} else if (len(enteredStr) < 2) {
			fmt.printfln(
				"Username is too short. Please enter a username that is 2 characters or more",
			)
			if isInitializing == true {
				CREATE_NEW_USERNAME(true)
			} else if isInitializing == false {
				CREATE_NEW_USERNAME(false)
			}
		} else {
			if isInitializing == true {
				user.username.Value = strings.clone(enteredStr)
				user.username.Length = len(enteredStr)
			} else if isInitializing == false {
				new_user.username.Value = strings.clone(enteredStr)
				new_user.username.Length = len(enteredStr)
			}
		}

	}
	if isInitializing == false {
		return strings.clone(strings.to_upper(new_user.username.Value))
	}

	return strings.clone(strings.to_upper(user.username.Value))
}


//Prompts the user for a password, checks if it is strong enough, then calls the confirm password proc
//the isInitializing param will be false when if creating an account post engine initialization,
CREATE_NEW_USER_PASSWORD :: proc(isInitializing: bool) -> string {
	using types
	using utils

	utils.show_current_step("Set Up Password", "2", "3")
	buf: [256]byte
	input := utils.get_input(true)
	enteredStr: string

	if len(input) > 0 {
		enteredStr = input
		//trim the string of any whitespace or newline characters

		//Shoutout to the OdinLang Discord for helping me with this...
		enteredStr = strings.trim_right_proc(enteredStr, proc(r: rune) -> bool {
			return r == '\r' || r == '\n'
		})
		if (isInitializing == true) {
			user.password.Value = enteredStr
		} else if (isInitializing == false) {
			new_user.password.Value = enteredStr
		}
	}

	strongPassword := check_password_strength(enteredStr)

	switch strongPassword 
	{
	case true:
		CONFIRM_NEW_USER_PASSWORD(enteredStr, isInitializing)
		break
	case false:
		fmt.printfln("Please try again")
		CREATE_NEW_USER_PASSWORD(isInitializing)
		break
	}

	return strings.clone(enteredStr)
}

//Takes in p as password and compares it to the confirmation password
//if the passwords do not match, the user is prompted to re-enter the password
//the isInitializing param will be false when if creating an account post engine initialization,
CONFIRM_NEW_USER_PASSWORD :: proc(p: string, isInitializing: bool) -> string {
	using types
	using utils

	utils.show_current_step("Confirm Password", "3", "3")
	buf: [256]byte

	fmt.printfln("Re-enter the password:")
	input := utils.get_input(true)
	confirmation: string


	if len(input) > 0 {
		confirmation = input
		//trim the string of any whitespace or newline characters

		//Shoutout to the OdinLang Discord for helping me with this...
		confirmation = strings.trim_right_proc(confirmation, proc(r: rune) -> bool {
			return r == '\r' || r == '\n'
		})
	}
	if p != confirmation {
		fmt.printfln("Passwords do not match. Please try again")
		CREATE_NEW_USER_PASSWORD(isInitializing)
	} else {

		if isInitializing == true {
			user.password.Length = len(p)
			user.password.Value = strings.clone(p)
			user.hashedPassword.valAsBytes = HASH_PASSWORD(p, 0, false, true)

			encodedPassword := ENCODE_HASHED_PASSWORD(user.hashedPassword.valAsBytes)
			user.hashedPassword.valAsBytes = encodedPassword

		} else if isInitializing == false {
			new_user.password.Length = len(p)
			new_user.password.Value = strings.clone(p)
			new_user.hashedPassword.valAsBytes = HASH_PASSWORD(p, 0, false, false)

			encodedPassword := ENCODE_HASHED_PASSWORD(new_user.hashedPassword.valAsBytes)
			new_user.hashedPassword.valAsBytes = encodedPassword
			return new_user.password.Value
		}
	}
	libc.system("stty echo")
	return strings.clone(types.user.password.Value)
}

//Stores the entered user credentials in the users secure collection file/cluster
// cn- cluster name, id- cluster id, rn- record name, rd- record data
STORE_USER_CREDENTIALS :: proc(fn: string, cn: string, id: i64, rn: string, rd: string) -> int {
	using metadata
	using const
	using utils

	secureFilePath := concat_secure_collection_name(fn)

	file, openSuccess := os.open(secureFilePath, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(file)
	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#file,
			#procedure,
			#line,
		)
		throw_err(error1)
		log_err("Error opening user credentials file", #procedure)
	}
	defer os.close(file)


	data.CREATE_CLUSTER_BLOCK(secureFilePath, id, cn)
	data.CREATE_AND_APPEND_PRIVATE_RECORD(secureFilePath, cn, rn, rd, "identifier", id)

	UPDATE_METADATA_AFTER_OPERATIONS(secureFilePath)
	return 0
}

// checks if the passed in password is strong enough returns true or false.
check_password_strength :: proc(p: string) -> bool {
	specialChars: []string = {"!", "@", "#", "$", "%", "^", "&", "*"}
	charsLow: []string = {
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
		"g",
		"h",
		"i",
		"j",
		"k",
		"l",
		"m",
		"n",
		"o",
		"p",
		"q",
		"r",
		"s",
		"t",
		"u",
		"v",
		"w",
		"x",
		"y",
		"z",
	}
	charsUp: []string = {
		"A",
		"B",
		"C",
		"D",
		"E",
		"F",
		"G",
		"H",
		"I",
		"J",
		"K",
		"L",
		"M",
		"N",
		"O",
		"P",
		"Q",
		"R",
		"S",
		"T",
		"U",
		"V",
		"W",
		"X",
		"Y",
		"Z",
	}
	nums: []string = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}

	longEnough: bool
	hasNumber: bool
	hasSpecial: bool
	hasUpper: bool
	strong: bool


	// //check for the length of the password
	switch (len(p)) 
	{
	case 0:
		fmt.printfln("Password cannot be empty. Please enter a password")
		return false
	case 1 ..< 8:
		fmt.printfln("Password is too short. Please enter a password that is 8 characters or more")
		return false
	case 32 ..< 1000:
		fmt.printfln("Password is too long. Please enter a password that is 32 characters or less")
		return false
	case:
		longEnough = true
	}

	//check for the presence of numbers
	for i := 0; i < len(nums); i += 1 {
		if strings.contains(p, nums[i]) {
			hasNumber = true
		}
	}

	// check for the presence of special characters
	for i := 0; i < len(specialChars); i += 1 {
		if strings.contains(p, specialChars[i]) {
			hasSpecial = true
			break
		}
	}
	//check for the presence of uppercase letters
	for i := 0; i < len(charsUp); i += 1 {
		if strings.contains(p, charsUp[i]) {
			hasUpper = true
			break
		}
	}

	switch (true) 
	{
	case longEnough && hasNumber && hasSpecial && hasUpper:
		strong = true
	case !hasNumber:
		fmt.printfln("Password must contain at least one number")
		strong = false
	case !hasSpecial:
		fmt.printfln("Password must contain at least one special character")
		strong = false
	case !hasUpper:
		fmt.printfln("Password must contain at least one uppercase letter")
		strong = false
	}

	return strong
}

// creates a new user account post engine initialization
//also determines if the currently logged in user has permission to create a new user account
//allows for test mode to be used to create a new user without the need for interactive input
// OST_CREATE_NEW_USER :: proc(
// 	username: string = "",
// 	password: string = "",
// 	role: string = "",
// ) -> int {
// 	using types

// 	buf: [1024]byte
// 	if user.role.Value == "admin" {
// 		fmt.println("Please enter role you would like to assign the new account")
// 		fmt.printf("1. Admin\n2. User\n3. Guest\n")
// 		input := utils.get_input(false)

// 		inputToCap := strings.to_upper(input)
// 		if inputToCap == "1" || inputToCap == "ADMIN" {
// 			new_user.role.Value = "admin"
// 		} else if inputToCap == "2" || inputToCap == "USER" {
// 			new_user.role.Value = "user"
// 		} else if inputToCap == "3" || inputToCap == "GUEST" {
// 			new_user.role.Value = "guest"
// 		} else {
// 			fmt.printfln("Invalid role entered")
// 			return 1
// 		}
// 	} else if (user.role.Value == "user") {
// 		new_user.role.Value = "guest"
// 	} else {
// 		fmt.println("You do not have the required permissions to create a new account")
// 		fmt.printfln("To create a new account you must be logged in as an admin or user account")
// 		return 1
// 	}

// 	newUserName := CREATE_NEW_USERNAME(false)
// 	new_user.username.Value = newUserName


// 	// Common validation logic for both test and interactive modes
// 	isBannedUsername := check_if_username_is_banned(new_user.username.Value)
// 	if isBannedUsername {
// 		fmt.printfln("Username is banned. Please enter a different username")
// 		fmt.println("Cannot create user with name: ", new_user.username.Value)
// 		return 1
// 	}

// 	newColName := fmt.tprintf("secure_%s", new_user.username.Value)
// 	exists, _ := data.FIND_SECURE_COLLECTION(newColName)

// 	if exists {
// 		fmt.printfln(
// 			"There is already a user with the name: %s%s%s\nPlease try again.",
// 			utils.BOLD_UNDERLINE,
// 			new_user.username.Value,
// 			utils.RESET,
// 		)
// 		return 1
// 	}

// 	result := data.CREATE_COLLECTION(newColName, .SECURE_PRIVATE)
// 	fmt.printf(
// 		"Passwords MUST: \n 1. Be least 8 characters \n 2. Contain at least one uppercase letter \n 3. Contain at least one number \n 4. Contain at least one special character \n",
// 	)
// 	libc.system("stty -echo")
// 	initpassword := CREATE_NEW_USER_PASSWORD(false)
// 	libc.system("stty echo")
// 	new_user.password.Value = initpassword


// 	saltAsString := string(new_user.salt.valAsStr)
// 	hashAsString := string(new_user.hashedPassword.valAsStr)
// 	algoMethodAsString := strconv.itoa(buf[:], new_user.store_method)

// 	new_user.user_id = data.GENERATE_ID(true)

// 	//store the id to both clusters in the id collection
// 	data.APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", new_user.user_id), 0)
// 	data.APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", new_user.user_id), 1)

// 	// Store user credentials
// 	STORE_USER_CREDENTIALS(
// 		newColName,
// 		new_user.username.Value,
// 		new_user.user_id,
// 		"user_name",
// 		new_user.username.Value,
// 	)
// 	STORE_USER_CREDENTIALS(
// 		newColName,
// 		new_user.username.Value,
// 		new_user.user_id,
// 		"role",
// 		new_user.role.Value,
// 	)
// 	STORE_USER_CREDENTIALS(
// 		newColName,
// 		new_user.username.Value,
// 		new_user.user_id,
// 		"salt",
// 		saltAsString,
// 	)
// 	STORE_USER_CREDENTIALS(
// 		newColName,
// 		new_user.username.Value,
// 		new_user.user_id,
// 		"hash",
// 		hashAsString,
// 	)
// 	STORE_USER_CREDENTIALS(
// 		newColName,
// 		new_user.username.Value,
// 		new_user.user_id,
// 		"store_method",
// 		algoMethodAsString,
// 	)

// 	// Create history cluster.
// 	data.CREATE_CLUSTER_BLOCK(const.HISTORY_PATH, user.user_id, new_user.username.Value)

// 	return 0
// }

//Checks that un as username is not a banned username from the banned usernames list
check_if_username_is_banned :: proc(un: string) -> bool {
	for i := 0; i < len(const.BannedUserNames); i += 1 {
		if strings.contains(un, const.BannedUserNames[i]) {
			return true
		}
	}
	return false
}
