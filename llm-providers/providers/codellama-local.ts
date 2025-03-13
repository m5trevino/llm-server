import { BaseProvider } from '~/lib/modules/llm/base-provider';
import type { ModelInfo } from '~/lib/modules/llm/types';
import type { IProviderSetting } from '~/types/model';
import type { LanguageModelV1 } from 'ai';
import { createOpenAI } from '@ai-sdk/openai';

export default class CodeLlamaLocalProvider extends BaseProvider {
  name = 'CodeLlamaLocal';
  getApiKeyLink = undefined;

  config = {
    baseUrlKey: 'CODELLAMA_LOCAL_API_BASE_URL',
  };

  staticModels: ModelInfo[] = [
    { 
      name: 'codellama-7b-instruct', 
      label: 'CodeLlama 7B (Local)', 
      provider: 'CodeLlamaLocal', 
      maxTokenAllowed: 8192 
    }
  ];

  getModelInstance(options: {
    model: string;
    serverEnv: Env;
    apiKeys?: Record<string, string>;
    providerSettings?: Record<string, IProviderSetting>;
  }): LanguageModelV1 {
    const { model, serverEnv, apiKeys, providerSettings } = options;

    const { baseUrl } = this.getProviderBaseUrlAndKey({
      apiKeys,
      providerSettings: providerSettings?.[this.name],
      serverEnv: serverEnv as any,
      defaultBaseUrlKey: 'CODELLAMA_LOCAL_API_BASE_URL',
      defaultApiTokenKey: '',
    });

    if (!baseUrl) {
      throw new Error(`Missing base URL for ${this.name} provider`);
    }

    const openai = createOpenAI({
      baseURL: baseUrl,
      apiKey: 'not-needed',
    });

    return openai(model);
  }
}