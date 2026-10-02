#pragma once

#include "mtmd.h"

#include <vector>

// INTERNAL HEADER FOR DEBUGGING PURPOSES ONLY
// NOT INTENDED FOR PUBLIC USE
// Do not raise issues related to this debugging API

MTMD_API void mtmd_debug_encode_image(mtmd_context * ctx, const std::vector<std::vector<float>> & image);
MTMD_API void mtmd_debug_encode_audio(mtmd_context * ctx, const std::vector<float> & input);

MTMD_API void mtmd_debug_preprocess_image(mtmd_context * ctx, const std::vector<uint8_t> & rgb_values, int nx, int ny);
MTMD_API void mtmd_debug_preprocess_audio(mtmd_context * ctx, const std::vector<float> & pcm_samples);
