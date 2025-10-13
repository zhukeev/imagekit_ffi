#include "ik_png.h"
#include <png.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* --- small helpers ------------------------------------------------------ */

static void set_err(uint8_t *err, int32_t err_len, const char *msg)
{
  if (!err || err_len <= 0)
    return;
  if (!msg)
  {
    err[0] = '\0';
    return;
  }

  snprintf((char *)err, (size_t)err_len, "%s", msg);
  ((char *)err)[err_len - 1] = '\0';
}

/* growable memory sink for png_set_write_fn */
struct MemW
{
  png_bytep buf;
  size_t size;
  size_t cap;
};

static void mem_write_data(png_structp png_ptr, png_bytep data, size_t length)
{
  struct MemW *o = (struct MemW *)png_get_io_ptr(png_ptr);
  if (!o)
    png_error(png_ptr, "no io_ptr");

  /* ensure capacity */
  if (o->size + length > o->cap)
  {
    size_t ncap = o->cap ? o->cap * 2u : 65536u;
    while (ncap < o->size + length)
      ncap *= 2u;
    png_bytep nbuf = (png_bytep)realloc(o->buf, ncap);
    if (!nbuf)
      png_error(png_ptr, "oom");
    o->buf = nbuf;
    o->cap = ncap;
  }

  memcpy(o->buf + o->size, data, length);
  o->size += length;
}

static void mem_flush(png_structp png_ptr)
{
  (void)png_ptr; /* nothing */
}

/* PixelFormat -> bytes-per-pixel */
static int bpp_for_pf(int pf)
{
  switch (pf)
  {
  case 0: /* rgb   */
    return 3;
  case 1: /* bgr   */
    return 3;
  case 2: /* rgbx  */
    return 4;
  case 3: /* bgrx  */
    return 4;
  case 4: /* xbgr  */
    return 4;
  case 5: /* xrgb  */
    return 4;
  case 6: /* gray  */
    return 1;
  case 7: /* rgba  */
    return 4;
  case 8: /* bgra  */
    return 4;
  case 9: /* abgr  */
    return 4;
  case 10: /* argb  */
    return 4;
  case 11:    /* cmyk  */
    return 4; /* not supported; just for size calc if ever needed */
  default:
    return 0;
  }
}

/* For libpng simplified API we use PNG_FORMAT_RGBA/PNG_FORMAT_RGB/PNG_FORMAT_GRAY as IO formats.
   We then swizzle to/from the user PixelFormat when necessary. */
static int can_direct_png_format_for_pf(int pf, int *out_png_fmt)
{
  switch (pf)
  {
  case 0:
    *out_png_fmt = PNG_FORMAT_RGB;
    return 1; /* rgb  */
  case 6:
    *out_png_fmt = PNG_FORMAT_GRAY;
    return 1; /* gray */
  case 7:
    *out_png_fmt = PNG_FORMAT_RGBA;
    return 1; /* rgba */
  default:
    *out_png_fmt = PNG_FORMAT_RGBA;
    return 0; /* others: go via RGBA + swizzle */
  }
}

