#!/usr/bin/env python3
import os
import json
from pathlib import Path
import argparse
import getpass
import subprocess
import time
import sys

# ANSI color codes for cyberpunk theme
CYAN = '\033[0;36m'
GREEN = '\033[0;32m'
PURPLE = '\033[0;35m'
YELLOW = '\033[1;33m'
RED = '\033[0;31m'
BOLD = '\033[1m'
NC = '\033[0m'  # No Color

def print_header(text):
    """Print a styled header"""
    print(f"\n{PURPLE}{BOLD}[+] {text} {NC}\n")

def print_step(text):
    """Print a styled step"""
    print(f"{CYAN}[*] {text}{NC}")

def print_success(text):
    """Print a styled success message"""
    print(f"{GREEN}[✓] {text}{NC}")

def print_error(text):
    """Print a styled error message"""
    print(f"{RED}[✗] {text}{NC}")

def print_info(text):
    """Print a styled info message"""
    print(f"{YELLOW}[i] {text}{NC}")

def progress_bar(iteration, total, prefix='', length=50, fill='█'):
    """Display a progress bar"""
    percent = ("{0:.1f}").format(100 * (iteration / float(total)))
    filled_length = int(length * iteration // total)
    bar = f"{CYAN}{fill}{NC}" * filled_length + '░' * (length - filled_length)
    sys.stdout.write(f'\r{prefix} |{bar}| {percent}%')
    sys.stdout.flush()
    if iteration == total:
        print()

class RunPodConfigManager:
    def __init__(self):
        # Define paths for RunPod environment
        self.root_dir = Path('/root')
        self.root_env_path = self.root_dir / '.env'
        self.bolt_dir = self.root_dir / 'bolt.diy'
        self.bolt_env_path = self.bolt_dir / '.env.local'
        self.tokens_store_path = self.root_dir / '.tokens.json'
        
        # Mandatory configurations for running the LLM server
        self.mandatory_configs = {
            'HUGGINGFACE_API_KEY': '',
            'NGROK_AUTH_TOKEN': '',
            'MODEL_NAME': 'deepseek-ai/deepseek-coder-6.7b-instruct',
            'DEFAULT_NUM_CTX': '6144',
            'DEFAULT_MAX_TOKENS': '2000',
            'DEFAULT_TEMPERATURE': '0.7',
            'DEFAULT_TOP_P': '0.95',
            'CUDA_VISIBLE_DEVICES': '0',
            'TRANSFORMERS_CACHE': '/root/.cache/huggingface',
            'HF_HOME': '/root/.cache/huggingface',
            'TMPDIR': '/dev/shm',
            'FASTAPI_HOST': '0.0.0.0',
            'FASTAPI_PORT': '8000',
        }
        
        # Optional API keys for bolt.diy
        self.optional_api_keys = {
            'OPENAI_API_KEY': '',
            'ANTHROPIC_API_KEY': '',
            'GROQ_API_KEY': '',
            'OPEN_ROUTER_API_KEY': '',
            'GOOGLE_GENERATIVE_AI_API_KEY': '',
            'TOGETHER_API_KEY': '',
            'MISTRAL_API_KEY': '',
            'COHERE_API_KEY': '',
            'PERPLEXITY_API_KEY': '',
        }
        
        # Load any previously stored tokens
        self.stored_tokens = self.load_stored_tokens()

    def load_stored_tokens(self):
        """Load previously stored API tokens"""
        if self.tokens_store_path.exists():
            try:
                with open(self.tokens_store_path, 'r') as f:
                    return json.load(f)
            except json.JSONDecodeError:
                print_error(f"Could not parse {self.tokens_store_path}. Creating a new file.")
                return {}
        return {}

    def save_stored_tokens(self):
        """Save API tokens for future use"""
        with open(self.tokens_store_path, 'w') as f:
            json.dump(self.stored_tokens, f, indent=2)
        # Set secure permissions
        os.chmod(self.tokens_store_path, 0o600)

    def get_user_input(self, key, is_mandatory=False, is_secret=True):
        """Get user input for a configuration value"""
        # Check if we have a stored token
        if key in self.stored_tokens:
            use_stored = input(f"{YELLOW}Found stored {key}. Use it? (y/n): {NC}").lower()
            if use_stored == 'y':
                print_success(f"Using stored {key}")
                return self.stored_tokens[key]
        
        # Prompt for the value
        prompt = f"Enter {key}"
        if is_mandatory:
            prompt += f" {RED}(required){NC}"
        prompt += f": {CYAN}"
        
        # Get the input (hide if it's a secret)
        if is_secret:
            value = getpass.getpass(prompt)
        else:
            value = input(prompt + NC)
        
        # Validate mandatory fields
        if is_mandatory and not value:
            print_error(f"{key} is required.")
            return self.get_user_input(key, is_mandatory, is_secret)
        
        # Ask to store the token
        if value and (key.endswith('_API_KEY') or key.endswith('_AUTH_TOKEN')):
            store = input(f"{YELLOW}Store {key} for future use? (y/n): {NC}").lower()
            if store == 'y':
                self.stored_tokens[key] = value
                self.save_stored_tokens()
                print_success(f"Stored {key} for future use")
        
        return value

    def setup_mandatory_configs(self):
        """Set up mandatory configurations"""
        print_header("MANDATORY CONFIGURATIONS")
        
        # First handle API keys
        for key in ['HUGGINGFACE_API_KEY', 'NGROK_AUTH_TOKEN']:
            value = self.get_user_input(key, is_mandatory=True, is_secret=True)
            if value:
                self.mandatory_configs[key] = value
                print_success(f"{key} configured")
        
        # Then handle model configuration with defaults
        print_header("MODEL CONFIGURATION")
        print_info("Press Enter to accept default values or enter a new value.")
        
        for i, key in enumerate(['MODEL_NAME', 'DEFAULT_NUM_CTX', 'DEFAULT_MAX_TOKENS', 
                   'DEFAULT_TEMPERATURE', 'DEFAULT_TOP_P']):
            default = self.mandatory_configs[key]
            value = input(f"{CYAN}{key} [{default}]: {NC}")
            if value:
                self.mandatory_configs[key] = value
            progress_bar(i+1, 5, prefix='Configuration progress')
            time.sleep(0.2)  # For visual effect
        
        # Write configurations to root .env
        self.write_root_env()

    def setup_optional_configs(self):
        """Set up optional API keys"""
        print_header("OPTIONAL API KEYS")
        configure = input(f"{YELLOW}Would you like to configure optional API keys for bolt.diy? (y/n): {NC}").lower()
        
        if configure != 'y':
            return
        
        print_info("\nSelect which API keys to configure:")
        print_info("(Enter the number, or multiple numbers separated by spaces, or 'all' for all keys)")
        
        # Display options
        for i, key in enumerate(self.optional_api_keys.keys(), 1):
            print(f"{CYAN}{i}. {key}{NC}")
        
        # Get selection
        selection = input(f"\n{YELLOW}Enter selection (or 'all'): {NC}").strip()
        
        if selection.lower() == 'all':
            keys_to_configure = list(self.optional_api_keys.keys())
        else:
            try:
                indices = [int(idx) - 1 for idx in selection.split()]
                keys_to_configure = [list(self.optional_api_keys.keys())[i] for i in indices if 0 <= i < len(self.optional_api_keys)]
            except ValueError:
                print_error("Invalid selection. Skipping optional configuration.")
                return
        
        # Configure selected keys
        for i, key in enumerate(keys_to_configure):
            value = self.get_user_input(key, is_mandatory=False, is_secret=True)
            if value:
                self.optional_api_keys[key] = value
            progress_bar(i+1, len(keys_to_configure), prefix='API key configuration')
            time.sleep(0.2)  # For visual effect
        
        # Write to bolt.diy .env.local
        self.write_bolt_env()

    def write_root_env(self):
        """Write mandatory configurations to root .env file"""
        # Create parent directory if it doesn't exist
        self.root_env_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(self.root_env_path, 'w') as f:
            f.write("# Mandatory Configurations for LLM API Server\n")
            f.write("# Generated by RunPod Configure Script\n\n")
            
            for key, value in self.mandatory_configs.items():
                f.write(f"{key}={value}\n")
        
        # Set secure permissions
        os.chmod(self.root_env_path, 0o600)
        print_success(f"Wrote configurations to {self.root_env_path}")

    def write_bolt_env(self):
        """Write optional API keys to bolt.diy .env.local file"""
        # Create parent directory if it doesn't exist
        self.bolt_env_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Read existing file if it exists
        existing_content = {}
        if self.bolt_env_path.exists():
            with open(self.bolt_env_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        existing_content[key] = value
        
        with open(self.bolt_env_path, 'w') as f:
            f.write("# API Keys for bolt.diy\n")
            f.write("# Generated by RunPod Configure Script\n\n")
            
            # Write API keys
            for key, value in self.optional_api_keys.items():
                if value:
                    f.write(f"{key}={value}\n")
                else:
                    f.write(f"#{key}=\n")
            
            # Write existing content that we didn't overwrite
            for key, value in existing_content.items():
                if key not in self.optional_api_keys:
                    f.write(f"{key}={value}\n")
            
            # Write local API URLs
            f.write("\n# Local API URLs\n")
            f.write("DEEPSEEK_LOCAL_API_BASE_URL=http://localhost:8000/v1\n")
            f.write("CODELLAMA_LOCAL_API_BASE_URL=http://localhost:8000/v1\n")
        
        # Set secure permissions
        os.chmod(self.bolt_env_path, 0o600)
        print_success(f"Wrote API keys to {self.bolt_env_path}")

    def check_bolt_diy(self):
        """Check if bolt.diy is installed and offer to clone it if not"""
        if not self.bolt_dir.exists():
            print_header("BOLT.DIY INSTALLATION")
            clone = input(f"{YELLOW}Would you like to clone bolt.diy repository? (y/n): {NC}").lower()
            
            if clone == 'y':
                print_step("Cloning bolt.diy repository...")
                try:
                    subprocess.run(
                        ["git", "clone", "-b", "stable", "https://github.com/stackblitz-labs/bolt.diy", str(self.bolt_dir)],
                        check=True
                    )
                    print_success("bolt.diy cloned successfully!")
                    
                    # Install dependencies
                    print_step("Installing bolt.diy dependencies...")
                    os.chdir(str(self.bolt_dir))
                    subprocess.run(["pnpm", "install"], check=True)
                    print_success("Dependencies installed successfully!")
                    
                    return True
                except subprocess.CalledProcessError as e:
                    print_error(f"Error cloning bolt.diy: {e}")
                    return False
            else:
                print_info("Please clone bolt.diy manually before running setup.sh")
                return False
        return True

    def run(self):
        """Run the configuration process"""
        # ASCII Art Banner
        print(f"{PURPLE}")
        print("""
 _____              ______          _    _____             __ _       
|  __ \            |  ____|        | |  / ____|           / _(_)      
| |__) |   _ _ __  | |__   _ __ ___| | | |     ___  _ __ | |_ _  __ _ 
|  _  / | | | '_ \ |  __| | '_ \_  / | | |    / _ \| '_ \|  _| |/ _` |
| | \ \ |_| | | | || |____| | | / /| | | |___| (_) | | | | | | | (_| |
|_|  \_\__,_|_| |_||______|_| |_/___|_|  \_____\___/|_| |_|_| |_|\__, |
                                                                   __/ |
                                                                  |___/ 
        """)
        print(f"{NC}")
        print(f"{CYAN}{BOLD}RunPod LLM Server Configuration{NC}")
        print(f"{YELLOW}This script will help you configure your LLM API server and bolt.diy integration.{NC}")
        
        # Check if bolt.diy is installed
        bolt_ready = self.check_bolt_diy()
        
        # Setup mandatory configurations
        self.setup_mandatory_configs()
        
        # Setup optional configurations if bolt.diy is ready
        if bolt_ready:
            self.setup_optional_configs()
        
        print_header("CONFIGURATION COMPLETE")
        print_success(f"Root config: {self.root_env_path}")
        if bolt_ready:
            print_success(f"bolt.diy config: {self.bolt_env_path}")
        print_info("\nNext steps:")
        print(f"{CYAN}1. Run setup.sh to complete the installation{NC}")
        print(f"{CYAN}2. Start the API server with ./start-api.sh deepseek{NC}")
        if bolt_ready:
            print(f"{CYAN}3. Start bolt.diy with ./start-bolt.sh{NC}")

def main():
    parser = argparse.ArgumentParser(description="Configure LLM API Server for RunPod")
    parser.add_argument("--reset", action="store_true", help="Reset all configurations")
    args = parser.parse_args()
    
    config_manager = RunPodConfigManager()
    
    if args.reset:
        # Remove configuration files
        if config_manager.root_env_path.exists():
            os.remove(config_manager.root_env_path)
        if config_manager.bolt_env_path.exists():
            os.remove(config_manager.bolt_env_path)
        if config_manager.tokens_store_path.exists():
            os.remove(config_manager.tokens_store_path)