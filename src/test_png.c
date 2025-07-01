#include "png_wrapper.h"
#include <stdlib.h>
#include <stdio.h>

void test_fpng() {
    int width = 256;
    int height = 256;

    uint8_t *rgba = (uint8_t *)malloc(width * height * 4);
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            int i = (y * width + x) * 4;
            rgba[i + 0] = x;       // R: горизонтальный градиент
            rgba[i + 1] = y;       // G: вертикальный градиент
            rgba[i + 2] = 128;     // B: постоянный
            rgba[i + 3] = 255;     // A: непрозрачный
        }
    }

    const char *output_path = "test_output.png";
    if (save_rgba_to_png(output_path, rgba, width, height)) {
        printf("✅ PNG saved: %s\n", output_path);
    } else {
        printf("❌ Failed to save PNG.\n");
    }

    free(rgba);
}

int main() {
    test_fpng();
    return 0;
}
