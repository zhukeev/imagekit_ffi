// Minimal C glue around libwebp for: version, get_info, decode, encode, transform.
// Build: link with -lwebp -lsharpyuv

#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>

#include "webp/decode.h"
#include "webp/encode.h"

// ---------------- Common pixel format values (align with Dart PixelFormat) ----
// Keep in sync with your PixelFormat enum values in Dart.
#define IK_FMT_RGB 0
#define IK_FMT_BGR 1
#define IK_FMT_RGBX 2
#define IK_FMT_BGRX 3
#define IK_FMT_XBGR 4
#define IK_FMT_XRGB 5
#define IK_FMT_GRAY 6
#define IK_FMT_RGBA 7
#define IK_FMT_BGRA 8
#define IK_FMT_ABGR 9
#define IK_FMT_ARGB 10

// ---------------- Transform ops (align with your TransformOp in Dart) ---------
#define IK_XF_NONE 0
#define IK_XF_ROT90 1
#define IK_XF_ROT180 2
#define IK_XF_ROT270 3
#define IK_XF_HFLIP 4
#define IK_XF_VFLIP 5
#define IK_XF_TRANSPOSE 6
#define IK_XF_TRANSVERSE 7

// Options bitmask (subset used here)
#define IK_XF_OPT_CROP (1 << 0)

// ---------------- Error helper ------------------------------------------------
static void err_set(char *dst, int cap, const char *msg)
{
  if (!dst || cap <= 0)
    return;
  int n = (int)strlen(msg);
  if (n >= cap)
    n = cap - 1;
  memcpy(dst, msg, (size_t)n);
  dst[n] = 0;
}

// ---------------- API: version string ----------------------------------------
int32_t ik_webp_version_str(uint8_t *out, int32_t cap)
{
  if (!out || cap <= 0)
    return -1;
  const int v = WebPGetDecoderVersion();
  const int a = (v >> 16) & 0xff;
  const int b = (v >> 8) & 0xff;
  const int c = (v >> 0) & 0xff;
  int n = snprintf((char *)out, (size_t)cap, "%d.%d.%d", a, b, c);
  if (n <= 0 || n >= cap)
    return -2;
  return 0;
}

// ---------------- API: get info (w,h) ----------------------------------------
int32_t ik_webp_get_info(const uint8_t *data, int32_t len,
                         int32_t *w, int32_t *h,
                         uint8_t *err, int32_t err_cap)
{
  if (!data || len <= 0)
  {
    err_set((char *)err, err_cap, "bad input");
    return -1;
  }
  int width = 0, height = 0;
  if (!WebPGetInfo(data, len, &width, &height))
  {
    err_set((char *)err, err_cap, "WebPGetInfo failed");
    return -2;
  }
  if (w)
    *w = width;
  if (h)
    *h = height;
  return 0;
}

// Map PixelFormat -> WebPDecoder config colorspace
static WEBP_CSP_MODE csp_for_decode(int pixel_format)
{
  switch (pixel_format)
  {
  case IK_FMT_RGBA:
    return MODE_RGBA;
  case IK_FMT_BGRA:
    return MODE_BGRA;
  case IK_FMT_ARGB:
    return MODE_ARGB;
  case IK_FMT_RGB:
    return MODE_RGB;
  case IK_FMT_BGR:
    return MODE_BGR;
  case IK_FMT_GRAY:
    return MODE_YUV;
  default:
    return MODE_RGBA;
  }
}

