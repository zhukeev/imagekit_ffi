#include "png_wrapper.h"
#include "../third_party/fpng/fpng.h"
#include <vector>
#include <fstream>

bool save_rgba_to_png(const char *filename, const uint8_t *rgba, int width, int height)
{
    fpng::fpng_init();

    std::vector<uint8_t> out;
    if (!fpng::encode_image_to_memory(rgba, width, height, 4, out, fpng::compression_level::FASTEST))
        return false;

    std::ofstream f(filename, std::ios::binary);
    if (!f)
        return false;

    f.write((const char *)out.data(), out.size());
    return true;
}
