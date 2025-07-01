#ifdef __cplusplus
extern "C"
{
#endif

#include <stdint.h>
#include <stdbool.h>

    // Saves RGBA data to a PNG file. (Can keep this if you still need file writing, or remove)
    // Returns true on success, false on failure.
    bool save_rgba_to_png(const char *filename, const uint8_t *rgba, int width, int height);

    // Encodes RGBA8888 data into a PNG byte buffer in memory.
    // The returned buffer must be freed by the caller using free_buffer().
    // Parameters:
    //   rgba: Pointer to the RGBA8888 image data.
    //   width: Image width in pixels.
    //   height: Image height in pixels.
    //   out_size: Pointer to a size_t variable that will store the size of the encoded PNG data.
    // Returns: A pointer to a newly allocated buffer containing the PNG data.
    //          Returns NULL on failure.
    uint8_t *encode_rgba_to_png_buffer(const uint8_t *rgba, int width, int height, size_t *out_size);

#ifdef __cplusplus
}
#endif
