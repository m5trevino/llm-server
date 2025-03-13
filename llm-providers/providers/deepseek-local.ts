import { BaseProvider } from '~/lib/modules/llm/base-provider';
import type { ModelInfo } from '~/lib/modules/llm/types';
import type { IProviderSetting } from '~/types/model';
import type { LanguageModelV1 } from 'ai';
import { createOpenAI } from '@ai-sdk/openai';

export default class DeepseekLocalProvider extends BaseProvider {
  name = 'DeepseekLocal';
  getApiKeyLink = undefined;

  config = {
    baseUrlKey: 'DEEPSEEK_LOCAL_API_BASE_URL',
  };

  staticModels: ModelInfo[] = [
    { 
      name: 'deepseek-coder-6.7b-instruct', 
      label: 'DeepSeek Coder 6.7B (Local)', 
      provider: 'DeepseekLocal', 
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
      defaultBaseUrlKey: 'DEEPSEEK_LOCAL_API_BASE_URL',
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