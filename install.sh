#!/bin/bash

# 1Password Kitten Installation Script
# This script installs the 1Password kitten for Kitty terminal

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

print_header() {
    echo
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}    1Password Kitten for Kitty Terminal${NC}"
    echo -e "${BLUE}===============================================${NC}"
    echo
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if we're on a supported platform
check_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        PLATFORM="linux"
    else
        print_error "Unsupported platform: $OSTYPE"
        exit 1
    fi
    print_info "Detected platform: $PLATFORM"
}

# Check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    local missing_deps=()
    
    # Check for kitty
    if ! command_exists kitty; then
        print_error "Kitty terminal not found"
        missing_deps+=("kitty")
    else
        # Check kitty version and remote control support
        if kitty --version >/dev/null 2>&1; then
            print_success "Kitty terminal found ($(kitty --version))"
        else
            print_warning "Kitty found but version check failed"
        fi
    fi
    
    # Check for Python 3
    if ! command_exists python3; then
        print_error "Python 3 not found"
        missing_deps+=("python3")
    else
        python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        print_success "Python 3 found (version $python_version)"
        
        # Check if required Python modules are available (all standard library)
        if ! python3 -c "import subprocess, json, pathlib, re, os, sys, tempfile" 2>/dev/null; then
            print_error "Required Python standard library modules not available"
            missing_deps+=("python3-complete")
        fi
    fi
    
    # Check for 1Password CLI (required)
    if ! command_exists op; then
        print_warning "1Password CLI not found. Attempting to install..."
        if ! install_1password_cli; then
            missing_deps+=("1password-cli")
        fi
    else
        op_version=$(op --version 2>/dev/null || echo "unknown")
        print_success "1Password CLI found (version $op_version)"
        
        # Test 1Password CLI basic functionality
        if ! op --help >/dev/null 2>&1; then
            print_warning "1Password CLI installation may be corrupted"
        fi
    fi
    
    # Check for fzf (optional but recommended) and store path
    FZF_PATH=""
    if command_exists fzf; then
        FZF_PATH=$(command -v fzf)
        fzf_version=$(fzf --version 2>/dev/null | cut -d' ' -f1 || echo "unknown")
        print_success "fzf found at $FZF_PATH (version $fzf_version) - fuzzy search enabled"
    else
        print_warning "fzf not found (optional but recommended for better UX)"
        print_info "Install fzf for fuzzy search interface:"
        if [[ "$PLATFORM" == "macos" ]]; then
            echo "  ${YELLOW}brew install fzf${NC}"
        else
            echo "  ${YELLOW}sudo apt install fzf${NC} (Ubuntu/Debian)"
            echo "  ${YELLOW}sudo dnf install fzf${NC} (Fedora)"
            echo "  ${YELLOW}sudo pacman -S fzf${NC} (Arch)"
        fi
    fi
    
    # Exit if we have missing required dependencies
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo
        print_info "Installation instructions:"
        
        for dep in "${missing_deps[@]}"; do
            case $dep in
                kitty)
                    if [[ "$PLATFORM" == "macos" ]]; then
                        echo "  Kitty: ${YELLOW}brew install kitty${NC}"
                    else
                        echo "  Kitty: Visit https://sw.kovidgoyal.net/kitty/binary/"
                    fi
                    ;;
                python3)
                    if [[ "$PLATFORM" == "macos" ]]; then
                        echo "  Python 3: ${YELLOW}brew install python3${NC}"
                    else
                        echo "  Python 3: ${YELLOW}sudo apt install python3${NC} (Ubuntu)"
                    fi
                    ;;
                python3-complete)
                    echo "  Complete Python 3: May need to reinstall Python or check your installation"
                    ;;
                1password-cli)
                    echo "  1Password CLI: Visit https://1password.com/downloads/command-line/"
                    ;;
            esac
        done
        echo
        exit 1
    fi
}


# Install 1Password CLI
install_1password_cli() {
    if [[ "$PLATFORM" == "macos" ]]; then
        if command_exists brew; then
            print_info "Installing 1Password CLI via Homebrew..."
            if brew install 1password-cli >/dev/null 2>&1; then
                print_success "1Password CLI installed successfully"
                return 0
            else
                print_error "Failed to install 1Password CLI via Homebrew"
                return 1
            fi
        else
            print_error "Homebrew not found. Cannot auto-install 1Password CLI."
            print_info "Please install manually: https://1password.com/downloads/command-line/"
            return 1
        fi
    else
        print_warning "Auto-installation not supported on $PLATFORM"
        print_info "Please install manually: https://1password.com/downloads/command-line/"
        return 1
    fi
}

# Create Kitty config directory
ensure_kitty_config_dir() {
    KITTY_CONFIG_DIR="$HOME/.config/kitty"
    if [[ ! -d "$KITTY_CONFIG_DIR" ]]; then
        print_info "Creating Kitty config directory..."
        mkdir -p "$KITTY_CONFIG_DIR"
        print_success "Created $KITTY_CONFIG_DIR"
    fi
}

