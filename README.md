# Ena Compile API

HTTP API for compiling and executing [Ena](https://github.com/ena-lang/ena) code.

## Build

```bash
docker build -t ena-api .
```

## Run

```bash
docker run -p 8080:8080 ena-api
```

## Usage

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"code": "function main() { return 1 + 2 }"}' \
  localhost:8080/compile
```

Response:

```json
{"status": "success", "body": {"result": 3, "output": {}}}
```

## Security

Shell commands are blocked for security reasons.
