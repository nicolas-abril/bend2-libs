// Open a named output once, or use stdout for the tar "-" spelling.
function output_open(path) {
  try {
    const fd = path === "/dev/stdout"
      ? 1
      : require("fs").openSync(path, "w", 0o644);
    return io_done(fd);
  } catch (e) {
    return io_fail(Math.abs(e.errno ?? 5));
  }
}

io_eff(CID(open_out_raw), output_open);
