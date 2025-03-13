from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel
from typing import List, Optional, Union, Dict
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch
from datetime import datetime
import logging
import uuid
import json
import os

# Add memory optimization settings
os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Switch to DeepSeek Coder - excellent for coding tasks
MODEL_NAME = os.getenv("MODEL_NAME", "deepseek-ai/deepseek-coder-6.7b-instruct")
DEFAULT_MAX_TOKENS = int(os.getenv("DEFAULT_MAX_TOKENS", 1024))
DEFAULT_TEMPERATURE = float(os.getenv("DEFAULT_TEMPERATURE", 0.2))  # Lower temp for coding
DEFAULT_TOP_P = float(os.getenv("DEFAULT_TOP_P", 0.95))

class ChatMessage(BaseModel):
    role: str
    content: str

class Usage(BaseModel):
    prompt_tokens: Optional[int]
    completion_tokens: Optional[int]
    total_tokens: Optional[int]

class ChatCompletionRequest(BaseModel):
    model: str
    messages: List[ChatMessage]
    temperature: float = DEFAULT_TEMPERATURE
    top_p: float = DEFAULT_TOP_P
    max_tokens: int = DEFAULT_MAX_TOKENS
    stream: bool = False

class ChatCompletionResponseChoice(BaseModel):
    index: int
    message: ChatMessage
    finish_reason: str

class ChatCompletionResponse(BaseModel):
    id: str = str(uuid.uuid4())
    object: str = "chat.completion"
    created: int = int(datetime.now().timestamp())
    model: str
    choices: List[ChatCompletionResponseChoice]
    usage: Optional[Usage] = None

# Load the model
try:
    # Clear CUDA memory before loading
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        torch.cuda.reset_peak_memory_stats()
        torch.cuda.synchronize()

    logger.info(f"Loading model {MODEL_NAME}...")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, trust_remote_code=True)
    model = AutoModelForCausalLM.from_pretrained(
        MODEL_NAME,
        load_in_4bit=True,  # 4-bit quantization for max speed
        bnb_4bit_compute_dtype=torch.float16,  # Use float16 for computation
        device_map="auto",
        trust_remote_code=True
    )
    logger.info(f"Model {MODEL_NAME} loaded successfully")
except Exception as e:
    logger.error(f"Error loading model: {e}")
    raise

def format_prompt(messages: List[ChatMessage]) -> str:
    """Format the conversation for DeepSeek Coder."""
    system_content = "You are an AI programming assistant, utilizing the DeepSeek Coder model to generate code and provide coding assistance."
    conversation = ""

    # Get system message if it exists
    for msg in messages:
        if msg.role == "system":
            system_content = msg.content
            break

    # Format the conversation
    conversation += f"<｜begin▁of▁conversation｜>\n"
    conversation += f"<｜system｜>\n{system_content}\n"

    for msg in messages:
        if msg.role == "user":
            conversation += f"<｜user｜>\n{msg.content}\n"
        elif msg.role == "assistant":
            conversation += f"<｜assistant｜>\n{msg.content}\n"

    # Add the final assistant prompt
    if messages[-1].role == "user":
        conversation += "<｜assistant｜>\n"

    logger.info(f"Formatted prompt: {conversation}")
    return conversation

def get_token_count(text: str) -> int:
    try:
        return len(tokenizer.encode(text))
    except Exception as e:
        logger.error(f"Error counting tokens: {e}")
        return 0

@app.get("/")
async def root():
    return {"message": "DeepSeek Coder API is running", "model": MODEL_NAME}

@app.get("/api/health")
async def health_check():
    return {"status": "ok", "model": MODEL_NAME}

@app.options("/v1/chat/completions")
async def options_chat_completions():
    return JSONResponse(content={})

# Echo endpoint for testing
@app.post("/echo")
async def echo(request: Request):
    data = await request.json()
    logger.info(f"Echo endpoint received: {json.dumps(data)}")
    return JSONResponse(content={"echo": data})

@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    try:
        # Log the raw request for debugging
        raw_request = await request.body()
        logger.info(f"Raw request: {raw_request.decode()}")

        request_data = await request.json()
        is_streaming = request_data.get("stream", False)

        # Parse the request properly
        request_obj = ChatCompletionRequest(**request_data)
        prompt = format_prompt(request_obj.messages)
        prompt_tokens = get_token_count(prompt)

        logger.info(f"Processing request with {len(request_obj.messages)} messages")

        inputs = tokenizer(prompt, return_tensors="pt", return_token_type_ids=False).to(model.device)

        generation_config = {
            "max_new_tokens": request_obj.max_tokens,
            "do_sample": request_obj.temperature > 0,
            "pad_token_id": tokenizer.eos_token_id,
        }

        if request_obj.temperature > 0:
            generation_config.update({
                "temperature": request_obj.temperature,
                "top_p": request_obj.top_p,
            })

        logger.info(f"Generating with config: {generation_config}")

        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                **generation_config
            )

        response_text = tokenizer.decode(outputs[0][inputs['input_ids'].shape[1]:], skip_special_tokens=True)
        completion_tokens = get_token_count(response_text)

        logger.info(f"Generated response with {completion_tokens} tokens")
        logger.info(f"Response text: {response_text}")

        usage = {
            "prompt_tokens": prompt_tokens,
            "completion_tokens": completion_tokens,
            "total_tokens": prompt_tokens + completion_tokens
        }

        # Create the response in OpenAI format
        response = {
            "id": f"chatcmpl-{str(uuid.uuid4())[:8]}",
            "object": "chat.completion",
            "created": int(datetime.now().timestamp()),
            "model": request_obj.model,
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": response_text.strip()
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": usage
        }

        # Log the full response for debugging
        logger.info(f"Sending response: {json.dumps(response)}")

        if is_streaming:
            logger.info("Streaming response requested")

            async def generate():
                # Format for streaming responses
                chunk = {
                    "id": response["id"],
                    "object": "chat.completion.chunk",
                    "created": response["created"],
                    "model": response["model"],
                    "choices": [
                        {
                            "index": 0,
                            "delta": {
                                "role": "assistant",
                                "content": response["choices"][0]["message"]["content"]
                            },
                            "finish_reason": "stop"
                        }
                    ]
                }
                yield f"data: {json.dumps(chunk)}\n\n"
                yield "data: [DONE]\n\n"

            return StreamingResponse(
                generate(),
                media_type="text/event-stream",
                headers={
                    "Cache-Control": "no-cache",
                    "Connection": "keep-alive",
                }
            )

        return JSONResponse(content=response)

    except Exception as e:
        logger.error(f"Error in chat completions: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    # Start the FastAPI server
    import uvicorn
    logger.info("Starting DeepSeek Coder API on http://localhost:8000")
    logger.info("Make sure bolt.diy is configured to use http://localhost:8000/v1")
    uvicorn.run(app, host="0.0.0.0", port=8000)