/* Swizzles from RGBA32 -> destination PF into out row. */
static void swizzle_from_rgba(const uint8_t *src_rgba, uint8_t *dst, int pf, int pixels)
{
  switch (pf)
  {
  case 7: /* RGBA -> RGBA */
    memcpy(dst, src_rgba, (size_t)pixels * 4);
    break;
  case 0: /* RGBA -> RGB */
    for (int i = 0; i < pixels; ++i)
    {
      dst[3 * i + 0] = src_rgba[4 * i + 0];
      dst[3 * i + 1] = src_rgba[4 * i + 1];
      dst[3 * i + 2] = src_rgba[4 * i + 2];
    }
    break;
  case 1: /* RGBA -> BGR */
    for (int i = 0; i < pixels; ++i)
    {
      dst[3 * i + 0] = src_rgba[4 * i + 2];
      dst[3 * i + 1] = src_rgba[4 * i + 1];
      dst[3 * i + 2] = src_rgba[4 * i + 0];
    }
    break;
  case 2: /* RGBA -> RGBX (opaque X) */
  case 5: /* RGBA -> XRGB */
    for (int i = 0; i < pixels; ++i)
    {
      dst[4 * i + 0] = src_rgba[4 * i + 0];
      dst[4 * i + 1] = src_rgba[4 * i + 1];
      dst[4 * i + 2] = src_rgba[4 * i + 2];
      dst[4 * i + 3] = 0xFF;
    }
    break;
  case 3: /* RGBA -> BGRX */
  case 4: /* RGBA -> XBGR */
    for (int i = 0; i < pixels; ++i)
    {
      dst[4 * i + 0] = src_rgba[4 * i + 2];
      dst[4 * i + 1] = src_rgba[4 * i + 1];
      dst[4 * i + 2] = src_rgba[4 * i + 0];
      dst[4 * i + 3] = 0xFF;
    }
    break;
  case 8: /* RGBA -> BGRA */
    for (int i = 0; i < pixels; ++i)
    {
      dst[4 * i + 0] = src_rgba[4 * i + 2];
      dst[4 * i + 1] = src_rgba[4 * i + 1];
      dst[4 * i + 2] = src_rgba[4 * i + 0];
      dst[4 * i + 3] = src_rgba[4 * i + 3];
    }
    break;
  case 9: /* RGBA -> ABGR */
    for (int i = 0; i < pixels; ++i)
    {
      dst[4 * i + 0] = src_rgba[4 * i + 3];
      dst[4 * i + 1] = src_rgba[4 * i + 2];
      dst[4 * i + 2] = src_rgba[4 * i + 1];
      dst[4 * i + 3] = src_rgba[4 * i + 0];
    }
    break;
  case 10: /* RGBA -> ARGB */
    for (int i = 0; i < pixels; ++i)
    {
      dst[4 * i + 0] = src_rgba[4 * i + 3];
      dst[4 * i + 1] = src_rgba[4 * i + 0];
      dst[4 * i + 2] = src_rgba[4 * i + 1];
      dst[4 * i + 3] = src_rgba[4 * i + 2];
    }
    break;
  case 6: /* RGBA -> GRAY (luma approx) */
    for (int i = 0; i < pixels; ++i)
    {
      uint8_t r = src_rgba[4 * i + 0], g = src_rgba[4 * i + 1], b = src_rgba[4 * i + 2];
      dst[i] = (uint8_t)((299 * r + 587 * g + 114 * b) / 1000);
    }
    break;
  default:
    /* CMYK or unknown: leave undefined; caller shouldn't get here. */
    break;
  }
}