// ---------------- API: decode to pixels --------------------------------------
int32_t ik_webp_decode_to_pixels(const uint8_t *data, int32_t len,
                                 uint8_t *out, int32_t out_pitch,
                                 int32_t out_w, int32_t out_h,
                                 int32_t pixel_format,
                                 uint8_t *err, int32_t err_cap)
{
  if (!data || len <= 0 || !out || out_w <= 0 || out_h <= 0) {
    err_set((char*)err, err_cap, "bad args");
    return -1;
  }

  WebPDecoderConfig cfg;
  if (!WebPInitDecoderConfig(&cfg)) {
    err_set((char*)err, err_cap, "WebPInitDecoderConfig failed");
    return -2;
  }

  cfg.options.use_threads = 1;

  // bpp / pitch
  int bpp = 4;
  switch (pixel_format) {
    case IK_FMT_RGB: bpp = 3; break;
    case IK_FMT_BGR: bpp = 3; break;
    case IK_FMT_GRAY: bpp = 1; break;
    default: bpp = 4; break;
  }
  if (out_pitch == 0) out_pitch = out_w * bpp;

  if (pixel_format == IK_FMT_GRAY) {
    // YUV decode into internal buffer, then copy Y -> out
    cfg.output.colorspace = MODE_YUV;
    cfg.output.is_external_memory = 0;  // libwebp allocates buffers

    const VP8StatusCode st = WebPDecode(data, len, &cfg);
    if (st != VP8_STATUS_OK) {
      err_set((char*)err, err_cap, "WebPDecode failed");
      WebPFreeDecBuffer(&cfg.output);
      return -3;
    }

    const WebPYUVABuffer yuva = cfg.output.u.YUVA;
    const uint8_t* srcY = yuva.y;
    const int yStride = yuva.y_stride;
    for (int y = 0; y < out_h; ++y) {
      memcpy(out + (size_t)y * out_pitch, srcY + (size_t)y * yStride, (size_t)out_w);
    }
    WebPFreeDecBuffer(&cfg.output);
    return 0;
  }

  // Non-GRAY: decode directly into external RGBA/BGRA/RGB...
  cfg.output.colorspace = csp_for_decode(pixel_format);
  cfg.output.is_external_memory = 1;
  cfg.output.u.RGBA.rgba   = out;
  cfg.output.u.RGBA.stride = out_pitch;
  cfg.output.u.RGBA.size   = (size_t)out_pitch * (size_t)out_h;

  const VP8StatusCode st = WebPDecode(data, len, &cfg);
  if (st != VP8_STATUS_OK) {
    err_set((char*)err, err_cap, "WebPDecode failed");
    WebPFreeDecBuffer(&cfg.output);
    return -3;
  }

  WebPFreeDecBuffer(&cfg.output);
  return 0;
}

// ---------------- Encode helpers ---------------------------------------------

// lossy: only 4:2:0; emulate 4:4:4 through lossless/near-lossless
static int choose_lossless_for_subsampling(int subsampling)
{
  // Dart Subsampling.s444 -> request "no subsampling"
  // s422 coerced to 420 in Dart side already
  const int S444 = 2;
  return (subsampling == S444) ? 1 : 0;
}

static int has_alpha_pf(int pixel_format)
{
  switch (pixel_format)
  {
  case IK_FMT_RGBA:
  case IK_FMT_BGRA:
  case IK_FMT_ARGB:
  case IK_FMT_ABGR:
    return 1;
  default:
    return 0;
  }
}

// Import pixels into WebPPicture according to pixel_format (tight or pitched)
static int import_picture(WebPPicture* pic, const uint8_t* pixels,
                          int width, int height, int pitch, int pixel_format,
                          char* err, int err_cap)
{
  // Fast paths: directly supported by libwebp import helpers.
  switch (pixel_format) {
    case IK_FMT_RGBA: return WebPPictureImportRGBA(pic, pixels, pitch);
    case IK_FMT_BGRA: return WebPPictureImportBGRA(pic, pixels, pitch);
    case IK_FMT_RGBX: return WebPPictureImportRGBX(pic, pixels, pitch);
    case IK_FMT_BGRX: return WebPPictureImportBGRX(pic, pixels, pitch);
    case IK_FMT_RGB:  return WebPPictureImportRGB(pic,  pixels, pitch);
    case IK_FMT_BGR:  return WebPPictureImportBGR(pic,  pixels, pitch);
    default: break; // fallthrough to slow paths below
  }

  // Slow paths: make a temporary tightly-packed RGBA buffer and import once.
  const size_t row_rgba = (size_t)width * 4;
  const size_t size_rgba = row_rgba * (size_t)height;

  // Helper: allocate a temp RGBA image.
  uint8_t* tmp = (uint8_t*)malloc(size_rgba);
  if (!tmp) {
    err_set(err, err_cap, "OOM");
    return 0;
  }

  if (pixel_format == IK_FMT_ARGB) {
    // Input per-pixel layout: A R G B  -> output RGBA
    for (int y = 0; y < height; ++y) {
      const uint8_t* s = pixels + (size_t)y * pitch;
      uint8_t* d = tmp + (size_t)y * row_rgba;
      for (int x = 0; x < width; ++x) {
        const uint8_t A = s[0], R = s[1], G = s[2], B = s[3];
        d[0] = R; d[1] = G; d[2] = B; d[3] = A;
        s += 4; d += 4;
      }
    }
  } else if (pixel_format == IK_FMT_ABGR) {
    // Input per-pixel layout: A B G R  -> output RGBA
    for (int y = 0; y < height; ++y) {
      const uint8_t* s = pixels + (size_t)y * pitch;
      uint8_t* d = tmp + (size_t)y * row_rgba;
      for (int x = 0; x < width; ++x) {
        const uint8_t A = s[0], B = s[1], G = s[2], R = s[3];
        d[0] = R; d[1] = G; d[2] = B; d[3] = A;
        s += 4; d += 4;
      }
    }
  } else if (pixel_format == IK_FMT_GRAY) {
    // Expand GRAY -> RGBA (A=255)
    for (int y = 0; y < height; ++y) {
      const uint8_t* s = pixels + (size_t)y * pitch;
      uint8_t* d = tmp + (size_t)y * row_rgba;
      for (int x = 0; x < width; ++x) {
        const uint8_t g = s[x];
        d[0] = g; d[1] = g; d[2] = g; d[3] = 255;
        d += 4;
      }
    }
  } else {
    free(tmp);
    err_set(err, err_cap, "unsupported pixel_format");
    return 0;
  }

  // Single import call from the temp RGBA buffer (tightly packed).
  const int ok = WebPPictureImportRGBA(pic, tmp, (int)row_rgba);
  free(tmp);
  return ok;
}


