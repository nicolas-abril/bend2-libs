# gralha-http-core

HTTP/1.1 messages in pure Bend: request parsing and response serialization,
headers, status reasons, targets and query strings, UTF-8 byte counts. No
IO and no foreign code, so it runs on every lane and checks with `--verdict`.
`gralha-http-server` reads requests from sockets with it.

    import gralha-http-core@0.1.0.0/http.bend as Http

- Types: `Header{name, value}`, `Request{method, target, version, headers,
  body}`, `Response{status, headers, body}`.
- Requests: `request.parse(text)` (`None` until the head is whole or when
  it is malformed), `request.complete(text)` (head ended and Content-Length
  bytes arrived), `request.method`, `request.target`, `request.path`,
  `request.body`, `request.header(r, name)`, `request.query(r, name)`,
  `request.is(r, "GET", "/path")`.
- Headers: `header.get(headers, name)` and `header.has` (any case),
  `header.parse`, `header.text`, `content.length`.
- Targets: `target.path`, `target.query`, `query.get(query, name)`,
  `url.decode` (`%XX` and `+`, read as UTF-8).
- Responses: `ok(content_type, body)`, `response(status, content_type,
  body)`, `status(code)` (the reason phrase as a plain-text body),
  `response.with(r, name, value)` (appends a header), `response.text(r)`
  (adds Content-Length in UTF-8 bytes unless present), `head(status,
  headers)` (status line and headers, for a body sent separately),
  `reason(code)`.
- Also `utf8.length`, `utf8.decode`, and `when`, a lazy two-way branch.

The request body is everything after the blank line; a pipelined second
request stays in it. Laws: `ok_is_200`, `with_keeps_status`.

Depends on: Base only. Tests: `tests/check.bend` (run from this directory).
