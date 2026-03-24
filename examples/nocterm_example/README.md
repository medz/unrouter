# Nocterm Unrouter Example

Runnable terminal example app for `nocterm_unrouter`.

## Run

```bash
cd examples/nocterm_example
dart pub get
dart run
```

## Shortcuts

- `1`: open the nested docs route rendered via `Outlet`
- `2`: open the named profile route with params, query, and state
- `b`: go back
- `h`: return home
- `q`: quit

## Key Files

- `lib/nocterm_example.dart`: router setup and the terminal app shell
- `bin/nocterm_example.dart`: runnable entrypoint
- `test/nocterm_example_test.dart`: navigation smoke test
