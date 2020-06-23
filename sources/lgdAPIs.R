if (.api.env$env == "dev") {
  x.api.key <- .api.env$dev.secret
}

if (.api.env$env == "test") {
  x.api.key <- .api.env$test.secret
}

if (.api.env$env == "prod") {
  x.api.key <- .api.env$prod.secret
}

#* @filter cors
cors <- function(res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  plumber::forward()
}

#* Log some information about the incoming request
#* @filter logger
function(req) {
  cat(
    as.character(Sys.time()),
    "-",
    req$REQUEST_METHOD,
    req$PATH_INFO,
    "-",
    req$HTTP_USER_AGENT,
    "@",
    req$REMOTE_ADDR,
    "\n"
  )
  plumber::forward()
}

#* LGD API
#* @json
#* @param inputData Input ECL dataset
#* @param collateralData collateral dataset
#* @post /lgd
function(req, res) {
  if (req$HTTP_X_API_KEY != x.api.key) {
    res$status <- 401 # Unauthorized
    return(list(error = "Authentication required"))
  }

  payload <- jsonlite::fromJSON(req$postBody, flatten = T)

  future(
    lgd(
      input.data = payload$inputData,
      collateral.data = payload$collateralData,
      wholesale.haircuts = payload$wholesaleHaircuts,
      retail.haircuts = payload$retailHaircuts
    )
  ) %...>% (function(df) {
    return(df)
  }) %...!% (function(err) {
    return(err)
  })
}

#* weighted Average APIs
#* @serializer unboxedJSON
#* @param inputData
#* @post /lgd/weighted-average
function(req, res) {
  if (req$HTTP_X_API_KEY != x.api.key) {
    res$status <- 401 # Unauthorized
    return(list(error = "Authentication required"))
  }

  payload <- jsonlite::fromJSON(req$postBody, flatten = T)

  input.data <- payload$inputData

  output <- list(
    complete = weighted.mean(input.data$LGD, input.data$EXPOSURE),
    wholesale =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("COR",
                                                           "CNR",
                                                           "SNR",
                                                           "SOR",
                                                           "COB",
                                                           "SOB"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("COR",
                                                           "CNR",
                                                           "SNR",
                                                           "SOR",
                                                           "COB",
                                                           "SOB"),]$EXPOSURE),
    wholesaleOnBalanceSheet =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("COR",
                                                           "CNR",
                                                           "SNR",
                                                           "SOR"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("COR",
                                                           "CNR",
                                                           "SNR",
                                                           "SOR"),]$EXPOSURE),
    wholesaleOffBalanceSheet =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("COB",
                                                           "SOB"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("COB",
                                                           "SOB"),]$EXPOSURE),
    retail =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("RET",
                                                           "CCR"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("RET",
                                                           "CCR"),]$EXPOSURE),
    banksAndSovereigns =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("BNK",
                                                           "SVR"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("BNK",
                                                           "SVR"),]$EXPOSURE),
    cor =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("COR"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("COR"),]$EXPOSURE),
    cnr =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("CNR"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("CNR"),]$EXPOSURE),
    cob =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("COB"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("COB"),]$EXPOSURE),
    smr =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("SMR"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("SMR"),]$EXPOSURE),
    snr =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("SNR"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("SNR"),]$EXPOSURE),
    sob =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("SOB"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("SOB"),]$EXPOSURE),
    ret =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("RET"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("RET"),]$EXPOSURE),
    ccr =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("CCR"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("CCR"),]$EXPOSURE),
    bnk =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("BNK"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("BNK"),]$EXPOSURE),
    svr =
      weighted.mean(input.data[input.data$IFRS_SECT %in% c("SVR"),]$LGD,
                    input.data[input.data$IFRS_SECT %in% c("SVR"),]$EXPOSURE)
  )

  return(output)
}