/* Swizzles from source PF -> RGBA32 into dst. */
static void swizzle_to_rgba(const uint8_t *src, uint8_t *dst_rgba, int pf, int pixels)
{
  switch (pf)
  {
  case 7: /* RGBA -> RGBA */
    memcpy(dst_rgba, src, (size_t)pixels * 4);
    break;
  case 0: /* RGB -> RGBA */
    for (int i = 0; i < pixels; ++i)
    {
      dst_rgba[4 * i + 0] = src[3 * i + 0];
      dst_rgba[4 * i + 1] = src[3 * i + 1];
      dst_rgba[4 * i + 2] = src[3 * i + 2];
      dst_rgba[4 * i + 3] = 0xFF;
    }
    break;
  case 1: /* BGR -> RGBA */
    for (int i = 0; i < pixels; ++i)
    {
      dst_rgba[4 * i + 0] = src[3 * i + 2];
      dst_rgba[4 * i + 1] = src[3 * i + 1];
      dst_rgba[4 * i + 2] = src[3 * i + 0];
      dst_rgba[4 * i + 3] = 0xFF;
    }
    break;
  case 2: /* RGBX -> RGBA (drop X) */
  case 5: /* XRGB -> RGBA (drop X) */
    for (int i = 0; i < pixels; ++i)
    {
      dst_rgba[4 * i + 0] = src[4 * i + 0];
      dst_rgba[4 * i + 1] = src[4 * i + 1];
      dst_rgba[4 * i + 2] = src[4 * i + 2];
      dst_rgba[4 * i + 3] = 0xFF;
    }
    break;
  case 3: /* BGRX -> RGBA (drop X) */
  case 4: /* XBGR -> RGBA (drop X) */
    for (int i = 0; i < pixels; ++i)
    {
      dst_rgba[4 * i + 0] = src[4 * i + 2];
      dst_rgba[4 * i + 1] = src[4 * i + 1];
      dst_rgba[4 * i + 2] = src[4 * i + 0];
      dst_rgba[4 * i + 3] = 0xFF;
    }
    break;
  case 8: /* BGRA -> RGBA */
    for (int i = 0; i < pixels; ++i)
    {
      dst_rgba[4 * i + 0] = src[4 * i + 2];
      dst_rgba[4 * i + 1] = src[4 * i + 1];
      dst_rgba[4 * i + 2] = src[4 * i + 0];
      dst_rgba[4 * i + 3] = src[4 * i + 3];
    }
    break;
  case 9: /* ABGR -> RGBA */
    for (int i = 0; i < pixels; ++i)
    {
      dst_rgba[4 * i + 3] = src[4 * i + 0];
      dst_rgba[4 * i + 2] = src[4 * i + 1];
      dst_rgba[4 * i + 1] = src[4 * i + 2];
      dst_rgba[4 * i + 0] = src[4 * i + 3];
    }
    break;
  case 10: /* ARGB -> RGBA */
    for (int i = 0; i < pixels; ++i)
    {
      dst_rgba[4 * i + 3] = src[4 * i + 0];
      dst_rgba[4 * i + 0] = src[4 * i + 1];
      dst_rgba[4 * i + 1] = src[4 * i + 2];
      dst_rgba[4 * i + 2] = src[4 * i + 3];
    }
    break;
  case 6: /* GRAY -> RGBA */
    for (int i = 0; i < pixels; ++i)
    {
      uint8_t g = src[i];
      dst_rgba[4 * i + 0] = g;
      dst_rgba[4 * i + 1] = g;
      dst_rgba[4 * i + 2] = g;
      dst_rgba[4 * i + 3] = 0xFF;
    }
    break;
  default:
    /* CMYK or unknown: leave undefined; caller shouldn't get here. */
    break;
  }
}

/* Basic pixel transforms on RGBA buffer. All in-place where possible. */

static int clampi(int v, int lo, int hi) { return v < lo ? lo : (v > hi ? hi : v); }

static void flip_h_rgba(uint8_t *rgba, int w, int h)
{
  const int stride = w * 4;
  for (int y = 0; y < h; ++y)
  {
    uint8_t *row = rgba + y * stride;
    for (int x = 0; x < w / 2; ++x)
    {
      uint8_t *a = row + 4 * x;
      uint8_t *b = row + 4 * (w - 1 - x);
      for (int c = 0; c < 4; ++c)
      {
        uint8_t t = a[c];
        a[c] = b[c];
        b[c] = t;
      }
    }
  }
}

static void flip_v_rgba(uint8_t *rgba, int w, int h)
{
  const int stride = w * 4;
  for (int y = 0; y < h / 2; ++y)
  {
    uint8_t *a = rgba + y * stride;
    uint8_t *b = rgba + (h - 1 - y) * stride;
    for (int i = 0; i < stride; ++i)
    {
      uint8_t t = a[i];
      a[i] = b[i];
      b[i] = t;
    }
  }
}

