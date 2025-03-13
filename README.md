# Local LLM Providers for bolt.diy

This repository contains API servers and provider files for running local LLMs with bolt.diy on RunPod:
- DeepSeek Coder 6.7B
- CodeLlama 7B

## Overview

This project allows you to run powerful local LLMs directly on your RunPod instance and integrate them with bolt.diy, providing a familiar chat interface with your local models.

### Features

- FastAPI servers for DeepSeek Coder and CodeLlama models
- OpenAI-compatible API endpoints
- Provider files for bolt.diy integration
- Easy setup scripts for RunPod environments
- Configuration management for API keys and environment variables

## Quick Setup on RunPod

1. Clone this repository:
```bash
git clone https://github.com/m5trevino/llm-server.git
cd llm-server