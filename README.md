## Compile API for Lua

### Build docker image

`docker build -t my-api-resty .`

### Run docker image

`docker run -p 8080:8080 my-api-resty`

### Test the endpoint

`curl -X POST -H "Content-Type: application/json" -d '{"code": "function main () {return 1}"}' localhost:8080/compile`

### Disclaimer

This API doesn't support shell execution for security reasons.