static void transpose_rgba(uint8_t *rgba, int w, int h, uint8_t **out, int *outw, int *outh)
{
  uint8_t *dst = (uint8_t *)malloc((size_t)w * h * 4);
  if (!dst)
  {
    *out = NULL;
    return;
  }
  for (int y = 0; y < h; ++y)
  {
    for (int x = 0; x < w; ++x)
    {
      uint8_t *s = rgba + 4 * (y * w + x);
      uint8_t *d = dst + 4 * (x * h + y);
      d[0] = s[0];
      d[1] = s[1];
      d[2] = s[2];
      d[3] = s[3];
    }
  }
  *out = dst;
  *outw = h;
  *outh = w;
}

static void rotate90_rgba(uint8_t *rgba, int w, int h, uint8_t **out, int *outw, int *outh)
{
  /* rot90 = transpose + H flip on the transposed image */
  uint8_t *t = NULL;
  int tw = 0, th = 0;
  transpose_rgba(rgba, w, h, &t, &tw, &th);
  if (!t)
  {
    *out = NULL;
    return;
  }
  flip_h_rgba(t, tw, th);
  *out = t;
  *outw = tw;
  *outh = th;
}

static void rotate270_rgba(uint8_t *rgba, int w, int h, uint8_t **out, int *outw, int *outh)
{
  uint8_t *t = NULL;
  int tw = 0, th = 0;
  transpose_rgba(rgba, w, h, &t, &tw, &th);
  if (!t)
  {
    *out = NULL;
    return;
  }
  flip_v_rgba(t, tw, th);
  *out = t;
  *outw = tw;
  *outh = th;
}

static void rotate180_rgba(uint8_t *rgba, int w, int h)
{
  flip_h_rgba(rgba, w, h);
  flip_v_rgba(rgba, w, h);
}

static uint8_t *crop_rgba(uint8_t *rgba, int w, int h, int x, int y, int cw, int ch, int *outw, int *outh)
{
  x = clampi(x, 0, w);
  y = clampi(y, 0, h);
  cw = clampi(cw, 0, w - x);
  ch = clampi(ch, 0, h - y);
  if (cw <= 0 || ch <= 0)
  {
    *outw = *outh = 0;
    return NULL;
  }
  uint8_t *dst = (uint8_t *)malloc((size_t)cw * ch * 4);
  if (!dst)
  {
    *outw = *outh = 0;
    return NULL;
  }
  for (int row = 0; row < ch; ++row)
  {
    memcpy(dst + row * cw * 4, rgba + ((y + row) * w + x) * 4, (size_t)cw * 4);
  }
  *outw = cw;
  *outh = ch;
  return dst;
}

/* Optional grayscale conversion (XformOptions.gray). */
static void rgba_to_gray_inplace(uint8_t *rgba, int pixels)
{
  for (int i = 0; i < pixels; i++)
  {
    uint8_t r = rgba[4 * i + 0], g = rgba[4 * i + 1], b = rgba[4 * i + 2];
    uint8_t y = (uint8_t)((299 * r + 587 * g + 114 * b) / 1000);
    rgba[4 * i + 0] = y;
    rgba[4 * i + 1] = y;
    rgba[4 * i + 2] = y; /* keep alpha */
  }
}

/* ================= version/info ================= */

int32_t ik_png_version_str(char *out, int32_t out_len)
{
  if (!out || out_len <= 0)
    return -1;
  const char *v = PNG_LIBPNG_VER_STRING;
  snprintf(out, (size_t)out_len, "%s", v);
  out[out_len - 1] = '\0';
  return 0;
}

int32_t ik_png_get_info(
    const uint8_t *png_bytes, int32_t len,
    int32_t *out_w, int32_t *out_h,
    char *err, int32_t err_len)
{
  if (!png_bytes || len <= 0 || !out_w || !out_h)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }

  png_image image;
  memset(&image, 0, sizeof(image));
  image.version = PNG_IMAGE_VERSION;

  if (!png_image_begin_read_from_memory(&image, png_bytes, (size_t)len))
  {
    set_err(err, err_len, image.message ? image.message : "png begin read failed");
    return -2;
  }

  *out_w = (int32_t)image.width;
  *out_h = (int32_t)image.height;
  png_image_free(&image);
  set_err(err, err_len, NULL);
  return 0;
}

