# **OstrichDB**

OstrichDB is a lightweight, document-based NoSQL DBMS written in the Odin programming language. It can be run serverless from the command line or deployed in server mode, offering flexibility for different use cases. With a focus on simplicity and straightforward setup, OstrichDB provides an intuitive command structure for managing data using both single and multi-token commands.


---

## **Key Features**

- Natural Language Processing for fast queries and data retrieval
- Three Modes of Operation:
  - Serverless Command-line Interface
  - Server Mode with HTTP API
  - Server Mode with the built-in natural language processor
- User Authentication
- User Role-Based Access
- Database permissions
- Database encryption & decryption
- Custom JSON-like Hierarchical Data Structure
- .CSV file importing
- Dot Notation Syntax when using the serverless CLI
- Command Chaining
- Built-in benchmarking, configurations, and user command history
- Exclusive macOS Support

## **Installation**

### **Prerequisites:**
- A Unix-based system (macOS, Linux).
- The [Go](https://go.dev/) programming language installed, and properly set in the systems PATH. Ideal Go version: `go1.23.1`
- The [Odin](https://odin-lang.org/) programming language installed, built, and properly set in the system's PATH. Ideal Odin Version: `dev-2024-11:764c32fd3`
*Note: You can achieve the previous step by following the [Odin Installation Guide](https://odin-lang.org/docs/install/)*

#### **Special Cases:**
 - if you wish to use the OstrichDB Natural Language Processor you will need to have [Ollama](https://ollama.com/download) installed
 - If you are an "End User" and plan install OstrichDB on your machine you will need [curl](https://curl.se/) installed

### Installation For Contributors:
#### **Steps:**

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Solitude-Software-Solutions/OstrichDB.git
   ```

2. **Navigate to the OstrichDB Directory**:
   ```bash
   cd path/to/OstrichDB
   ```

3. **Make the Build, Run & Restart Scripts Executable**:
   ```bash
   chmod +x scripts/local_build_run.sh && chmod +x scripts/local_build.sh && chmod +x scripts/restart.sh
   ```

4. **Run The Build Script**:
   ```bash
   ./scripts/local_build_run.sh
   ```


### Installation For End Users:
#### **Steps:**
1. Use curl to download the latest release:
   ```bash
   curl -o install.sh https://raw.githubusercontent.com/Solitude-Software-Solutions/OstrichDB/27b7074f9a4b33fa15254e0e93996d67afc5f84c/scripts/install.sh
   ```

2. Make the script executable:
    ```bash
    chmod +x install.sh
    ```
3. Run the script:
    ```bash
    ./install.sh
    ```
4. Find and run the OstrichDB executable:
*Note: This will be located in a directory called `.ostrichdb` in the same directory as the install script.*
You can run the executable by double clicking it or running it from the terminal with the following command:
    ```bash
    ./path/to/.ostrichdb/ostrichdb
    ```


### Installing From Source:
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Solitude-Software-Solutions/OstrichDB.git
   ```

2. **Navigate to the OstrichDB Directory**:
   ```bash
   cd path/to/OstrichDB
   ```
3. Open the `local_install.sh` script and follow the directions at the top of the file.
4. Run the script:
   ```bash
   ./local_install.sh
   ```
5. Find you installed OstirchDB executable in the `.ostrichdb` directory in the same directory you chose to install OstrichDB in via the `local_install.sh` script.
6. Run the executable by double clicking it or running it from the terminal with the following command:
    ```bash
    ./path/to/.ostrichdb/ostrichdb
    ```



---


## **Data Structure Overview**

OstrichDB organizes data into three levels:

- **Records**: The smallest unit of data. e.g user_name, age, email. Format: [name] :[type]: [value]
- **Clusters**: Groups of related records. Given a name and an id upon creation.
- **Collections**: Database files containing clusters, Have the '.ostrichdb' extension.

---

## **Command Structure (CLPs)**

In OstrichDB, commands are typically broken into **three types of tokens**, called **CLPs**, to improve readability and ensure clear instructions.

**Note:** Not all commands require all 3 tokens.


1. **(C)ommand Token**: Specifies the operation to perform (e.g., `NEW`, `ERASE`, `RENAME`).
2. **(L)ocation Token**: The dot notation path that the command will be performed on (e.g., `foo.bar.baz`).
3. **(P)arameter Token(s)**: Additional parameters that change the behavior of the command (e.g., `TO`, `OF_TYPE`).

---

### **Command Walkthrough**

```bash
NEW foo.bar.baz OF_TYPE []STRING
```
Explanation:
- **`NEW`**: Create a new object (Command token).
- **`foo`**: The fisrt object always points to a collection. (Location token). Note: If there is only 1 object given, its a collection.
- **`bar`**: The second object always to a cluster within the collection. (Location token).
- **`baz`**: The third object is always a record within the cluster. (Location token).
- **`OF_TYPE`**: Specifies the data type of the record (Parameter token). Note: Only records are given data types.
- **`[]STRING`**: The record will be an array of strings (Parameter token).

---

## **Supported Commands**

### **Single-Token Operations**
These operations perform a task without any additional arguments.

- **`AGENT`**: Starts the OstrichDB natural language processor. Requires the server to be running in another terminal.
- **`VERSION`**: Displays the current version of OstrichDB.
- **`LOGOUT`**: Logs out the current user.
- **`EXIT`**: Ends the session and closes the DBMS.
- **`RESTART`**: Restarts the program.
- **`REBUILD`**: Rebuilds the DBMS and restarts the program.
- **`SERVE/SERVER`**: Turns on the OstrichDB server allowing http requests to be made.
- **`HELP`**: Displays general help information or detailed help when chained with specific tokens.
- **`TREE`**: Displays the entire data structure in a tree format.
- **`CLEAR`**: Clears the console screen.
- **`HISTORY`**: Shows the current users command history.
- **`DESTROY`**: Completley destorys the entire DBMS. Including all databases, users, configs, and logs.
- **`BENCHMARK`**: Runs a benchmark test on the DBMS to test performance. Can be run with or without parameters.

---

### **Multi-Token Operations**
These operations allow you to perform more complex operations.

- **`NEW`**: Create a new collection, cluster, record, or user.
- **`ERASE`**: Delete a collection, cluster, or record.
- **`RENAME`**: Rename an existing object.
- **`FETCH`**: Retrieve data from a collection, cluster, or record.
- **`SET`**: Assign a value to a record or configuration.
- **`BACKUP`**: Create a backup of a specific collection.
- **`PURGE`**: Removes all data from an object while maintining the object structure.
- **`COUNT`**: Returns the number of objects within a scope. Paired with the plural form of the object type (e.g., `RECORDS`, `CLUSTERS`).
- **`SIZE_OF`**: Returns the size in bytes of an object.
- **`TYPE_OF`**: Returns the type of a record.
- **`CHANGE_TYPE`**: Allows you to change the type of a record.
- **`HELP`**: Displays help information for a specific token.
- **`ISOLATE`**: Quarentines a collection file. Preventing any further changes to the file
- **`WHERE`**: Searches for the location of a single or several record(s) or cluster(s). DOES NOT WORK WITH COLLECTIONS.
- **`VALIDATE`**: Validates a collection file for any errors or corruption.
- **`BENCHMARK`**: Runs a benchmark test on the DBMS to test performance. Can be run with or without parameters.
- **`LOCK`**: Used to change the access mode of a collection. Using `LOCK {collection_name} -r` sets a collection to Read-Only. Removing the `-r` will set a collection to Inaccessible.
- **`UNLOCK`**: Changes the access mode of a collection to the default Read-Write.
- **`ENC`** : Encrypts a collection.
- **`DEC`** : Decrypts a currently encrypted collection.  Use at own discretion.
- **`IMPORT`**: Allows the user to import a .csv file into OstrichDB. This will create a new collection thay shares the name of the .csv file.
---

### **Parameters**
Modifiers adjust the behavior of commands. The current supported modifiers are:

- **`OF_TYPE`**: Specifies the type of a new record (e.g., INT, STR, []BOOL)
- **`WITH`**: Used to assign a value to a record in the same command you are creating it(e.g `NEW {collection_name}.{cluster_name}.{record_name} OF_TYPE {record_type} WITH {record_value}`)
- **`TO`**: Used to assign a new value or name to a data structure or config(e.g `RENAME {old_collection_name} to {new_collection_name}`)

### **Command Chaining**
OstrichDB supports command chaining, allowing you to execute multiple commands in sequence with a single input. Commands are separated by the `&&` operator, and they will be executed in the order they appear.

Example:
```bash
RENAME foo.bar.baz TO goob && FETCH fetch foo.bar.goob
```


## **Supported Record Data Type Tokens**
When setting a record value, you must specify the records data type by using the `OF_TYPE` modifier. Some types have a shorthand notation for convenience.

### Primary data types include:
  - **`INTEGER`**: Integer values. Short-hand: `INT`.
  - **`STRING`**: Any text value longer than 1 character. Short-hand: `STR`.
  - **`FLOAT`**: Floating-point numbers. Short-hand: `FLT`.
  - **`BOOLEAN`**: true or false values. Short-hand: `BOOL`.
  - **`CHAR`**: Single character values. No short-hand.

### Complex data types include:
*NOTE: When setting array values, separate each element with a comma WITHOUT spaces.*
  - **`[]STRING`**: String arrays. Short-hand: `[]STR`.
  - **`[]INTEGER`**: Integer arrays. Short-hand: `[]INT`.
  - **`[]FLOAT`**: Float arrays. Short-hand: `[]FLT`.
  - **`[]BOOLEAN`**: Boolean arrays. Short-hand: `[]BOOL`.
  - **`[]CHAR`**: Character arrays. No short-hand.


### Other supported data types include:
  - **`DATE`**: Must be in `YYYY-MM-DD` format. No short-hand.
  - **`TIME`**: Must be in `HH:MM:SS` format. No short-hand.
  - **`DATETIME`**: Must be in `YYYY-MM-DDTHH:MM:SS` format. No short-hand.
  - **`[]DATE`**: Date arrays. Each value must follow the above format. No short-hand.
  - **`[]TIME`**: Time arrays. Each value must follow the above format. No short-hand.
  - **`[]DATETIME`**: Date and time arrays. Each value must follow the above format. No short-hand.
  - **`NULL`**: Null value. No short-hand.

    *Note: UUIDs can only have `0-9` and `a-f` characters and must be in the format `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`.*
  - **`UUID`**: Universally unique identifier. Must follow the above format. No short-hand.
  - **`[]UUID`**: UUID arrays. Each value must follow the above format. No short-hand.

---

## **Usage Examples**
   ```bash
   # Create a new collection:
   NEW staff
   # Create a new cluster:
   NEW staff.engineering
   # Create a new record:
   NEW staff.engineering.team_one OF_TYPE []STRING
   # Set a record value:
   SET staff.engineers.team_one TO Alice,Bob,Charlie
   # Fetch the record value:
   FETCH staff.engineers.team_one
   # Rename a cluster:
   RENAME staff.engineering TO HR
   # Get the size of a cluster:
   SIZE_OF staff.HR
   # Erase a record:
   ERASE staff.HR.team_one
   # Get a count of all collections in the database:
   COUNT COLLECTIONS
   #Get help information for a specific token:
   HELP {TOKEN_NAME}
   # Get general help information
   HELP
   # Create a new user
   NEW USER
   ```
---

## **Configs**
OstrichDB has a configuration file that allows the user to customize the DBMS to their liking.
- **`HELP_VERBOSE`**: Decide whether help information is simple or verbose. (Default is false)
- **`ERROR_SUPPRESSION`**: show or hide error messages. (Default is false)
- **`LIMIT_HISTORY`**: Ensure whether a users command history does or does not exceed the built in limit(100) (Default is true)


**Note: ALL configs must be set using the following command:**
Values can only be `true` or `false`

```
SET CONFIG {CONFIG_NAME} TO {VALUE}
```

---
## **Future Plans**

- More configuration options
- Several new command tokens:
  - `EXPORT`: Export data to various formats
  - `RESTORE`: Restores a collection backup in the place of the original collection
  - `MERGE`: Combine multiple collections or clusters into one
- Command chaining for even more complex operations
- OstrichDB web application
- Linux support
- Windows support
- External API support for even more programming languages!
- Integration with the planned Feather query language!

---

## **Contributing**

Please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on how to contribute.

---

## **License**

OstrichDB is released under the **Apache License 2.0**. For the full license text, see [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
