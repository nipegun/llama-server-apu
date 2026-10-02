#!/usr/bin/env -S PYTHONDONTWRITEBYTECODE=1 python3

"""Generate the bundled OpenAPI inventory from the registered server routes."""

import json
import re
import sys
from pathlib import Path

cRoot = Path(__file__).resolve().parents[2]
dDescriptions = {
  'health': 'Read server health. Returns 503 while a model is loading; no API key is required.',
  'metrics': 'Read Prometheus metrics, including TTFT and queue timings. Requires --metrics.',
  'props': 'Read model capabilities, chat template, defaults and router state. POST changes permitted global properties and requires --props.',
  'models': 'List available models; requires the API key when one is configured. In router mode POST downloads a model from Hugging Face and DELETE cancels a download or removes a downloaded model.',
  'models/load': 'Load a model in router mode. The model field identifies a configured model.',
  'models/unload': 'Unload a model in router mode and release its inference resources.',
  'models/sse': 'Subscribe to model status and loading progress as server-sent events in router mode.',
  'completions': 'Generate text from a native prompt. Supports streaming, sampling parameters, cache reuse and timing data. The v1 variant uses the OpenAI request/response convention.',
  'chat/completions': 'Generate an assistant response from role/content messages. Supports tools, multimodal input, reasoning, sampling parameters and SSE streaming.',
  'chat/completions/control': 'Control an active chat completion, including skipping reasoning. Requires an active request.',
  'responses': 'Generate a response using the OpenAI Responses-compatible input format. Supports tools and streaming.',
  'audio/transcriptions': 'Transcribe audio using an audio-capable model. Upload the audio file using multipart/form-data.',
  'messages': 'Generate a response using Anthropic-compatible messages. Accepts X-Api-Key or Bearer authentication.',
  'messages/count_tokens': 'Count tokens for an Anthropic-compatible messages request without generating a response.',
  'infill': 'Generate a fill-in-the-middle completion from an input prefix and suffix.',
  'embeddings': 'Compute embedding vectors. Requires an embedding-capable model and embedding mode. The v1 variant uses the OpenAI-compatible input format.',
  'rerank': 'Rank documents by relevance to a query using a reranking-capable model.',
  'reranking': 'Alias for document reranking.',
  'tokenize': 'Convert content to token IDs using the loaded tokenizer; add_special and with_pieces control the result.',
  'detokenize': 'Convert token IDs back into text using the loaded tokenizer.',
  'apply-template': 'Apply the model chat template to role/content messages without generating tokens.',
  'chat/completions/input_tokens': 'Tokenize a chat-completions request after applying the model template.',
  'responses/input_tokens': 'Tokenize a Responses request after applying the model template.',
  'lora-adapters': 'GET lists LoRA adapters; POST changes their scaling factors.',
  'slots': 'Read inference slot state. Requires --slots.',
  'slots/{id_slot}': 'Save, restore or erase a slot prompt cache. Specify action in the query and filename for save/restore. Requires configured slot persistence.',
  'stream': 'GET resumes a buffered generation stream; DELETE cancels its producer and removes the replay session. conv_id identifies the conversation and from the byte offset.',
  'streams/lookup': 'Find currently active replay sessions for the supplied conversation_ids.',
  'cors-proxy': 'Proxy an explicitly configured MCP HTTP request. Requires the CORS proxy feature to be enabled; otherwise returns 403.',
  'tools': 'GET lists available built-in and configured MCP tools; POST executes one. Requires enabled server tools or MCP servers; otherwise returns 403.'
}

def fSchema(pName):
  return {'$ref': '#/components/schemas/' + pName}

