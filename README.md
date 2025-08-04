# 1Password Kitten for Kitty Terminal

A seamless Kitty terminal kitten that integrates with 1Password CLI for secure password retrieval with fuzzy search and smart context detection.

## Features

- **Zero Configuration**: No shell configuration required - works out of the box
- **Fuzzy Search**: Interactive fuzzy search using `fzf` with real-time filtering
- **Biometric Support**: Touch ID/Windows Hello integration via 1Password app
- **Smart Search**: Search across all your 1Password items with fuzzy matching
- **Secure**: No passwords stored locally, uses 1Password CLI exclusively
- **Fast**: Direct integration with terminal for instant password pasting

## Requirements

- Kitty terminal emulator
- 1Password CLI (`op`) installed and configured
- Python 3.8+ (uses only standard library modules)
- `fzf` (optional but recommended for better UX)

> **Note**: This kitten uses only Python standard library modules, so no additional packages need to be installed!

## Installation

### Quick Install (Recommended)

```bash
# Clone or download this repository
git clone https://github.com/yourusername/kitty-kitten-1password.git
cd kitty-kitten-1password

# Run the install script
./install.sh
```

The install script will:
- Check for Python 3 and other dependencies
- Install 1Password CLI if needed (macOS with Homebrew)
- Copy the kitten to your Kitty config directory  
- Configure key mappings in your `kitty.conf`
- Test the installation

### Recommended: Set up 1Password App Integration

For seamless biometric authentication, set up the 1Password app integration:

1. Open the 1Password app
2. Go to **Settings > Security** and enable Touch ID/Windows Hello/system authentication
3. Go to **Developer > Settings** and select **"Integrate with 1Password CLI"**

Once configured, the kitten will automatically prompt for biometric authentication (Touch ID, Windows Hello, etc.) when you use it, eliminating the need to enter your master password.

📖 **Documentation**: [1Password CLI App Integration](https://developer.1password.com/docs/cli/app-integration/)

### Manual Installation

1. **Install 1Password CLI:**
   ```bash
   # macOS
   brew install 1password-cli
   
   # Or download from https://1password.com/downloads/command-line/
   ```

2. **Install fzf (optional but recommended):**
   ```bash
   # macOS
   brew install fzf
   
   # Ubuntu/Debian
   sudo apt install fzf
   ```

3. **Copy the kitten to your Kitty config directory:**
   ```bash
   cp onepassword_kitten.py ~/.config/kitty/
   chmod +x ~/.config/kitty/onepassword_kitten.py
   ```

4. **Add key mappings to your `~/.config/kitty/kitty.conf`:**
   ```conf
   # Enable remote control for context detection
   allow_remote_control yes
   
   # Primary hotkey - smart context detection
   map ctrl+alt+p kitten onepassword_kitten.py
   
   # Search for specific items
   map ctrl+alt+s kitten onepassword_kitten.py ssh
   map ctrl+alt+g kitten onepassword_kitten.py git
   map ctrl+alt+d kitten onepassword_kitten.py database
   ```

## Usage

### Basic Usage

1. When you encounter a password prompt, press `Ctrl+Alt+P`
2. A fuzzy search interface opens with all your 1Password items
3. Start typing to filter items in real-time
4. Use arrow keys to navigate, Enter to select
5. Password is automatically pasted into the terminal

### Interactive Search

The kitten provides an interactive fuzzy search interface where you can:

```bash
# Example: Searching for AWS credentials
$ aws configure
AWS Secret Access Key [None]: [press Ctrl+Alt+P]
# Type "aws" in the search box to filter AWS-related items

# Example: SSH connection
$ ssh user@myserver.com  
Password: [press Ctrl+Alt+P]
# Type "myserver" or "ssh" to quickly find the right credential

# Example: Database connection
$ mysql -h db.example.com -u admin -p
Password: [press Ctrl+Alt+P] 
# Type "database" or "mysql" to find database credentials
```

### Manual Search

Pass search terms as arguments:

```conf
# Search for SSH-related items
map ctrl+alt+s kitten onepassword_kitten.py ssh

# Search for work-related items  
map ctrl+alt+w kitten onepassword_kitten.py work

# Search for specific service
map ctrl+alt+a kitten onepassword_kitten.py aws
```

### Fuzzy Search Interface

When `fzf` is installed, you get an interactive fuzzy search:
- Type to filter items in real-time
- Use arrow keys to navigate
- Press Enter to select
- Press Escape to cancel

Without `fzf`, falls back to a numbered list interface.

## How It Works

1. **Standard Library Only**: Uses only Python standard library modules - no dependencies to install
2. **Biometric Authentication**: Integrates with 1Password app for Touch ID/Windows Hello
3. **Real-time Search**: Loads all 1Password items and provides interactive fuzzy search
4. **Smart Authentication**: Tries biometric unlock first, falls back to manual signin
5. **Fuzzy Matching**: Searches item titles, tags, and categories in real-time
6. **Secure Pasting**: Retrieves password and pastes directly into terminal

## Authentication Flow

1. **Automatic Authentication**: When invoked, the 1Password CLI automatically handles authentication
2. **Biometric First**: If app integration is configured, automatically prompts for Touch ID/Windows Hello
3. **Master Password Fallback**: If biometric authentication is unavailable or fails, prompts for master password
4. **Fresh Sessions**: Authenticates fresh each time for maximum security

## Troubleshooting

1. **Check 1Password CLI installation:**
   ```bash
   op whoami
   ```

2. **Test the kitten manually:**
   ```bash
   kitty +kitten onepassword_kitten.py
   ```

3. **Enable Kitty remote control (if context detection isn't working):**
   Add to `~/.config/kitty/kitty.conf`:
   ```conf
   allow_remote_control yes
   ```

4. **Check file permissions:**
   ```bash
   ls -la ~/.config/kitty/onepassword_kitten.py  # Should be executable
   ```

5. **Set up biometric authentication:**
   Follow the [1Password CLI App Integration guide](https://developer.1password.com/docs/cli/app-integration/) to enable automatic Touch ID/Windows Hello authentication

## Security Notes

- **No Local Storage**: Passwords are never stored locally - retrieved fresh each time
- **No Session Caching**: Authenticates fresh each time for maximum security
- **CLI Integration**: Uses official 1Password CLI exclusively
- **Biometric Security**: Leverages your device's secure biometric authentication
- **Memory Safe**: No sensitive data persisted to disk

## Comparison with Shell-Based Solutions

Unlike solutions requiring shell configuration, this kitten:
- ✅ Works immediately without modifying shell configs
- ✅ No need to source additional files
- ✅ Works across different shells (bash, zsh, fish)
- ✅ Interactive fuzzy search with real-time filtering
- ✅ Biometric authentication support
- ✅ Zero dependencies (Python standard library only)