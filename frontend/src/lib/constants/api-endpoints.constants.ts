export const API_MODELS = {
	/** Download a model from HuggingFace (ROUTER mode, POST) or cancel/remove it (DELETE) */
	DELETE: '/api/models',
	DOWNLOAD: '/api/models',
	LIST: '/api/v1/models',
	LOAD: '/api/models/load',
	SSE: '/api/models/sse',
	UNLOAD: '/api/models/unload'
};

// chat completion routes, the control route drives realtime inference (e.g. end reasoning)
export const API_CHAT = {
	COMPLETIONS: './api/v1/chat/completions',
	CONTROL: './api/v1/chat/completions/control'
};

// slot introspection, requires the --slots flag on the server
export const API_SLOTS = {
	LIST: './api/slots'
};

export const API_TOOLS = {
	EXECUTE: '/api/tools',
	LIST: '/api/tools'
};

// resumable stream routes, the conv::model identity travels as the conv_id query param
// because model names can contain slashes that a path segment cannot carry
// resume retry cadence while the owning model is still loading (server answers 503)
export const STREAM_RESUME_RETRY_MS = 2000;

export const API_STREAM = {
	BASE: './api/v1/stream',
	LOOKUP: './api/v1/streams/lookup'
};

// query params for the resumable stream routes
export const STREAM_QUERY_PARAMS = {
	CONV_ID: 'conv_id',
	FROM: 'from'
} as const;

/** CORS proxy endpoint path */
export const CORS_PROXY_ENDPOINT = '/api/cors-proxy';