def fOperation(pMethod, pPath):
  vName = pPath.lstrip('/').removeprefix('v1/')
  dOperation = {
    'operationId': pMethod + ''.join(vPart.title() for vPart in re.split(r'[^a-zA-Z0-9]+', pPath)),
    'summary': pMethod.upper() + ' /api' + pPath,
    'description': dDescriptions.get(vName, 'Server operation; see the request schema and source handler.'),
    'tags': ['Router' if vName.startswith('models/') else 'Inference'],
    'responses': {
      '200': {'description': 'Successful response.', 'content': {'application/json': {'schema': {'type': 'object', 'additionalProperties': True}}}},
      '400': {'description': 'Invalid parameters or incompatible model.', 'content': {'application/json': {'schema': fSchema('Error')}}},
      '401': {'description': 'Missing or invalid API key.', 'content': {'application/json': {'schema': fSchema('Error')}}},
      '403': {'description': 'Feature disabled or operation forbidden.'},
      '404': {'description': 'Model, slot or resource not found.'},
      '500': {'description': 'Server error.'},
      '503': {'description': 'Model loading or server unavailable.'}
    }
  }
  if pMethod == 'get' and vName in ['health']:
    dOperation['security'] = []
  if pMethod == 'post':
    vSchema = 'Request'
    if vName in ['chat/completions', 'chat/completions/input_tokens', 'apply-template', 'messages', 'messages/count_tokens']:
      vSchema = 'ChatRequest'
    elif vName in ['tokenize', 'detokenize']:
      vSchema = 'TokenRequest'
    elif vName.startswith('models/'):
      vSchema = 'ModelRequest'
    elif vName == 'streams/lookup':
      vSchema = 'StreamLookup'
    dOperation['requestBody'] = {'required': True, 'content': {'application/json': {'schema': fSchema(vSchema)}}}
    if vName == 'audio/transcriptions':
      dOperation['requestBody']['content'] = {'multipart/form-data': {'schema': {'type': 'object', 'required': ['file'], 'properties': {
        'file': {'type': 'string', 'format': 'binary'}, 'model': {'type': 'string'}, 'language': {'type': 'string'}, 'prompt': {'type': 'string'}, 'response_format': {'type': 'string'}
      }}}}
  if vName in ['chat/completions', 'completions', 'responses', 'messages', 'stream', 'models/sse']:
    dOperation['responses']['200']['content']['text/event-stream'] = {'schema': {'type': 'string'}, 'example': 'data: {"choices":[]}\n\ndata: [DONE]\n\n'}
  if vName == 'metrics':
    dOperation['responses']['200']['content'] = {'text/plain': {'schema': {'type': 'string'}}}
  if vName == 'tools':
    if pMethod == 'get':
      dOperation['responses']['200']['content']['application/json']['schema'] = {'type': 'array', 'items': {'type': 'object', 'additionalProperties': True}}
    else:
      dOperation['requestBody']['content']['application/json']['schema'] = {'type': 'object', 'required': ['tool'], 'properties': {'tool': {'type': 'string'}, 'params': {'type': 'object', 'additionalProperties': True}, 'stream': {'type': 'boolean', 'default': False}}}
      dOperation['parameters'] = [{'name': 'x-tool-cwd', 'in': 'header', 'required': False, 'schema': {'type': 'string'}, 'description': 'Working directory override for tools that accept it.'}]
      dOperation['responses']['200']['content']['text/event-stream'] = {'schema': {'type': 'string'}, 'description': 'Streaming tool output followed by an event with done=true.'}
  if vName == 'cors-proxy':
    dOperation['parameters'] = [{'name': 'url', 'in': 'query', 'required': True, 'schema': {'type': 'string', 'format': 'uri'}, 'description': 'HTTP(S) MCP target. Userinfo authentication in the target URL is rejected.'}]
    if pMethod == 'post':
      dOperation['requestBody'] = {'required': False, 'content': {'application/json': {'schema': {'type': 'object', 'additionalProperties': True}}}}
  if vName == 'stream':
    dOperation['parameters'] = [
      {'name': 'conv_id', 'in': 'query', 'required': True, 'schema': {'type': 'string'}},
      {'name': 'from', 'in': 'query', 'required': False, 'schema': {'type': 'integer', 'minimum': 0}}
    ]
  if '{id_slot}' in pPath:
    dOperation['parameters'] = [
      {'name': 'id_slot', 'in': 'path', 'required': True, 'schema': {'type': 'integer', 'minimum': 0}},
      {'name': 'action', 'in': 'query', 'required': True, 'schema': {'type': 'string', 'enum': ['save', 'restore', 'erase']}}
    ]
  if vName == 'props' and pMethod == 'get':
    dOperation['parameters'] = [
      {'name': 'model', 'in': 'query', 'schema': {'type': 'string'}},
      {'name': 'autoload', 'in': 'query', 'schema': {'type': 'boolean', 'default': False}}
    ]
  return dOperation

