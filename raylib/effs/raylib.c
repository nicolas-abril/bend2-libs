// gralha-raylib: the C side of raylib.bend. Build flags (Homebrew raylib
// on macOS): -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib
// -framework Cocoa -framework IOKit -framework CoreVideo
// -framework CoreAudio -framework AudioToolbox

#include <raylib.h>

#define RL_MAX_TEX 64
#define RL_MAX_SND 32
#define RL_REPLYQ 64

static struct {
  int open;
  int w;
  int h;
  Texture2D tex[RL_MAX_TEX];
  int ntex;
  Sound snd[RL_MAX_SND];
  int nsnd;
  Font font;
  int font_ok;
  u32 replyq[RL_REPLYQ];
  u32 rq_h;
  u32 rq_t;
} rl;

static void rl_drop(u64 v) {
  (void)v;
  if (!rl.open) {
    return;
  }
  for (int i = 0; i < rl.nsnd; i++) {
    UnloadSound(rl.snd[i]);
  }
  for (int i = 0; i < rl.ntex; i++) {
    UnloadTexture(rl.tex[i]);
  }
  if (rl.font_ok) {
    UnloadFont(rl.font);
    rl.font_ok = 0;
  }
  rl.ntex = 0;
  rl.nsnd = 0;
  CloseAudioDevice();
  CloseWindow();
  rl.open = 0;
}

static void rl_reply(u32 v) {
  if (rl.rq_t - rl.rq_h < RL_REPLYQ) {
    rl.replyq[rl.rq_t++ & (RL_REPLYQ - 1)] = v;
  }
}

// consume a List<U32> into a malloc'd u32 buffer
static u32* rl_words(Env e, Term t, u64* len) {
  u64 n = 0;
  u64 cap = 256;
  u32* p = io_mem(malloc(cap * sizeof(u32)));
  while (term_aux(t) == CID(Con)) {
    Term f[2];
    spare_free(e, cls_fit(2), ctr_take(e, t, 2, f));
    if (n == cap) {
      cap *= 2;
      p = io_mem(realloc(p, cap * sizeof(u32)));
    }
    p[n++] = (u32)f[0];
    t = f[1];
  }
  *len = n;
  return p;
}

static Term rl_nil(void) {
  return term_pak(CID(Nil), 0);
}

static Term rl_cons(Env e, Term h, Term t) {
  return io_node(e, CID(Con), h, t);
}

static Term rl_unit(void) {
  return term_pak(CID(Unit), 0);
}

static void* rl_alloc(void* p, size_t n) { return io_mem(p ? realloc(p, n) : malloc(n)); }
static void rl_exit(void) { rl_drop(0); }


static Color rl_col(u32 w) {
  Color c;
  c.r = (unsigned char)(w >> 16);
  c.g = (unsigned char)(w >> 8);
  c.b = (unsigned char)w;
  c.a = (unsigned char)(w >> 24);
  if (c.a == 0) {
    c.a = 255;
  }
  return c;
}

// words -> NUL-terminated ascii scratch (meta ops carry text/paths)
static void rl_text_of(const u32* ws, u32 n, char* out, u32 cap) {
  u32 m = 0;
  for (u32 j = 0; j < n && m + 1 < cap; j++) {
    out[m++] = ws[j] < 128 ? (char)ws[j] : '?';
  }
  out[m] = 0;
}

static Term rl_window(Env st, Term title, Term wT, Term hT) {
  if (rl.open) {
    term_drop(st, title);
    err_fail("raylib: window already open");
  }
  u64 tlen = 0;
  char* t = io_cstr(st, title, &tlen);
  int w = (int)(u32)wT;
  int h = (int)(u32)hT;
  SetTraceLogLevel(LOG_WARNING);
  InitWindow(w, h, t);
  free(t);
  if (!IsWindowReady()) {
    err_fail("raylib: window failed to open");
  }
  SetExitKey(KEY_NULL);  // ESC is a UI key here, never "quit the app"
  InitAudioDevice();
  rl.open = 1;
  rl.w = w;
  rl.h = h;
  atexit(rl_exit);
  return rl_unit();
}

