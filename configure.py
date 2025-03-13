#!/usr/bin/env python3
import os
import json
from pathlib import Path
import argparse
import getpass
import subprocess

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
                print(f"Warning: Could not parse {self.tokens_store_path}. Creating a new file.")
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
            use_stored = input(f"Found stored {key}. Use it? (y/n): ").lower()
            if use_stored == 'y':
                return self.stored_tokens[key]

        # Prompt for the value
        prompt = f"Enter {key}"
        if is_mandatory:
            prompt += " (required)"
        prompt += ": "

        # Get the input (hide if it's a secret)
        if is_secret:
            value = getpass.getpass(prompt)
        else:
            value = input(prompt)

        # Validate mandatory fields
        if is_mandatory and not value:
            print(f"Error: {key} is required.")
            return self.get_user_input(key, is_mandatory, is_secret)

        # Ask to store the token
        if value and (key.endswith('_API_KEY') or key.endswith('_AUTH_TOKEN')):
            store = input(f"Store {key} for future use? (y/n): ").lower()
            if store == 'y':
                self.stored_tokens[key] = value
                self.save_stored_tokens()

        return value

    def setup_mandatory_configs(self):
        """Set up mandatory configurations"""
        print("\n=== Setting up mandatory configurations ===")

        # First handle API keys
        for key in ['HUGGINGFACE_API_KEY', 'NGROK_AUTH_TOKEN']:
            value = self.get_user_input(key, is_mandatory=True, is_secret=True)
            if value:
                self.mandatory_configs[key] = value

        # Then handle model configuration with defaults
        print("\n=== Model Configuration ===")
        print("Press Enter to accept default values or enter a new value.")

        for key in ['MODEL_NAME', 'DEFAULT_NUM_CTX', 'DEFAULT_MAX_TOKENS',
                   'DEFAULT_TEMPERATURE', 'DEFAULT_TOP_P']:
            default = self.mandatory_configs[key]
            value = input(f"{key} [{default}]: ")
            if value:
                self.mandatory_configs[key] = value

        # Write configurations to root .env
        self.write_root_env()

    def setup_optional_configs(self):
        """Set up optional API keys"""
        print("\n=== Optional API Keys Configuration ===")
        configure = input("Would you like to configure optional API keys for bolt.diy? (y/n): ").lower()

        if configure != 'y':
            return

        print("\nSelect which API keys to configure:")
        print("(Enter the number, or multiple numbers separated by spaces, or 'all' for all keys)")

        # Display options
        for i, key in enumerate(self.optional_api_keys.keys(), 1):
            print(f"{i}. {key}")

        # Get selection
        selection = input("\nEnter selection (or 'all'): ").strip()

        if selection.lower() == 'all':
            keys_to_configure = list(self.optional_api_keys.keys())
        else:
            try:
                indices = [int(idx) - 1 for idx in selection.split()]
                keys_to_configure = [list(self.optional_api_keys.keys())[i] for i in indices if 0 <= i < len(self.optional_api_keys)]
            except ValueError:
                print("Invalid selection. Skipping optional configuration.")
                return

        # Configure selected keys
        for key in keys_to_configure:
            value = self.get_user_input(key, is_mandatory=False, is_secret=True)
            if value:
                self.optional_api_keys[key] = value

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
        print(f"Wrote configurations to {self.root_env_path}")

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
        print(f"Wrote API keys to {self.bolt_env_path}")

    def check_bolt_diy(self):
        """Check if bolt.diy is installed and offer to clone it if not"""
        if not self.bolt_dir.exists():
            print("\n=== bolt.diy not found ===")
            clone = input("Would you like to clone bolt.diy repository? (y/n): ").lower()

            if clone == 'y':
                print("Cloning bolt.diy repository...")
                try:
                    subprocess.run(
                        ["git", "clone", "https://github.com/stackblitz/bolt.diy.git", str(self.bolt_dir)],
                        check=True
                    )
                    print("bolt.diy cloned successfully!")

                    # Install dependencies
                    print("Installing bolt.diy dependencies...")
                    os.chdir(str(self.bolt_dir))
                    subprocess.run(["npm", "install"], check=True)
                    print("Dependencies installed successfully!")

                    return True
                except subprocess.CalledProcessError as e:
                    print(f"Error cloning bolt.diy: {e}")
                    return False
            else:
                print("Please clone bolt.diy manually before running setup.sh")
                return False
        return True

    def run(self):
        """Run the configuration process"""
        print("=== RunPod LLM Server Configuration ===")
        print("This script will help you configure your LLM API server and bolt.diy integration.")

        # Check if bolt.diy is installed
        bolt_ready = self.check_bolt_diy()

        # Setup mandatory configurations
        self.setup_mandatory_configs()

        # Setup optional configurations if bolt.diy is ready
        if bolt_ready:
            self.setup_optional_configs()

        print("\n=== Configuration Complete ===")
        print(f"Root config: {self.root_env_path}")
        if bolt_ready:
            print(f"bolt.diy config: {self.bolt_env_path}")
        print("\nNext steps:")
        print("1. Run setup.sh to complete the installation")
        print("2. Start the API server with ./start-api.sh deepseek")
        if bolt_ready:
            print("3. Start bolt.diy with ./start-bolt.sh")

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
        print("All configurations have been reset.")

    config_manager.run()

if __name__ == "__main__":
    main()