// ---------------- API: encode from pixels ------------------------------------
int32_t ik_webp_encode_from_pixels_ex(const uint8_t *pixels,
                                      int32_t width, int32_t pitch, int32_t height,
                                      int32_t pixel_format,
                                      int32_t subsampling,
                                      int32_t quality,
                                      uint8_t **out, int64_t *out_len,
                                      uint8_t *err, int32_t err_cap)
{
  if (!pixels || width <= 0 || height <= 0 || !out || !out_len)
  {
    err_set((char *)err, err_cap, "bad args");
    return -1;
  }

  WebPConfig cfg;
  if (!WebPConfigInit(&cfg))
  {
    err_set((char *)err, err_cap, "WebPConfigInit failed");
    return -2;
  }

  const int want_lossless = choose_lossless_for_subsampling(subsampling);
  if (want_lossless)
  {
    cfg.lossless = 1;
    // If quality < 100, expose near-lossless to approximate 4:4:4 with fidelity control.
    if (quality >= 0 && quality <= 100)
      cfg.near_lossless = quality;
  }
  else
  {
    cfg.lossless = 0;
    cfg.quality = (float)quality; // 0..100
    cfg.method = 4;
    cfg.use_sharp_yuv = 1; // best 420 resampling
  }

  WebPPicture pic;
  if (!WebPPictureInit(&pic))
  {
    err_set((char *)err, err_cap, "WebPPictureInit failed");
    return -3;
  }
  pic.width = width;
  pic.height = height;

  if (!import_picture(&pic, pixels, width, height, pitch, pixel_format,
                      (char *)err, err_cap))
  {
    WebPPictureFree(&pic);
    if (err && err[0] == 0)
      err_set((char *)err, err_cap, "import failed");
    return -4;
  }

  WebPMemoryWriter wrt;
  WebPMemoryWriterInit(&wrt);
  pic.writer = WebPMemoryWrite;
  pic.custom_ptr = &wrt;

  const int ok = WebPEncode(&cfg, &pic);
  if (!ok)
  {
    err_set((char *)err, err_cap, "WebPEncode failed");
    WebPPictureFree(&pic);
    WebPMemoryWriterClear(&wrt);
    return -5;
  }

  *out = wrt.mem; // ownership transferred to caller
  *out_len = (int64_t)wrt.size;

  WebPPictureFree(&pic);
  // DON'T clear writer: we return wrt.mem to Dart and free in ik_webp_free.
  return 0;
}

// ---------------- Pixel transforms on RGBA -----------------------------------

static int rgba_alloc(uint8_t **buf, int w, int h)
{
  size_t n = (size_t)w * (size_t)h * 4;
  *buf = (uint8_t *)malloc(n);
  return (*buf != NULL);
}

static void rgba_copy(uint8_t *dst, const uint8_t *src, int w, int h)
{
  memcpy(dst, src, (size_t)w * (size_t)h * 4);
}

static void rgba_flip_h(uint8_t *p, int w, int h)
{
  for (int y = 0; y < h; ++y)
  {
    uint8_t *row = p + (size_t)y * w * 4;
    for (int x = 0; x < w / 2; ++x)
    {
      uint8_t tmp[4];
      memcpy(tmp, row + 4 * x, 4);
      memcpy(row + 4 * x, row + 4 * (w - 1 - x), 4);
      memcpy(row + 4 * (w - 1 - x), tmp, 4);
    }
  }
}