// meta ops (20+). Each returns the count of words it consumed after
// the opcode, or 0xFFFFFFFF on a malformed tail (stops the walk).
static u32 rl_meta(u32 op, const u32* c, u64 left) {
  char txt[1024];
  if (op == 20) {  // texture upload: w h n byte*n -> reply id
    if (left < 3 || left < 3 + (u64)c[2]) {
      return 0xFFFFFFFF;
    }
    u32 w = c[0];
    u32 h = c[1];
    u32 n = c[2];
    if (rl.ntex >= RL_MAX_TEX || (u64)w * h * 4 != n) {
      rl_reply(0xFFFFFFFF);
      return 3 + n;
    }
    unsigned char* px = (unsigned char*)rl_alloc(NULL, n);
    for (u32 j = 0; j < n; j++) {
      px[j] = (unsigned char)c[3 + j];
    }
    Image img;
    img.data = px;
    img.width = (int)w;
    img.height = (int)h;
    img.mipmaps = 1;
    img.format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
    rl.tex[rl.ntex] = LoadTextureFromImage(img);
    free(px);
    rl_reply((u32)rl.ntex);
    rl.ntex++;
    return 3 + n;
  }
  if (op == 21) {  // sound upload: n byte*n -> reply id
    if (left < 1 || left < 1 + (u64)c[0]) {
      return 0xFFFFFFFF;
    }
    u32 n = c[0];
    if (rl.nsnd >= RL_MAX_SND || n == 0) {
      rl_reply(0xFFFFFFFF);
      return 1 + n;
    }
    unsigned char* sm = (unsigned char*)rl_alloc(NULL, n);
    for (u32 j = 0; j < n; j++) {
      sm[j] = (unsigned char)c[1 + j];
    }
    Wave wv;
    wv.frameCount = n;
    wv.sampleRate = 22050;
    wv.sampleSize = 8;
    wv.channels = 1;
    wv.data = sm;
    rl.snd[rl.nsnd] = LoadSoundFromWave(wv);
    free(sm);
    rl_reply((u32)rl.nsnd);
    rl.nsnd++;
    return 1 + n;
  }
  if (op == 22) {  // ui font from ttf path -> reply 0/1
    if (left < 1 || left < 1 + (u64)c[0]) {
      return 0xFFFFFFFF;
    }
    rl_text_of(c + 1, c[0], txt, sizeof(txt));
    u32 ok = 0;
    if (!rl.font_ok && FileExists(txt)) {
      rl.font = LoadFontEx(txt, 48, NULL, 0);
      if (rl.font.texture.id != 0) {
        SetTextureFilter(rl.font.texture, TEXTURE_FILTER_BILINEAR);
        rl.font_ok = 1;
        ok = 1;
      }
    }
    rl_reply(ok);
    return 1 + c[0];
  }
  if (op == 23) {  // clipboard: n cp*n
    if (left < 1 || left < 1 + (u64)c[0]) {
      return 0xFFFFFFFF;
    }
    rl_text_of(c + 1, c[0], txt, sizeof(txt));
    SetClipboardText(txt);
    return 1 + c[0];
  }
  if (op == 24) {  // screenshot: n cp*n
    if (left < 1 || left < 1 + (u64)c[0]) {
      return 0xFFFFFFFF;
    }
    rl_text_of(c + 1, c[0], txt, sizeof(txt));
    TakeScreenshot(txt);
    return 1 + c[0];
  }
  if (op == 25) {  // shutdown
    rl_drop(0);
    return 0;
  }
  if (op == 26) {  // query should-close -> reply 0/1
    rl_reply(rl.open && WindowShouldClose() ? 1 : 0);
    return 0;
  }
  if (op == 27) {  // query text width: size n cp*n -> reply px
    if (left < 2 || left < 2 + (u64)c[1]) {
      return 0xFFFFFFFF;
    }
    rl_text_of(c + 2, c[1], txt, sizeof(txt));
    int wpx = 0;
    if (rl.font_ok) {
      Vector2 v = MeasureTextEx(rl.font, txt, (float)c[0], 0.0f);
      wpx = (int)v.x;
    } else {
      wpx = MeasureText(txt, (int)c[0]);
    }
    rl_reply((u32)wpx);
    return 2 + c[1];
  }
  return 0xFFFFFFFF;
}

