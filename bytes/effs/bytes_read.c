// Bytes
// =====

// The whole file as a Bytes value: a balanced tree of packed four-byte
// word leaves over the next power of two, with zero leaves standing in for
// the unused tail, plus the byte count and that capacity. Built here so no
// Bend-side conversion touches every byte. io_node and io_seal seal a field
// exactly when the program shares values of the constructor's type.
static Term gralha_bytes_read_tree(Env e, const uint8_t* p, u64 n, u64 lo, u64 cap) {
  if (lo >= n) {
    return term_pak(CID(ByteFlat), 0);
  }
  if (cap <= 4) {
    u64 word = 0;
    for (u64 k = 0; k < cap && lo + k < n; k += 1) {
      word |= (u64)p[lo + k] << (8 * k);
    }
    return term_pak(CID(ByteWord), word);
  }
  u64 half = cap / 2;
  Term left = gralha_bytes_read_tree(e, p, n, lo, half);
  Term right = gralha_bytes_read_tree(e, p, n, lo + half, half);
  return io_node(e, CID(ByteNode), left, right);
}

static Term gralha_bytes_read_run(Env e, Term* f, IoWork* w) {
  u64 n = 0;
  char* path = io_cstr(e, f[0], &n);
  FILE* fp = io_nul(path, n) ? NULL : fopen(path, "rb");
  if (fp == NULL) {
    free(path);
    return io_fail(e, errno != 0 ? (u32)errno : ENOENT, NULL);
  }
  free(path);
  u64 cap = 1 << 16;
  u64 len = 0;
  uint8_t* buf = io_mem(malloc(cap));
  for (;;) {
    if (len == cap) {
      cap *= 2;
      buf = io_mem(realloc(buf, cap));
    }
    size_t got = fread(buf + len, 1, cap - len, fp);
    if (got == 0) {
      break;
    }
    len += got;
  }
  fclose(fp);
  u64 size = 1;
  while (size < len) {
    size *= 2;
  }
  Term tree = gralha_bytes_read_tree(e, buf, len, 0, size);
  free(buf);
  u64 l = heap_alloc(e, 2);
  e.mem[l]     = io_seal(e, tree, CID(Bytes));
  e.mem[l + 1] = (Term)len;
  e.mem[l + 2] = (Term)size;
  return io_done(e, term_ctr(CID(Bytes), l));
}

static void __attribute__((constructor)) gralha_bytes_read_use(void) {
  io_eff(CID(bytes.read.raw), gralha_bytes_read_run);
}