static void rgba_flip_v(uint8_t *p, int w, int h)
{
  const int rowb = w * 4;
  for (int y = 0; y < h / 2; ++y)
  {
    uint8_t *r1 = p + (size_t)y * rowb;
    uint8_t *r2 = p + (size_t)(h - 1 - y) * rowb;
    for (int i = 0; i < rowb; ++i)
    {
      uint8_t t = r1[i];
      r1[i] = r2[i];
      r2[i] = t;
    }
  }
}

static void rgba_transpose(uint8_t *dst, const uint8_t *src, int w, int h)
{
  for (int y = 0; y < h; ++y)
  {
    for (int x = 0; x < w; ++x)
    {
      const uint8_t *s = src + ((size_t)y * w + x) * 4;
      uint8_t *d = dst + ((size_t)x * h + y) * 4;
      d[0] = s[0];
      d[1] = s[1];
      d[2] = s[2];
      d[3] = s[3];
    }
  }
}

static void rgba_rotate90(uint8_t *dst, const uint8_t *src, int w, int h)
{
  // rotate clockwise 90: dst(x,y) = src(y, w-1-x)
  for (int y = 0; y < h; ++y)
  {
    for (int x = 0; x < w; ++x)
    {
      const uint8_t *s = src + ((size_t)y * w + x) * 4;
      uint8_t *d = dst + ((size_t)x * h + (h - 1 - y)) * 4;
      d[0] = s[0];
      d[1] = s[1];
      d[2] = s[2];
      d[3] = s[3];
    }
  }
}

static void rgba_rotate180(uint8_t *dst, const uint8_t *src, int w, int h)
{
  for (int y = 0; y < h; ++y)
  {
    for (int x = 0; x < w; ++x)
    {
      const uint8_t *s = src + ((size_t)y * w + x) * 4;
      uint8_t *d = dst + ((size_t)(h - 1 - y) * w + (w - 1 - x)) * 4;
      d[0] = s[0];
      d[1] = s[1];
      d[2] = s[2];
      d[3] = s[3];
    }
  }
}

static void rgba_rotate270(uint8_t *dst, const uint8_t *src, int w, int h)
{
  // rotate clockwise 270: dst(x,y) = src(w-1-y, x)
  for (int y = 0; y < h; ++y)
  {
    for (int x = 0; x < w; ++x)
    {
      const uint8_t *s = src + ((size_t)y * w + x) * 4;
      uint8_t *d = dst + ((size_t)(w - 1 - x) * h + y) * 4;
      d[0] = s[0];
      d[1] = s[1];
      d[2] = s[2];
      d[3] = s[3];
    }
  }
}

static int clampi(int v, int lo, int hi)
{
  if (v < lo)
    return lo;
  if (v > hi)
    return hi;
  return v;
}

static void rgba_crop(uint8_t *dst, const uint8_t *src,
                      int w, int h, int x, int y, int cw, int ch)
{
  for (int j = 0; j < ch; ++j)
  {
    const uint8_t *s = src + ((size_t)(y + j) * w + x) * 4;
    uint8_t *d = dst + (size_t)j * cw * 4;
    memcpy(d, s, (size_t)cw * 4);
  }
}