def fMain():
  vSource = (cRoot / 'backend/tools/server/server.cpp').read_text()
  dPaths = {}
  for vMethod, vPath in re.findall(r'ctx_http\.(get|post|del)\s*\("([^"]+)"', vSource):
    vMethod = 'delete' if vMethod == 'del' else vMethod
    vPath = vPath.replace(':id_slot', '{id_slot}')
    dPaths.setdefault(vPath, {})[vMethod] = fOperation(vMethod, vPath)
  for vPath, vMime in [('/doc/', 'text/html'), ('/doc/openapi.json', 'application/json'), ('/doc/swagger-ui.css', 'text/css'), ('/doc/swagger-ui-bundle.js', 'application/javascript')]:
    dPaths[vPath] = {'get': {'summary': 'Bundled API documentation asset', 'security': [], 'responses': {'200': {'description': 'Documentation available without an API key, including during startup.', 'content': {vMime: {'schema': {'type': 'string'}}}}}}}
  dPaths['/doc'] = {'get': {'summary': 'Redirect to /api/doc/', 'security': [], 'responses': {'301': {'description': 'Permanent redirect to /api/doc/.'}}}}
  dPaths['/predict'] = {'post': {
    'summary': 'Google Cloud prediction compatibility (only in GCP mode)',
    'description': 'Default prediction suffix. AIP_PREDICT_ROUTE can select a different suffix under /api. Each instance carries @requestFormat (a handler suffix or its camelCase alias). Streaming is disabled for these batched calls.',
    'requestBody': {'required': True, 'content': {'application/json': {'schema': {'type': 'object', 'required': ['instances'], 'properties': {'instances': {'type': 'array', 'items': {'type': 'object', 'required': ['@requestFormat'], 'properties': {'@requestFormat': {'type': 'string'}}, 'additionalProperties': True}}}}}}},
    'responses': {'200': {'description': 'Batch results.', 'content': {'application/json': {'schema': {'type': 'object', 'properties': {'predictions': {'type': 'array', 'items': {}}}}}}}, '400': {'description': 'Invalid instances or request format.'}, '401': {'description': 'Invalid API key.'}, '503': {'description': 'Model loading.'}}
  }}
  dSchemas = {
    'Error': {'type': 'object', 'properties': {'error': {'type': 'object', 'properties': {'message': {'type': 'string'}, 'type': {'type': 'string'}, 'code': {'type': 'integer'}}}}},
    'Request': {'type': 'object', 'additionalProperties': True, 'properties': {
      'model': {'type': 'string'}, 'prompt': {}, 'input': {}, 'stream': {'type': 'boolean', 'default': False},
      'temperature': {'type': 'number'}, 'top_p': {'type': 'number'}, 'top_k': {'type': 'integer'},
      'max_tokens': {'type': 'integer'}, 'n_predict': {'type': 'integer'}, 'seed': {'type': 'integer'},
      'query': {'type': 'string'}, 'documents': {'type': 'array', 'items': {'type': 'string'}},
      'input_prefix': {'type': 'string'}, 'input_suffix': {'type': 'string'}, 'filename': {'type': 'string'},
      'tools': {'type': 'array', 'items': {'type': 'object', 'additionalProperties': True}},
      'tool_choice': {}, 'response_format': {'type': 'object', 'additionalProperties': True}
    }},
    'ChatRequest': {'allOf': [fSchema('Request'), {'type': 'object', 'required': ['messages'], 'properties': {
      'messages': {'type': 'array', 'items': {'type': 'object', 'required': ['role'], 'properties': {
        'role': {'type': 'string', 'enum': ['system', 'developer', 'user', 'assistant', 'tool']},
        'content': {'oneOf': [{'type': 'string'}, {'type': 'array', 'items': {'type': 'object', 'additionalProperties': True}}]},
        'tool_calls': {'type': 'array', 'items': {'type': 'object', 'additionalProperties': True}}, 'tool_call_id': {'type': 'string'}
      }}}
    }}], 'example': {'messages': [{'role': 'user', 'content': 'Hello'}], 'stream': False}},
    'TokenRequest': {'type': 'object', 'properties': {'content': {'type': 'string'}, 'tokens': {'type': 'array', 'items': {'type': 'integer'}}, 'add_special': {'type': 'boolean'}, 'with_pieces': {'type': 'boolean'}}},
    'ModelRequest': {'type': 'object', 'required': ['model'], 'properties': {'model': {'type': 'string'}}, 'additionalProperties': True},
    'StreamLookup': {'type': 'object', 'required': ['conversation_ids'], 'properties': {'conversation_ids': {'type': 'array', 'items': {'type': 'string'}}}}
  }
  dDocument = {
    'openapi': '3.0.3',
    'info': {'title': 'llama-server-apu API', 'version': '1.0.0', 'description': 'All API routes are under /api. The chat interface is at /. Most operations require the configured API key. Model capabilities and launch flags determine feature availability. Native and compatibility aliases share handlers. Additional backend sampling parameters are accepted. Google Cloud prediction mode additionally exposes /api/predict (or its configured prediction suffix), accepting an instances array with @requestFormat dispatch names and returning a predictions array.'},
    'servers': [{'url': '/api'}],
    'security': [{'BearerAuth': []}, {'ApiKeyAuth': []}],
    'paths': dict(sorted(dPaths.items())),
    'components': {'securitySchemes': {'BearerAuth': {'type': 'http', 'scheme': 'bearer'}, 'ApiKeyAuth': {'type': 'apiKey', 'in': 'header', 'name': 'X-Api-Key'}}, 'schemas': dSchemas}
  }
  (cRoot / 'backend/tools/server/openapi.json').write_text(json.dumps(dDocument, indent=2, ensure_ascii=False) + '\n')

try:
  fMain()
except (OSError, ValueError) as vError:
  print(str(vError), file=sys.stderr)
  sys.exit(1)
finally:
  pass
