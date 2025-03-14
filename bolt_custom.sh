#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Customizing bolt.diy...${NC}"

REPO_DIR=$(pwd)
BOLT_DIR="/root/bolt.diy"
PROVIDERS_DIR="${BOLT_DIR}/app/lib/modules/llm/providers"
REGISTRY_PATH="${BOLT_DIR}/app/lib/modules/llm/registry.ts"

# Create providers directory if it doesn't exist
if [ ! -d "${PROVIDERS_DIR}" ]; then
    echo -e "${YELLOW}Creating providers directory...${NC}"
    mkdir -p "${PROVIDERS_DIR}"
fi

# Create codellama-local.ts
echo -e "${YELLOW}Creating codellama-local.ts...${NC}"
cat > "${PROVIDERS_DIR}/codellama-local.ts" << 'EOF'
import { BaseProvider, getOpenAILikeModel } from '../base-provider';
import type { ModelInfo } from '../types';
import type { IProviderSetting } from '~/types/model';
import type { LanguageModelV1 } from 'ai';
import { logger } from '~/utils/logger';

export default class CodeLlamaLocalProvider extends BaseProvider {
  name = 'CodeLlamaLocal';
  displayName = 'CodeLlama Local';
  getApiKeyLink = 'http://localhost:8000';
  labelForGetApiKey = 'Local Server';
  icon = 'i-carbon-machine-learning-model';
  requiresApiKey = false;
  config = {
    baseUrlKey: 'CODELLAMA_LOCAL_API_BASE_URL',
    apiTokenKey: 'CODELLAMA_LOCAL_API_KEY',
    baseUrl: 'http://localhost:8000/v1'
  };
  staticModels: ModelInfo[] = [
    { 
      name: 'codellama-7b-instruct', 
      label: 'CodeLlama 7B (Local)', 
      provider: 'CodeLlamaLocal', 
      maxTokenAllowed: 8192,
      contextWindow: 8192,
      pricing: { prompt: 0, completion: 0 }
    }
  ];
  getModelInstance(options: {
    model: string;
    serverEnv?: Record<string, string>;
    apiKeys?: Record<string, string>;
    providerSettings?: Record<string, IProviderSetting>;
  }): LanguageModelV1 {
    const { model } = options;
  
    const { baseUrl, apiKey } = this.getProviderBaseUrlAndKey({
      apiKeys: options.apiKeys,
      providerSettings: options.providerSettings?.[this.name],
      serverEnv: options.serverEnv,
      defaultBaseUrlKey: this.config.baseUrlKey,
      defaultApiTokenKey: this.config.apiTokenKey
    });
    const finalBaseUrl = baseUrl || this.config.baseUrl;
    const finalApiKey = apiKey || 'sk-1234567890';
  
    logger.debug('CodeLlama Local Provider:', { baseUrl: finalBaseUrl, model });
    return getOpenAILikeModel(finalBaseUrl, finalApiKey, model);
  }
}
EOF
echo -e "${GREEN}codellama-local.ts created${NC}"

# Create deepseek-local.ts
echo -e "${YELLOW}Creating deepseek-local.ts...${NC}"
cat > "${PROVIDERS_DIR}/deepseek-local.ts" << 'EOF'
import { BaseProvider, getOpenAILikeModel } from '../base-provider';
import type { ModelInfo } from '../types';
import type { IProviderSetting } from '~/types/model';
import type { LanguageModelV1 } from 'ai';
import { logger } from '~/utils/logger';

export default class DeepseekLocalProvider extends BaseProvider {
  name = 'DeepseekLocal';
  displayName = 'Deepseek Local';
  getApiKeyLink = 'http://localhost:8000';
  labelForGetApiKey = 'Local Server';
  icon = 'i-carbon-machine-learning-model';
  requiresApiKey = false;
  config = {
    baseUrlKey: 'DEEPSEEK_LOCAL_API_BASE_URL',
    apiTokenKey: 'DEEPSEEK_LOCAL_API_KEY',
    baseUrl: 'http://localhost:8000/v1'
  };
  staticModels: ModelInfo[] = [
    { 
      name: 'deepseek-coder-6.7b-instruct', 
      label: 'DeepSeek Coder 6.7B (Local)', 
      provider: 'DeepseekLocal', 
      maxTokenAllowed: 8192,
      contextWindow: 8192,
      pricing: { prompt: 0, completion: 0 }
    }
  ];
  getModelInstance(options: {
    model: string;
    serverEnv?: Record<string, string>;
    apiKeys?: Record<string, string>;
    providerSettings?: Record<string, IProviderSetting>;
  }): LanguageModelV1 {
    const { model } = options;
  
    const { baseUrl, apiKey } = this.getProviderBaseUrlAndKey({
      apiKeys: options.apiKeys,
      providerSettings: options.providerSettings?.[this.name],
      serverEnv: options.serverEnv,
      defaultBaseUrlKey: this.config.baseUrlKey,
      defaultApiTokenKey: this.config.apiTokenKey
    });
    const finalBaseUrl = baseUrl || this.config.baseUrl;
    const finalApiKey = apiKey || 'sk-1234567890';
  
    logger.debug('Deepseek Local Provider:', { baseUrl: finalBaseUrl, model });
    return getOpenAILikeModel(finalBaseUrl, finalApiKey, model);
  }
}
EOF
echo -e "${GREEN}deepseek-local.ts created${NC}"