// one command list -> draws presented, meta ops applied. A list that
// is only meta ops (a query, an upload) presents nothing: BeginDrawing
// happens lazily at the first DRAW op.
static Term rl_blit(Env st, Term cmds) {
  if (!rl.open) {
    term_drop(st, cmds);
    err_fail("raylib: no window (call open first)");
  }
  u64 n = 0;
  u32* c = rl_words(st, cmds, &n);
  int drawing = 0;
  u64 i = 0;
  while (i < n) {
    u32 op = c[i];
    if (op >= 20) {
      u32 used = rl_meta(op, c + i + 1, n - i - 1);
      if (used == 0xFFFFFFFF) {
        break;
      }
      i += 1 + used;
      if (!rl.open) {
        break;  // op 25 closed the window
      }
      continue;
    }
    if (!drawing) {
      BeginDrawing();
      drawing = 1;
    }
    if (op == 0 && i + 2 <= n) {
      ClearBackground(rl_col(c[i + 1]));
      i += 2;
    } else if (op == 1 && i + 6 <= n) {
      DrawRectangle((int)c[i + 1], (int)c[i + 2], (int)c[i + 3], (int)c[i + 4], rl_col(c[i + 5]));
      i += 6;
    } else if (op == 2 && i + 6 <= n) {
      DrawRectangleLines((int)c[i + 1], (int)c[i + 2], (int)c[i + 3], (int)c[i + 4], rl_col(c[i + 5]));
      i += 6;
    } else if (op == 3 && i + 6 <= n) {
      u32 len = c[i + 5];
      if (i + 6 + len > n) {
        break;
      }
      char txt[512];
      u32 m = 0;
      for (u32 j = 0; j < len && m < 511; j++) {
        u32 cp = c[i + 6 + j];
        txt[m++] = cp < 128 ? (char)cp : '?';
      }
      txt[m] = 0;
      if (rl.font_ok) {
        Vector2 tp = {(float)(int)c[i + 1], (float)(int)c[i + 2]};
        DrawTextEx(rl.font, txt, tp, (float)(int)c[i + 3], 0.0f, rl_col(c[i + 4]));
      } else {
        DrawText(txt, (int)c[i + 1], (int)c[i + 2], (int)c[i + 3], rl_col(c[i + 4]));
      }
      i += 6 + len;
    } else if (op == 4 && i + 5 <= n) {
      DrawCircle((int)c[i + 1], (int)c[i + 2], (float)(int)c[i + 3], rl_col(c[i + 4]));
      i += 5;
    } else if (op == 5 && i + 6 <= n) {
      DrawLine((int)c[i + 1], (int)c[i + 2], (int)c[i + 3], (int)c[i + 4], rl_col(c[i + 5]));
      i += 6;
    } else if (op == 6 && i + 11 <= n) {
      u32 id = c[i + 1];
      if (id < (u32)rl.ntex) {
        float sx = (float)(int)c[i + 2];
        float sy = (float)(int)c[i + 3];
        float sw = (float)(int)c[i + 4];
        float sh = (float)(int)c[i + 5];
        float scale = (float)c[i + 8] / 256.0f;
        Rectangle src = {sx, sy, (c[i + 9] & 1) != 0 ? -sw : sw, sh};
        Rectangle dst = {(float)(int)c[i + 6], (float)(int)c[i + 7], sw * scale, sh * scale};
        Vector2 org = {0.0f, 0.0f};
        DrawTexturePro(rl.tex[id], src, dst, org, 0.0f, rl_col(c[i + 10]));
      }
      i += 11;
    } else if (op == 7 && i + 2 <= n) {
      u32 id = c[i + 1];
      if (id < (u32)rl.nsnd) {
        PlaySound(rl.snd[id]);
      }
      i += 2;
    } else {
      break;
    }
  }
  free(c);
  if (drawing) {
    EndDrawing();
  }
  return rl_unit();
}