// ---------------- API: transform (decode RGBA -> op -> encode) ----------------
int32_t ik_webp_transform_simple(const uint8_t *data, int32_t len,
                                 int32_t op, int32_t options,
                                 int32_t cropX, int32_t cropY,
                                 int32_t cropW, int32_t cropH,
                                 uint8_t **out, int64_t *out_len,
                                 int32_t /*flags*/,
                                 uint8_t *err, int32_t err_cap)
{
  if (!data || len <= 0 || !out || !out_len)
  {
    err_set((char *)err, err_cap, "bad args");
    return -1;
  }

  int w = 0, h = 0;
  if (!WebPGetInfo(data, len, &w, &h))
  {
    err_set((char *)err, err_cap, "WebPGetInfo failed");
    return -2;
  }

  // Decode to RGBA tight
  uint8_t *rgba = WebPDecodeRGBA(data, len, &w, &h);
  if (!rgba)
  {
    err_set((char *)err, err_cap, "WebPDecodeRGBA failed");
    return -3;
  }

  uint8_t *tmp = NULL;
  int tw = w, th = h;

  // crop first if requested
  if (options & IK_XF_OPT_CROP)
  {
    cropX = clampi(cropX, 0, w);
    cropY = clampi(cropY, 0, h);
    cropW = clampi(cropW, 0, w - cropX);
    cropH = clampi(cropH, 0, h - cropY);
    if (cropW <= 0 || cropH <= 0)
    {
      WebPFree(rgba);
      err_set((char *)err, err_cap, "empty crop");
      return -4;
    }
    if (!rgba_alloc(&tmp, cropW, cropH))
    {
      WebPFree(rgba);
      err_set((char *)err, err_cap, "OOM");
      return -5;
    }
    rgba_crop(tmp, rgba, w, h, cropX, cropY, cropW, cropH);
    WebPFree(rgba);
    rgba = tmp;
    tmp = NULL;
    w = cropW;
    h = cropH;
  }

  switch (op)
  {
  case IK_XF_NONE:
    // nothing
    break;
  case IK_XF_HFLIP:
    rgba_flip_h(rgba, w, h);
    break;
  case IK_XF_VFLIP:
    rgba_flip_v(rgba, w, h);
    break;
  case IK_XF_ROT90:
    if (!rgba_alloc(&tmp, h, w))
    {
      WebPFree(rgba);
      err_set((char *)err, err_cap, "OOM");
      return -6;
    }
    rgba_rotate90(tmp, rgba, w, h);
    free(rgba);
    rgba = tmp;
    tmp = NULL;
    tw = h;
    th = w;
    w = tw;
    h = th;
    break;
  case IK_XF_ROT180:
    if (!rgba_alloc(&tmp, w, h))
    {
      WebPFree(rgba);
      err_set((char *)err, err_cap, "OOM");
      return -7;
    }
    rgba_rotate180(tmp, rgba, w, h);
    free(rgba);
    rgba = tmp;
    tmp = NULL;
    break;
  case IK_XF_ROT270:
    if (!rgba_alloc(&tmp, h, w))
    {
      WebPFree(rgba);
      err_set((char *)err, err_cap, "OOM");
      return -8;
    }
    rgba_rotate270(tmp, rgba, w, h);
    free(rgba);
    rgba = tmp;
    tmp = NULL;
    tw = h;
    th = w;
    w = tw;
    h = th;
    break;
  case IK_XF_TRANSPOSE:
    if (!rgba_alloc(&tmp, h, w))
    {
      WebPFree(rgba);
      err_set((char *)err, err_cap, "OOM");
      return -9;
    }
    rgba_transpose(tmp, rgba, w, h);
    free(rgba);
    rgba = tmp;
    tmp = NULL;
    tw = h;
    th = w;
    w = tw;
    h = th;
    break;
  case IK_XF_TRANSVERSE:
    // transpose + flip both axes == rotate 180 over secondary diagonal
    if (!rgba_alloc(&tmp, h, w))
    {
      WebPFree(rgba);
      err_set((char *)err, err_cap, "OOM");
      return -10;
    }
    rgba_transpose(tmp, rgba, w, h);
    free(rgba);
    rgba = tmp;
    tmp = NULL;
    rgba_flip_h(rgba, h, w);
    rgba_flip_v(rgba, h, w);
    tw = h;
    th = w;
    w = tw;
    h = th;
    break;
  default:
    WebPFree(rgba);
    err_set((char *)err, err_cap, "unsupported op");
    return -11;
  }

  // Re-encode RGBA as lossy 420 (quality 90). If you want to pass through
  // quality/subsampling externally, extend the signature similarly to PNG.
  WebPConfig cfg;
  WebPConfigInit(&cfg);
  cfg.lossless = 0;
  cfg.quality = 90.f;
  cfg.method = 4;
  cfg.use_sharp_yuv = 1;

  WebPPicture pic;
  WebPPictureInit(&pic);
  pic.width = w;
  pic.height = h;
  if (!WebPPictureImportRGBA(&pic, rgba, w * 4))
  {
    WebPFree(rgba);
    err_set((char *)err, err_cap, "import RGBA failed");
    WebPPictureFree(&pic);
    return -12;
  }

  WebPMemoryWriter wrt;
  WebPMemoryWriterInit(&wrt);
  pic.writer = WebPMemoryWrite;
  pic.custom_ptr = &wrt;

  const int ok = WebPEncode(&cfg, &pic);
  WebPFree(rgba);
  if (!ok)
  {
    WebPPictureFree(&pic);
    WebPMemoryWriterClear(&wrt);
    err_set((char *)err, err_cap, "WebPEncode failed");
    return -13;
  }

  *out = wrt.mem;
  *out_len = (int64_t)wrt.size;
  WebPPictureFree(&pic);
  return 0;
}

// ---------------- API: free ---------------------------------------------------
void ik_webp_free(uint8_t *p)
{
  if (p)
    free(p);
}
