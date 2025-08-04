# 1Password Kitten for Kitty Terminal

Provides integration with 1Password biometrics to allow you to inject passwords from 1Password into the terminal anywhere.

## Requirements

- Kitty terminal emulator
- 1Password CLI (`op`) installed and configured
- Python 3.8+ (uses only standard library modules)
- `fzf`

## Installation

Since this is a pretty sensitive concept, I suggest you read the [installer](https://github.com/mm-zacharydavison/kitty-kitten-1password/blob/main/install.sh) and [kitten code](https://github.com/mm-zacharydavison/kitty-kitten-1password/blob/main/onepassword_kitten.py) yourself before installing.

### Quick Install (Recommended)

```bash
# Clone or download this repository
curl -s https://raw.githubusercontent.com/mm-zacharydavison/kitty-kitten-1password/refs/heads/main/install.sh | bash
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

# Thanks

Thanks to https://github.com/dnanhkhoa/kitty-password-manager for the inspiration (A BitWarden based solution).