// the return wire: pending query replies first (drained whole), else
// the packed input poll (see README.md)
static Term rl_events(Env st) {
  Term list = rl_nil();
  if (rl.rq_t != rl.rq_h) {
    while (rl.rq_t != rl.rq_h) {
      list = rl_cons(st, rl.replyq[--rl.rq_t & (RL_REPLYQ - 1)], list);
    }
    rl.rq_h = 0;
    rl.rq_t = 0;
    return list;
  }
  if (!rl.open) {
    return list;
  }
  u32 evs[128];
  u32 nev = 0;
  int cp;
  while ((cp = GetCharPressed()) != 0 && nev < 64) {
    evs[nev++] = 0x20000000u | (u32)cp;
  }
  int key;
  while ((key = GetKeyPressed()) != 0 && nev < 128) {
    evs[nev++] = 0x10000000u | (u32)key;
  }
  for (u32 j = nev; j > 0; j--) {
    list = rl_cons(st, (evs[j - 1]), list);
  }
  Vector2 mp = GetMousePosition();
  int mx = (int)mp.x;
  int my = (int)mp.y;
  mx = mx < 0 ? 0 : mx >= rl.w ? rl.w - 1 : mx;
  my = my < 0 ? 0 : my >= rl.h ? rl.h - 1 : my;
  u32 mouse = (u32)mx | ((u32)my << 12);
  mouse |= IsMouseButtonDown(MOUSE_BUTTON_LEFT) ? 1u << 24 : 0;
  mouse |= IsMouseButtonDown(MOUSE_BUTTON_RIGHT) ? 1u << 25 : 0;
  mouse |= IsMouseButtonPressed(MOUSE_BUTTON_LEFT) ? 1u << 26 : 0;
  mouse |= IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) ? 1u << 27 : 0;
  u32 held = 0;
  held |= IsKeyDown(KEY_LEFT) ? 1u << 0 : 0;
  held |= IsKeyDown(KEY_RIGHT) ? 1u << 1 : 0;
  held |= IsKeyDown(KEY_UP) ? 1u << 2 : 0;
  held |= IsKeyDown(KEY_DOWN) ? 1u << 3 : 0;
  held |= IsKeyDown(KEY_W) ? 1u << 4 : 0;
  held |= IsKeyDown(KEY_A) ? 1u << 5 : 0;
  held |= IsKeyDown(KEY_S) ? 1u << 6 : 0;
  held |= IsKeyDown(KEY_D) ? 1u << 7 : 0;
  held |= IsKeyDown(KEY_SPACE) ? 1u << 8 : 0;
  held |= (IsKeyDown(KEY_LEFT_SHIFT) || IsKeyDown(KEY_RIGHT_SHIFT)) ? 1u << 9 : 0;
  held |= IsKeyDown(KEY_ENTER) ? 1u << 10 : 0;
  held |= IsKeyDown(KEY_ESCAPE) ? 1u << 11 : 0;
  held |= IsKeyDown(KEY_TAB) ? 1u << 12 : 0;
  held |= IsKeyDown(KEY_E) ? 1u << 13 : 0;
  held |= IsKeyDown(KEY_Q) ? 1u << 14 : 0;
  held |= IsKeyDown(KEY_I) ? 1u << 15 : 0;
  held |= IsKeyDown(KEY_C) ? 1u << 16 : 0;
  held |= IsKeyDown(KEY_H) ? 1u << 17 : 0;
  held |= IsKeyDown(KEY_X) ? 1u << 18 : 0;
  held |= IsKeyDown(KEY_BACKSPACE) ? 1u << 19 : 0;
  list = rl_cons(st, (mouse), list);
  list = rl_cons(st, (held), list);
  return list;
}

static Term rl_open_run(Env e, Term* f, IoWork* w) {
  return rl_window(e, f[0], f[1], f[2]);
}

static Term rl_send_run(Env e, Term* f, IoWork* w) {
  return rl_blit(e, f[0]);
}

static Term rl_poll_run(Env e, Term* f, IoWork* w) {
  return rl_events(e);
}

static void __attribute__((constructor)) rl_effects(void) {
#ifdef CID(open)
  io_eff(CID(open), rl_open_run);
#endif
#ifdef CID(send)
  io_eff(CID(send), rl_send_run);
#endif
#ifdef CID(poll)
  io_eff(CID(poll), rl_poll_run);
#endif
}
