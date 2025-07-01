#include "png_wrapper.h"
#include "../third_party/fpng/fpng.h" // Убедитесь, что этот путь верен относительно png_wrapper.cpp
#include <vector>
#include <fstream>

bool save_rgba_to_png(const char *filename, const uint8_t *rgba, int width, int height)
{
    fpng::fpng_init();

    std::vector<uint8_t> out;
    // enum для уровней сжатия, используйте 0 для значения по умолчанию (обычно FASTEST).
    if (!fpng::fpng_encode_image_to_memory(rgba, width, height, 4, out, 0)) // Используем 0 для флагов
        return false;

    std::ofstream f(filename, std::ios::binary);
    if (!f)
        return false;

    f.write((const char *)out.data(), out.size());
    return true;
}

uint8_t *encode_rgba_to_png_buffer(const uint8_t *rgba, int width, int height, size_t *out_size)
{
    if (rgba == nullptr || width <= 0 || height <= 0 || out_size == nullptr)
    {
        fprintf(stderr, "Error (encode_rgba_to_png_buffer): Invalid input parameters.\n");
        if (out_size)
            *out_size = 0; // Ensure output size is zeroed on error
        return nullptr;
    }

    std::vector<uint8_t> png_buffer_vec;
    // fpng_encode_image_to_memory expects width, height, num_channels, data_ptr, and output vector
    bool success = fpng::fpng_encode_image_to_memory(rgba, width, height, 4 /* components (RGBA) */, png_buffer_vec);

    if (!success)
    {
        fprintf(stderr, "Error (encode_rgba_to_png_buffer): Failed to encode PNG to memory.\n");
        if (out_size)
            *out_size = 0;
        return nullptr;
    }

    // Allocate memory on the C heap to return to Dart
    uint8_t *result_buffer = (uint8_t *)malloc(png_buffer_vec.size());
    if (result_buffer == nullptr)
    {
        fprintf(stderr, "Error (encode_rgba_to_png_buffer): Failed to allocate memory for PNG output.\n");
        if (out_size)
            *out_size = 0;
        return nullptr;
    }

    // Copy data from vector to allocated buffer
    memcpy(result_buffer, png_buffer_vec.data(), png_buffer_vec.size());

    // Set the output size
    *out_size = png_buffer_vec.size();

    return result_buffer;
}
