# Installation Manual

## Prerequisites

- Bash shell environment
- `.env` file containing necessary environment variables
- Configuration file for SSH settings (`config_file`)

## Installation

### Automatic Instalation
This method requires that [.gitbash](https://github.com/sergio-rodrigues/.git_bash) is installed first:

To install the script, just execute:
```bash
git_bash_manager install .git_alias
```

### Manual Instalation
1. Download Archive

Download the zip archive from:
```bash
https://github.com/sergio-rodrigues/.git_alias/archive/refs/heads/main.zip 
```

2. Unzip the archive

The archive contains a `.git_alias-main` folder that should be renamed `.git_alias`

If you are using [.gitbash](https://github.com/sergio-rodrigues/.git_bash), just 
unzip the archive to :
```
C:\Users\<Username>\.git_bash
```
and it will be automatically executed at shell startup.


if you are not using *.gitbash* then you need to add the following to one shell startup script file like `.bash_profile`:
```bash
LOCATION=<LOCATION_OF_THE_EXTRACTED_FILES>

if [ -f "${LOCATION}/.git_alias/git_alias.sh" ]; then
    alias git="${LOCATION}/.git_alias/git_alias.sh"
fi
```

3. Navigate to the project directory:

   ```
   cd <project_directory>
   ```

4. Ensure the `.env` file is present and contains the required environment variables.

5. Review and update the configuration file (`config_file`) with SSH settings.

6. Run the script:

   ```
   ./git_alias.sh
   ```

7. Follow the on-screen information to configure SSH settings based on network conditions.

## Configuration Examples

- Example `.env` file:

  ```
  CONFIG_FILE=/path/to/config_file
  PROXY_CMD="/mingw64/bin/connect -H proxy.example.com:3128 %h %p"

  PROFILE_DIR="${HOME}/.git_bash/.git_alias/profiles"
  BACKUP_DIR="${HOME}/.git_bash/.git_alias/.backup"
  ```

- Example `config_file`:

  ```
  # SSH Configuration Examples

  # No proxy configuration
  192.168.1.1|

  # Proxy configuration
  10.0.0.1|proxy.example.com:3128
  ```
```