# Create .env.local
echo -e "${YELLOW}Creating .env.local...${NC}"
cat > "${BOLT_DIR}/.env.local" << 'EOF'
# Core Configuration for Local LLMs
DEEPSEEK_LOCAL_API_BASE_URL=http://localhost:8000/v1
CODELLAMA_LOCAL_API_BASE_URL=http://localhost:8000/v1
OPENAI_LIKE_API_BASE_URL=http://localhost:8000/v1
OPENAI_LIKE_API_KEY=sk-dummy-key
OPENAI_LIKE_STREAM=false

# Debug Settings
VITE_LOG_LEVEL=debug

# Model Context Window
DEFAULT_NUM_CTX=4096

# Everything below is commented out as it's not needed for local setup
# GROQ_API_KEY=
# OPENAI_API_KEY=
# ANTHROPIC_API_KEY=
# OPEN_ROUTER_API_KEY=
# GOOGLE_GENERATIVE_AI_API_KEY=
# OLLAMA_API_BASE_URL=
# TOGETHER_API_BASE_URL=
# DEEPSEEK_API_KEY=
# TOGETHER_API_KEY=
# HYPERBOLIC_API_KEY=
# HYPERBOLIC_API_BASE_URL=
# MISTRAL_API_KEY=
# COHERE_API_KEY=
# LMSTUDIO_API_BASE_URL=
# XAI_API_KEY=
# PERPLEXITY_API_KEY=
# AWS_BEDROCK_CONFIG=
EOF
echo -e "${GREEN}.env.local created${NC}"

# Create vite.config.ts
echo -e "${YELLOW}Creating vite.config.ts...${NC}"
cat > "${BOLT_DIR}/vite.config.ts" << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { fileURLToPath, URL } from 'node:url';
import UnoCSS from 'unocss/vite';
import { presetUno, presetIcons, presetWebFonts } from 'unocss';
import { visualizer } from 'rollup-plugin-visualizer';
import { VitePWA } from 'vite-plugin-pwa';
import { nodePolyfills } from 'vite-plugin-node-polyfills';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    react(),
    UnoCSS({
      presets: [
        presetUno(),
        presetIcons({
          scale: 1.2,
          extraProperties: {
            display: 'inline-block',
            'vertical-align': 'middle',
          },
        }),
        presetWebFonts({
          provider: 'google',
          fonts: {
            sans: ['Inter:400,500,600,700,800,900', 'Inter'],
            mono: ['Fira Code', 'Fira Mono:400,700'],
          },
        }),
      ],
    }),
    visualizer(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.ico', 'apple-touch-icon.png', 'mask-icon.svg'],
      manifest: {
        name: 'bolt.diy',
        short_name: 'bolt.diy',
        theme_color: '#ffffff',
        icons: [
          {
            src: 'pwa-64x64.png',
            sizes: '64x64',
            type: 'image/png',
          },
          {
            src: 'pwa-192x192.png',
            sizes: '192x192',
            type: 'image/png',
          },
          {
            src: 'pwa-512x512.png',
            sizes: '512x512',
            type: 'image/png',
          },
        ],
      },
    }),
    nodePolyfills(),
  ],
  resolve: {
    alias: {
      '~': fileURLToPath(new URL('./app', import.meta.url)),
    },
  },
  server: {
    host: process.env.BOLT_HOST || '0.0.0.0',
    port: parseInt(process.env.BOLT_PORT || '5173'),
  },
});
EOF
echo -e "${GREEN}vite.config.ts created${NC}"

# Update registry.ts to include local providers
echo -e "${YELLOW}Updating registry.ts...${NC}"
# First, backup the original registry.ts
cp "${REGISTRY_PATH}" "${REGISTRY_PATH}.bak"

# Create updated registry.ts with local providers
cat > "${REGISTRY_PATH}" << 'EOF'
import AnthropicProvider from './providers/anthropic';
import CohereProvider from './providers/cohere';
import DeepseekProvider from './providers/deepseek';
import DeepseekLocalProvider from './providers/deepseek-local';
import GoogleProvider from './providers/google';
import GroqProvider from './providers/groq';
import HuggingFaceProvider from './providers/huggingface';
import LMStudioProvider from './providers/lmstudio';
import MistralProvider from './providers/mistral';
import OllamaProvider from './providers/ollama';
import OpenRouterProvider from './providers/open-router';
import OpenAILikeProvider from './providers/openai-like';
import OpenAIProvider from './providers/openai';
import PerplexityProvider from './providers/perplexity';
import TogetherProvider from './providers/together';
import XAIProvider from './providers/xai';
import HyperbolicProvider from './providers/hyperbolic';
import AmazonBedrockProvider from './providers/amazon-bedrock';
import GithubProvider from './providers/github';
import CodeLlamaLocalProvider from './providers/codellama-local';

export {
  AnthropicProvider,
  CohereProvider,
  DeepseekProvider,
  DeepseekLocalProvider,
  GoogleProvider,
  GroqProvider,
  HuggingFaceProvider,
  HyperbolicProvider,
  MistralProvider,
  OllamaProvider,
  OpenAIProvider,
  OpenRouterProvider,
  OpenAILikeProvider,
  PerplexityProvider,
  XAIProvider,
  TogetherProvider,
  LMStudioProvider,
  AmazonBedrockProvider,
  GithubProvider,
  CodeLlamaLocalProvider,
};
EOF
echo -e "${GREEN}registry.ts updated${NC}"

echo -e "${GREEN}bolt.diy customization completed!${NC}"