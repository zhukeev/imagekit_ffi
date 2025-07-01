#ifdef __cplusplus
extern "C"
{
#endif

#include <stdint.h>
#include <stdbool.h>

    bool save_rgba_to_png(const char *filename, const uint8_t *rgba, int width, int height);

#ifdef __cplusplus
}
#endif
