#!/usr/bin/env python3

import subprocess
import sys
import os
import re
import json
import tempfile
from pathlib import Path
from typing import Optional, List, Dict

# Import kitty modules only when running as a kitten
try:
    from kitty.boss import Boss
    RUNNING_AS_KITTEN = True
except ImportError:
    # Running standalone (e.g., for testing)
    Boss = None
    RUNNING_AS_KITTEN = False

# fzf binary path - will be set during installation
FZF_BINARY_PATH = None

def has_fzf() -> bool:
    """Check if fzf is available for fuzzy search"""
    result = subprocess.run(["which", "fzf"], capture_output=True)
    return result.returncode == 0


def authenticate() -> Optional[str]:
    """Authenticate with 1Password and return session token"""
    # Try to authenticate
    try:
        # First try biometric unlock if available
        result = subprocess.run(["op", "signin", "--raw"], 
                              capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            session_token = result.stdout.strip()
            # If we got a session token, return it
            if session_token:
                return session_token
            else:
                # App integration mode - no token returned, but authentication succeeded
                return "APP_INTEGRATION"  # Special marker for app integration
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError):
        pass
    
    # Fallback to interactive signin
    try:
        print("Please authenticate with 1Password...")
        # Run interactive signin with --raw, allow stdin but capture stdout
        result = subprocess.run(["op", "signin", "--raw"], 
                              stdout=subprocess.PIPE, 
                              text=True)
        if result.returncode == 0:
            session_token = result.stdout.strip()
            if session_token:
                return session_token
            else:
                return "APP_INTEGRATION"
    except Exception:
        pass
    
    return None

def get_1password_items(session_token: str, query: str = "") -> List[Dict]:
    """Get items from 1Password with session token"""
    try:
        # Build command based on whether we have app integration or session token
        if session_token == "APP_INTEGRATION":
            cmd = ["op", "item", "list", "--format=json"]
        else:
            cmd = ["op", "item", "list", "--format=json", "--session", session_token]
        
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        
        if result.returncode != 0:
            return []
        
        items = json.loads(result.stdout)
        
        # Filter by query if provided
        if query:
            query_lower = query.lower()
            filtered_items = []
            for item in items:
                title = item.get("title", "").lower()
                tags = " ".join(item.get("tags", [])).lower()
                category = item.get("category", "").lower()
                
                if (query_lower in title or 
                    query_lower in tags or 
                    query_lower in category):
                    filtered_items.append(item)
            return filtered_items
        
        return items
    except (json.JSONDecodeError, Exception):
        return []

def get_password_from_1password(session_token: str, item_id: str) -> Optional[str]:
    """Retrieve password from 1Password for a specific item"""
    try:
        # Build command based on whether we have app integration or session token
        if session_token == "APP_INTEGRATION":
            cmd = ["op", "item", "get", item_id, "--fields=password"]
        else:
            cmd = ["op", "item", "get", item_id, "--fields=password", "--session", session_token]
        
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None

def fuzzy_select_item(items: List[Dict]) -> Optional[Dict]:
    """Use fzf for fuzzy selection of items"""
    if not items:
        return None
    
    return fuzzy_select_with_fzf(items)