/* ================= decode ================= */

int32_t ik_png_decode_to_pixels(
    const uint8_t *png_bytes, int32_t len,
    uint8_t *out_pixels, int32_t out_pitch,
    int32_t out_w, int32_t out_h, int32_t out_pf,
    char *err, int32_t err_len)
{
  if (!png_bytes || len <= 0 || !out_pixels || out_w <= 0 || out_h <= 0)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }

  int direct_fmt = 0;
  int png_fmt = PNG_FORMAT_RGBA;
  int bpp = bpp_for_pf(out_pf);
  if (bpp == 0)
  {
    set_err(err, err_len, "pixel format not supported");
    return -5;
  }
  direct_fmt = can_direct_png_format_for_pf(out_pf, &png_fmt);

  png_image image;
  memset(&image, 0, sizeof(image));
  image.version = PNG_IMAGE_VERSION;
  if (!png_image_begin_read_from_memory(&image, png_bytes, (size_t)len))
  {
    set_err(err, err_len, image.message ? image.message : "png begin read failed");
    return -2;
  }

  if ((int32_t)image.width != out_w || (int32_t)image.height != out_h)
  {
    png_image_free(&image);
    set_err(err, err_len, "dimension mismatch");
    return -3;
  }

  if (direct_fmt)
  {
    image.format = png_fmt;
    png_int_32 stride = (out_pitch > 0) ? out_pitch : 0;
    int ok = png_image_finish_read(&image, NULL, out_pixels, stride, NULL);
    png_image_free(&image);
    if (!ok)
    {
      set_err(err, err_len, "png finish read failed");
      return -2;
    }
    set_err(err, err_len, NULL);
    return 0;
  }

  /* Read as RGBA first, then swizzle to requested PF. */
  image.format = PNG_FORMAT_RGBA;
  size_t tmp_sz = (size_t)image.width * image.height * 4;
  uint8_t *tmp = (uint8_t *)malloc(tmp_sz);
  if (!tmp)
  {
    png_image_free(&image);
    set_err(err, err_len, "oom");
    return -3;
  }

  int ok = png_image_finish_read(&image, NULL, tmp, 0, NULL);
  png_image_free(&image);
  if (!ok)
  {
    free(tmp);
    set_err(err, err_len, "png finish read failed");
    return -2;
  }

  const int stride_out = (out_pitch > 0) ? out_pitch : (out_w * bpp);
  for (int y = 0; y < out_h; ++y)
  {
    const uint8_t *src = tmp + (size_t)y * out_w * 4;
    uint8_t *dst = out_pixels + (size_t)y * stride_out;
    swizzle_from_rgba(src, dst, out_pf, out_w);
  }

  free(tmp);
  set_err(err, err_len, NULL);
  return 0;
}

/* ================= encode ================= */

