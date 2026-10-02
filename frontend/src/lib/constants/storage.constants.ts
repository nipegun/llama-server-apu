/**
 * Storage-related constants (localStorage, IndexedDB).
 *
 * Centralized to ensure consistency across the app and simplify future
 * name changes.
 */

/** Name prefix for all localStorage keys */
export const STORAGE_APP_NAME = 'LlamaUi';

export const ALWAYS_ALLOWED_TOOLS_LOCALSTORAGE_KEY = `${STORAGE_APP_NAME}.alwaysAllowedTools`;

/** Paused model download ids (`<repo>:<tag>`), restored on the next page load. */
export const PAUSED_MODEL_DOWNLOADS_LOCALSTORAGE_KEY = `${STORAGE_APP_NAME}.pausedModelDownloads`;
export const CONFIG_LOCALSTORAGE_KEY = `${STORAGE_APP_NAME}.config`;

/** Disabled tools keyed by stable selection identity */
export const DISABLED_TOOL_KEYS_LOCALSTORAGE_KEY = `${STORAGE_APP_NAME}.disabledToolKeys`;

/** Default disabled tool categories, seeded into newly created conversations */
export const DISABLED_TOOL_CATEGORIES_LOCALSTORAGE_KEY = `${STORAGE_APP_NAME}.disabledToolCategories`;
export const FAVORITE_MODELS_LOCALSTORAGE_KEY = `${STORAGE_APP_NAME}.favoriteModels`;
export const REASONING_EFFORT_DEFAULT_LOCALSTORAGE_KEY = `${STORAGE_APP_NAME}.reasoningEffortDefault`;
export const CONVERSATION_TABS_LOCALSTORAGE_KEY = `${STORAGE_APP_NAME}.conversationTabs`;
export const USER_OVERRIDES_LOCALSTORAGE_KEY = `${STORAGE_APP_NAME}.userOverrides`;
export const DISMISSED_RECOMMENDED_MCP_SERVERS_LOCALSTORAGE_KEY = `${STORAGE_APP_NAME}.dismissedRecommendedMcpServers`;

/** Key prefix for per-conversation resumable stream state, conversationId is appended */
export const STREAM_RESUME_LOCALSTORAGE_KEY_PREFIX = `${STORAGE_APP_NAME}.streamResume.`;

/** Build version stored in localStorage for non-PWA update detection */
export const BUILD_VERSION_LOCALSTORAGE_KEY = `${STORAGE_APP_NAME}.buildVersion`;