def fuzzy_select_with_fzf(items: List[Dict]) -> Optional[Dict]:
    """Use fzf for interactive fuzzy selection"""
    # Prepare items for fzf
    fzf_input = []
    for i, item in enumerate(items):
        title = item.get("title", "Untitled")
        category = item.get("category", "Unknown")
        url = item.get("urls", [{}])[0].get("href", "") if item.get("urls") else ""
        
        display_line = f"{title} ({category})"
        if url:
            display_line += f" - {url}"
        
        fzf_input.append(f"{i}:{display_line}")
    
    try:
        # Determine fzf command
        fzf_cmd = FZF_BINARY_PATH if FZF_BINARY_PATH else "fzf"
        
        # Use subprocess.Popen to control stdin/stdout/stderr separately
        fzf_process = subprocess.Popen(
            [fzf_cmd, "--prompt=Select 1Password item: ", "--height=40%", "--reverse"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=None,  # Let stderr go to terminal
            text=True
        )
        
        stdout, _ = fzf_process.communicate("\n".join(fzf_input))
        
        if fzf_process.returncode == 0 and stdout.strip():
            # Extract index from fzf output
            selected_line = stdout.strip()
            index = int(selected_line.split(":", 1)[0])
            return items[index]
    except (subprocess.CalledProcessError, ValueError, IndexError):
        pass
    
    return None

def select_with_numbered_list(items: List[Dict]) -> Optional[Dict]:
    """Fallback selection using numbered list"""
    print("\n1Password Items:")
    print("-" * 60)
    
    for i, item in enumerate(items):
        title = item.get("title", "Untitled")
        category = item.get("category", "Unknown")
        url = item.get("urls", [{}])[0].get("href", "") if item.get("urls") else ""
        
        display_line = f"{i + 1:2d}. {title} ({category})"
        if url:
            display_line += f"\n    {url}"
        
        print(display_line)
    
    print(f"\nEnter item number (1-{len(items)}) or 0 to cancel:")
    
    try:
        choice = int(input().strip())
        if choice == 0:
            return None
        if 1 <= choice <= len(items):
            return items[choice - 1]
    except (ValueError, KeyboardInterrupt):
        pass
    
    return None

def detect_context_from_screen() -> str:
    """Try to detect context from terminal screen content"""
    try:
        # Try to get current window content using kitty remote control
        result = subprocess.run(
            ["kitty", "@", "get-text", "--extent=screen"],
            capture_output=True, text=True, timeout=2
        )
        
        if result.returncode == 0:
            screen_text = result.stdout.strip()
            return analyze_screen_content(screen_text)
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
        pass
    
    return ""

def analyze_screen_content(screen_text: str) -> str:
    """Analyze screen content to detect context for password search"""
    if not screen_text:
        return ""
    
    lines = screen_text.lower().split('\n')
    recent_lines = lines[-10:]  # Look at last 10 lines
    
    # SSH connection patterns
    ssh_patterns = [
        r'ssh\s+([^@\s]+@)?([^@\s]+)',
        r'connecting to ([^@\s]+)',
        r'password for [^@\s]*@?([^@\s:]+)',
        r'([^@\s]+).*password[:\s]*$'
    ]
    
    for line in recent_lines:
        for pattern in ssh_patterns:
            match = re.search(pattern, line)
            if match:
                # Extract hostname/server name
                hostname = match.group(1) if match.lastindex and match.lastindex >= 1 else ""
                hostname = hostname.replace("@", "").strip()
                if hostname and len(hostname) > 2:
                    return hostname
    
    # Database connection patterns
    db_patterns = [
        r'mysql.*-h\s+([^\s]+)',
        r'psql.*-h\s+([^\s]+)',
        r'connecting to database.*([^\s]+)',
    ]
    
    for line in recent_lines:
        for pattern in db_patterns:
            match = re.search(pattern, line)
            if match and match.group(1):
                return f"database {match.group(1)}"
    
    # Sudo/system authentication
    if any('sudo' in line for line in recent_lines):
        return "sudo"
    
    # Git operations
    if any(re.search(r'git (push|pull|clone)', line) for line in recent_lines):
        return "git"
    
    return ""

def main(args: List[str]) -> str:
    """Main entry point for the kitten"""
    # Authenticate
    session_token = authenticate()
    if not session_token:
        return "ERROR: Authentication failed"
    
    # Get all items from 1Password (no initial filtering)
    items = get_1password_items(session_token)
    
    if not items:
        return "ERROR: No items found in 1Password"
    
    # Let user select an item with fzf (user can type to filter)
    selected_item = fuzzy_select_item(items)
    if not selected_item:
        return "CANCELLED"
    
    # Get the password
    password = get_password_from_1password(session_token, selected_item["id"])
    if password:
        return password
    else:
        return "ERROR: Could not retrieve password"

def handle_result(args: List[str], answer: str, target_window_id: int, boss: Boss) -> None:
    """Handle the result from main() and paste it into the terminal"""
    if answer.startswith("ERROR:") or answer == "CANCELLED":
        # Don't paste errors, just show them
        print(f"\n{answer}")
    else:
        # Paste the password
        w = boss.window_id_map.get(target_window_id)
        if w is not None:
            w.paste_text(answer)