int32_t ik_png_encode_from_pixels(
    const uint8_t *pixels,
    int32_t width,
    int32_t pitch,
    int32_t height,
    int32_t pf,
    uint8_t **out_png,
    int64_t *out_len,
    char *err, int32_t err_len)
{
  if (!pixels || width <= 0 || height <= 0 || !out_png || !out_len)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }

  int direct_fmt = 0;
  int png_fmt = PNG_FORMAT_RGBA;
  int bpp = bpp_for_pf(pf);
  if (bpp == 0 || pf == 11 /* CMYK */)
  {
    set_err(err, err_len, "pixel format not supported");
    return -5;
  }
  direct_fmt = can_direct_png_format_for_pf(pf, &png_fmt);

  png_image image;
  memset(&image, 0, sizeof(image));
  image.version = PNG_IMAGE_VERSION;
  image.width = (png_uint_32)width;
  image.height = (png_uint_32)height;

  const uint8_t *src_data = pixels;
  int src_pitch = pitch;
  uint8_t *tmp_rgba = NULL;

  if (direct_fmt)
  {
    image.format = png_fmt;
  }
  else
  {
    /* Convert to RGBA first. */
    image.format = PNG_FORMAT_RGBA;
    size_t sz = (size_t)width * height * 4;
    tmp_rgba = (uint8_t *)malloc(sz);
    if (!tmp_rgba)
    {
      set_err(err, err_len, "oom");
      return -3;
    }

    const uint8_t *src_row = pixels;
    for (int y = 0; y < height; ++y)
    {
      swizzle_to_rgba(src_row, tmp_rgba + (size_t)y * width * 4, pf, width);
      src_row += (pitch > 0) ? pitch : (width * bpp);
    }

    src_data = tmp_rgba;
    src_pitch = 0; /* tight */
  }

  /* Query size */
  png_alloc_size_t required = 0;
  int ok = png_image_write_to_memory(
      &image, NULL, &required, 0,
      src_data, (png_int_32)src_pitch, NULL);

  if (!ok || required == 0)
  {
    set_err(err, err_len, image.message ? image.message : "png size query failed");
    if (tmp_rgba)
      free(tmp_rgba);
    return -2;
  }

  uint8_t *mem = (uint8_t *)malloc((size_t)required);
  if (!mem)
  {
    if (tmp_rgba)
      free(tmp_rgba);
    set_err(err, err_len, "oom");
    return -3;
  }

  png_alloc_size_t outsz = required;
  ok = png_image_write_to_memory(
      &image, mem, &outsz, 0,
      src_data, (png_int_32)src_pitch, NULL);

  if (tmp_rgba)
    free(tmp_rgba);

  if (!ok)
  {
    free(mem);
    set_err(err, err_len, image.message ? image.message : "png write failed");
    return -2;
  }

  *out_png = mem;
  *out_len = (int64_t)outsz;
  set_err(err, err_len, NULL);
  return 0;
}

/* ================= transform (decode -> pixel op -> encode) ================= */

