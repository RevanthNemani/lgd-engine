source("./sources/libraries.R")
source("./sources/helpers.R")
source("./sources/lgdFunctions.R")

.api.env <- .GetEnvironmentVars()

if (.api.env$env == "dev") {
  host <- .api.env$dev.host
  port <- .api.env$dev.port
}

if (.api.env$env == "test") {
  host <- .api.env$test.host
  port <- .api.env$test.port
}

if (.api.env$env == "prod") {
  host <- .api.env$prod.host
  port <- .api.env$prod.port
}

pr <- plumb("./sources/lgdAPIs.R")

pr$registerHook("exit", function(){
  print("Shutting down APIs...")
})

pr$run(host = host, port = as.numeric(port))