# Install the kitten
install_kitten() {
    print_info "Installing 1Password kitten..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    KITTEN_SOURCE="$SCRIPT_DIR/onepassword_kitten.py"
    KITTEN_DEST="$KITTY_CONFIG_DIR/onepassword_kitten.py"
    
    # Check if we're running from a local directory or need to download
    if [[ ! -f "$KITTEN_SOURCE" ]]; then
        print_info "onepassword_kitten.py not found locally, downloading from GitHub..."
        
        # Download the Python file from GitHub
        GITHUB_RAW_URL="https://raw.githubusercontent.com/mm-zacharydavison/kitty-kitten-1password/refs/heads/main/onepassword_kitten.py"
        
        if command_exists curl; then
            if curl -sL "$GITHUB_RAW_URL" -o "$KITTEN_DEST"; then
                print_success "Downloaded onepassword_kitten.py from GitHub"
            else
                print_error "Failed to download onepassword_kitten.py from GitHub"
                exit 1
            fi
        elif command_exists wget; then
            if wget -q "$GITHUB_RAW_URL" -O "$KITTEN_DEST"; then
                print_success "Downloaded onepassword_kitten.py from GitHub"
            else
                print_error "Failed to download onepassword_kitten.py from GitHub"
                exit 1
            fi
        else
            print_error "Neither curl nor wget found. Cannot download kitten file."
            print_info "Please install curl or wget, or download the repository manually."
            exit 1
        fi
        
        # Set the source to the downloaded file for fzf path configuration
        KITTEN_SOURCE="$KITTEN_DEST"
    else
        # Copy the kitten from local directory
        cp "$KITTEN_SOURCE" "$KITTEN_DEST"
    fi
    
    # Update the fzf path in the Python script
    if [[ -n "$FZF_PATH" ]]; then
        print_info "Configuring fzf path: $FZF_PATH"
        # Replace the FZF_BINARY_PATH placeholder with the actual path
        sed -i.bak "s|FZF_BINARY_PATH = None|FZF_BINARY_PATH = \"$FZF_PATH\"|" "$KITTEN_DEST"
        rm -f "$KITTEN_DEST.bak"
    else
        print_info "No fzf found, kitten will use fallback method"
        sed -i.bak "s|FZF_BINARY_PATH = None|FZF_BINARY_PATH = None|" "$KITTEN_DEST"
        rm -f "$KITTEN_DEST.bak"
    fi
    
    chmod +x "$KITTEN_DEST"
    print_success "Kitten installed to $KITTEN_DEST"
}

# Configure Kitty
configure_kitty() {
    KITTY_CONF="$KITTY_CONFIG_DIR/kitty.conf"
    
    print_info "Configuring Kitty..."
    
    # Check if config file exists
    if [[ ! -f "$KITTY_CONF" ]]; then
        print_info "Creating new kitty.conf..."
        touch "$KITTY_CONF"
    fi
    
    # Check if our config is already present
    if grep -q "onepassword_kitten.py" "$KITTY_CONF" 2>/dev/null; then
        print_warning "1Password kitten configuration already exists in kitty.conf"
        echo "You may want to review the configuration manually."
        return
    fi
    
    # Add configuration
    print_info "Adding 1Password kitten configuration to kitty.conf..."
    cat >> "$KITTY_CONF" << EOF

# 1Password Kitten Configuration
# Primary hotkey - fuzzy search through all 1Password items
map ctrl+alt+p kitten onepassword_kitten.py
EOF
    
    print_success "Configuration added to kitty.conf"
}

# Test installation
test_installation() {
    print_info "Testing installation..."
    local test_failed=false
    
    # Test if the kitten file exists and is executable
    if [[ -f "$KITTEN_DEST" && -x "$KITTEN_DEST" ]]; then
        print_success "Kitten file installed and executable"
    else
        print_error "Kitten file missing or not executable"
        test_failed=true
    fi
    
    # Test if the kitten can be imported and run
    if python3 -c "
import sys
sys.path.insert(0, '$KITTY_CONFIG_DIR')
try:
    import onepassword_kitten
    print('Kitten imports successfully')
except Exception as e:
    print(f'Import failed: {e}')
    exit(1)
" 2>/dev/null; then
        print_success "Kitten imports and loads successfully"
    else
        print_warning "Kitten import test failed"
        test_failed=true
    fi
    
    # Test 1Password CLI
    if command_exists op && op --version >/dev/null 2>&1; then
        print_success "1Password CLI working"
    else
        print_warning "1Password CLI test failed - you may need to sign in later"
    fi
    
    
    # Test fzf availability
    if command_exists fzf; then
        print_success "fzf available - fuzzy search enabled"
    else
        print_info "fzf not available - will use numbered selection"
    fi
    
    if [[ "$test_failed" == true ]]; then
        print_warning "Some tests failed - installation may not work correctly"
        return 1
    fi
    
    return 0
}

# Show post-installation instructions
show_instructions() {
    echo
    print_success "Installation complete!"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. ${YELLOW}[RECOMMENDED]${NC} Set up 1Password app integration for seamless biometric authentication:"
    echo "   • Open the 1Password app"
    echo "   • Go to Settings > Security and enable Touch ID/Windows Hello/system authentication"
    echo "   • Go to Developer > Settings and select 'Integrate with 1Password CLI'"
    echo "   • Once configured, the kitten will automatically use biometrics when you invoke it"
    echo -e "   • Documentation: ${YELLOW}https://developer.1password.com/docs/cli/app-integration/${NC}"
    echo
    echo "2. Restart Kitty terminal"
    echo
    echo -e "3. Test the kitten by pressing ${YELLOW}Ctrl+Alt+P${NC} in any terminal session"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo -e "• ${YELLOW}Ctrl+Alt+P${NC} - Open fuzzy search for all 1Password items"
    echo "• Start typing to filter items in real-time"
    echo "• Use arrow keys to navigate, Enter to select, Escape to cancel"
    echo
    echo -e "${BLUE}For more information:${NC}"
    echo "• View README.md for detailed usage instructions"
    echo "• Configure additional hotkeys in ~/.config/kitty/kitty.conf"
    echo
}

# Main installation flow
main() {
    print_header
    
    check_platform
    check_dependencies
    ensure_kitty_config_dir
    install_kitten
    configure_kitty
    test_installation
    show_instructions
}

# Handle interruption
trap 'print_error "Installation interrupted"; exit 1' INT

# Run main function
main "$@"