int32_t ik_png_transform_simple(
    const uint8_t *in_png, int32_t in_len,
    int32_t op,
    int32_t options,
    int32_t crop_x, int32_t crop_y, int32_t crop_w, int32_t crop_h,
    uint8_t **out_png, int64_t *out_len,
    int32_t flags,
    char *err, int32_t err_len)
{
  (void)flags; /* PNG ignores JPEG flags; kept for symmetry. */

  if (!in_png || in_len <= 0 || !out_png || !out_len)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }

  /* Fast path: noOutput option -> just echo the input */
  if (options & (1 << 4) /* noOutput */)
  {
    uint8_t *buf = (uint8_t *)malloc((size_t)in_len);
    if (!buf)
    {
      set_err(err, err_len, "oom");
      return -3;
    }
    memcpy(buf, in_png, (size_t)in_len);
    *out_png = buf;
    *out_len = in_len;
    set_err(err, err_len, NULL);
    return 0;
  }

  /* 1) Decode to RGBA (tight). */
  png_image image;
  memset(&image, 0, sizeof(image));
  image.version = PNG_IMAGE_VERSION;
  if (!png_image_begin_read_from_memory(&image, in_png, (size_t)in_len))
  {
    set_err(err, err_len, image.message ? image.message : "png begin read failed");
    return -2;
  }
  image.format = PNG_FORMAT_RGBA;

  int w = (int)image.width, h = (int)image.height;
  size_t sz = (size_t)w * h * 4;
  uint8_t *rgba = (uint8_t *)malloc(sz);
  if (!rgba)
  {
    png_image_free(&image);
    set_err(err, err_len, "oom");
    return -3;
  }

  int ok = png_image_finish_read(&image, NULL, rgba, 0, NULL);
  png_image_free(&image);
  if (!ok)
  {
    free(rgba);
    set_err(err, err_len, "png read failed");
    return -2;
  }

  /* 2) Optional crop first if requested. */
  if (options & (1 << 2) /* crop */)
  {
    int nw = 0, nh = 0;
    uint8_t *cr = crop_rgba(rgba, w, h, crop_x, crop_y, crop_w, crop_h, &nw, &nh);
    free(rgba);
    rgba = cr;
    w = nw;
    h = nh;
    if (!rgba || w <= 0 || h <= 0)
    {
      set_err(err, err_len, "empty crop");
      return -4;
    }
  }

  /* 3) Transform op */
  uint8_t *tmp = NULL;
  int tw = 0, th = 0;
  switch (op)
  {
  case 0: /* none */
    break;
  case 1: /* hflip */
    flip_h_rgba(rgba, w, h);
    break;
  case 2: /* vflip */
    flip_v_rgba(rgba, w, h);
    break;
  case 3: /* transpose */
    transpose_rgba(rgba, w, h, &tmp, &tw, &th);
    if (!tmp)
    {
      free(rgba);
      set_err(err, err_len, "oom");
      return -3;
    }
    free(rgba);
    rgba = tmp;
    w = tw;
    h = th;
    break;
  case 4: /* transverse = transpose + both flips?  For simplicity use: transpose + rot180. */
    transpose_rgba(rgba, w, h, &tmp, &tw, &th);
    if (!tmp)
    {
      free(rgba);
      set_err(err, err_len, "oom");
      return -3;
    }
    rotate180_rgba(tmp, tw, th);
    free(rgba);
    rgba = tmp;
    w = tw;
    h = th;
    break;
  case 5: /* rot90 */
    rotate90_rgba(rgba, w, h, &tmp, &tw, &th);
    if (!tmp)
    {
      free(rgba);
      set_err(err, err_len, "oom");
      return -3;
    }
    free(rgba);
    rgba = tmp;
    w = tw;
    h = th;
    break;
  case 6: /* rot180 */
    rotate180_rgba(rgba, w, h);
    break;
  case 7: /* rot270 */
    rotate270_rgba(rgba, w, h, &tmp, &tw, &th);
    if (!tmp)
    {
      free(rgba);
      set_err(err, err_len, "oom");
      return -3;
    }
    free(rgba);
    rgba = tmp;
    w = tw;
    h = th;
    break;
  default: /* unknown op */
    break;
  }

  /* 4) Optional grayscale */
  if (options & (1 << 3) /* gray */)
  {
    rgba_to_gray_inplace(rgba, w * h);
  }

  /* 5) Encode from RGBA */
  uint8_t *out_buf = NULL;
  int64_t out_sz = 0;
  int rc = ik_png_encode_from_pixels(
      rgba, w, 0, h, /* pf= */ 7 /* RGBA */, &out_buf, &out_sz, err, err_len);
  free(rgba);
  if (rc != 0)
    return rc;

  *out_png = out_buf;
  *out_len = out_sz;
  set_err(err, err_len, NULL);
  return 0;
}

/* map our PixelFormat enum (Dart side) to libpng color_type/channels */
static void pf_to_png(int pf, int *out_color_type, int *out_channels)
{
  int ct = PNG_COLOR_TYPE_RGB;
  int ch = 3;
  switch (pf)
  {
  case 6: /* gray  */
    ct = PNG_COLOR_TYPE_GRAY;
    ch = 1;
    break;
  case 7: /* rgba  */
    ct = PNG_COLOR_TYPE_RGBA;
    ch = 4;
    break;
  case 8: /* bgra  */
    ct = PNG_COLOR_TYPE_RGBA;
    ch = 4;
    break;
  case 9: /* abgr  */
    ct = PNG_COLOR_TYPE_RGBA;
    ch = 4;
    break;
  case 10: /* argb  */
    ct = PNG_COLOR_TYPE_RGBA;
    ch = 4;
    break;
  default: /* rgb/x */
    ct = PNG_COLOR_TYPE_RGB;
    ch = 3;
    break;
  }
  *out_color_type = ct;
  *out_channels = ch;
}

