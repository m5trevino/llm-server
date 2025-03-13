#!/usr/bin/env python3
import os
import argparse
import subprocess
import sys

def main():
    parser = argparse.ArgumentParser(description="Run LLM API Server")
    parser.add_argument("--model", type=str, choices=["deepseek", "codellama"],
                        default="deepseek", help="Model to use")
    parser.add_argument("--port", type=int, default=8000, help="Port to run the server on")
    parser.add_argument("--quantize", type=str, choices=["4bit", "8bit", "none"],
                        default="4bit", help="Quantization level")

    args = parser.parse_args()

    # Set environment variables
    os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"
    os.environ["MODEL_QUANTIZE"] = args.quantize

    # Run the appropriate model file
    if args.model == "deepseek":
        subprocess.run([sys.executable, "deepseek.py", "--port", str(args.port)])
    elif args.model == "codellama":
        subprocess.run([sys.executable, "codellama.py", "--port", str(args.port)])

if __name__ == "__main__":
    main()