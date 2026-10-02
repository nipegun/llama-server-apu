export const CLI_FLAGS = {
	AGENT: '--agent',
	API_KEY: '--api-key',
	MCP_PROXY: '--ui-mcp-proxy',
	/** Multimodal projector path; unlocks vision/audio for the model. */
	MMPROJ: '--mmproj',
	/** Draft model weights path; the router records it per model. */
	MODEL_DRAFT: '--spec-draft-model',
	SLOTS: '--slots',
	TOOLS: '--tools'
} as const;