int32_t ik_png_encode_from_pixels_ex(
    const uint8_t *pixels,
    int32_t width, int32_t pitch, int32_t height,
    int32_t pf,
    int32_t compression_level, /* 0..9 */
    int32_t filter_mask,       /* e.g. PNG_ALL_FILTERS (0x1F) */
    int32_t interlace,         /* 0 or 1 */
    uint8_t **out_png, int64_t *out_len,
    uint8_t *err, int32_t err_len)
{
  if (!pixels || width <= 0 || height <= 0 || pitch <= 0 || !out_png || !out_len)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }

  int color_type = PNG_COLOR_TYPE_RGB;
  int channels = 3;
  pf_to_png(pf, &color_type, &channels);

  png_structp png_ptr = NULL;
  png_infop info_ptr = NULL;
  png_bytep *rows = NULL;
  struct MemW sink = {0};
  int32_t rc = 0;

  /* rows point into input buffer, no copy */
  rows = (png_bytep *)malloc(sizeof(png_bytep) * (size_t)height);
  if (!rows)
  {
    set_err(err, err_len, "oom");
    rc = -2;
    goto done;
  }
  for (int32_t y = 0; y < height; ++y)
  {
    rows[y] = (png_bytep)(pixels + (size_t)y * (size_t)pitch);
  }

  png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  if (!png_ptr)
  {
    set_err(err, err_len, "png_create_write_struct failed");
    rc = -3;
    goto done;
  }
  info_ptr = png_create_info_struct(png_ptr);
  if (!info_ptr)
  {
    set_err(err, err_len, "png_create_info_struct failed");
    rc = -4;
    goto done;
  }

  if (setjmp(png_jmpbuf(png_ptr)))
  {
    set_err(err, err_len, "libpng error");
    rc = -5;
    goto done;
  }

  png_set_write_fn(png_ptr, &sink, mem_write_data, mem_flush);

  const int bit_depth = 8;
  png_set_IHDR(png_ptr, info_ptr,
               (png_uint_32)width, (png_uint_32)height,
               bit_depth, color_type,
               interlace ? PNG_INTERLACE_ADAM7 : PNG_INTERLACE_NONE,
               PNG_COMPRESSION_TYPE_BASE,
               PNG_FILTER_TYPE_BASE);

  /* clamp compression level to 0..9 */
  if (compression_level < 0)
    compression_level = 0;
  if (compression_level > 9)
    compression_level = 9;
  png_set_compression_level(png_ptr, compression_level);

  /* filter mask */
  png_set_filter(png_ptr, PNG_FILTER_TYPE_BASE, (int)filter_mask);

  /* NB: если вход не RGBA, а BGRA/ABGR/ARGB — можно переставить каналы заранее.
     Для чистоты/скорости делай это в Dart перед вызовом, либо добавь тут своп. */

  png_write_info(png_ptr, info_ptr);
  png_write_image(png_ptr, rows);
  png_write_end(png_ptr, info_ptr);

  *out_len = (int64_t)sink.size;
  *out_png = sink.buf; /* отдаём буфер наружу; освобождать через ik_png_free */
  sink.buf = NULL;
  sink.cap = sink.size = 0;
  set_err(err, err_len, NULL);

done:
  if (rows)
    free(rows);
  if (sink.buf)
    free(sink.buf);
  if (png_ptr || info_ptr)
    png_destroy_write_struct(&png_ptr, &info_ptr);
  return rc;
}

/* ================= free ================= */

void ik_png_free(uint8_t *p)
{
  if (p)
    free(p);
}
