lgd <-
  function(input.data,
           collateral.data,
           wholesale.haircuts,
           retail.haircuts,
           lgd.floor.rate = .10,
           non.collateralised.lgd = .45) {
    # summarising collaterals after reducing the haircut values based on CIF----
    coll.summary <-
      merge(
        collateral.data,
        wholesale.haircuts,
        by.x = "securityType",
        by.y = "collateralType",
        all.x = T,
        all.y = F
      ) %>% transmute(
        cif = cif,
        customerName = customerName,
        endUse = endUse,
        securityType = securityType,
        value = value,
        `1-haircut` = `1-Haircut`,
        useableValue = (value * `1-haircut`)
      ) %>% group_by(cif) %>% summarise(useableValue = sum(useableValue))

    # Dividing data based on different LGD segments-----------------------------

    ## Corporate and SME segments
    input.whs <-
      input.data %>% filter(IFRS_SECT %in% c("COR", "SMR",
                                             "COB", "SOB",
                                             "CNR", "SNR"))

    ## Retail (excluding Credit Cards)
    input.ret <- input.data %>% filter(IFRS_SECT %in% c("RET"))

    ## Credit Cards
    input.ccr <- input.data %>% filter(IFRS_SECT %in% c("CCR"))

    ## Banks and Sovereigns
    input.bns <-
      input.data %>% filter(IFRS_SECT %in% c("BNK", "SVR"))

    # Corporate and SME segments LGD calculation--------------------------------

    ## EAD summary by cif for prorata allocation of collaterals
    input.whs.outstanding.summary <-
      input.whs %>% group_by(CUSTOMER_ID) %>% summarise(cifExposure =
                                                          sum(EXPOSURE))

    ## Adding EAD summary by cif to it's data based on CIFs
    input.whs <-
      merge(
        input.whs,
        input.whs.outstanding.summary,
        by = "CUSTOMER_ID",
        all.x = T,
        all.y = F
      )
    rm(input.whs.outstanding.summary)
    ## Calculating EAD ratio (prep for prorata collateral allocation)
    input.whs$eadRatio <- input.whs$EXPOSURE / input.whs$cifExposure

    ## Calculating useable value
    input.whs <-
      merge(
        input.whs,
        coll.summary,
        by.x = "CUSTOMER_ID",
        by.y = "cif",
        all.x = T,
        all.y = F
      ) %>% mutate(useableValue = (eadRatio * useableValue))
    input.whs <- input.whs %>% mutate(useableValue =
                                        ifelse(is.na(useableValue),
                                               0,
                                               useableValue))
    rm(coll.summary)
    ## Calculating recovery amount
    input.whs$recovery <-
      pmin(input.whs$EXPOSURE, input.whs$useableValue)

    ## Discounting Recovery amount
    input.whs <-
      input.whs %>% mutate(discountFactor = 1 / ((1 + (PROFIT_RATE)) ^ 3))
    input.whs$discountedRecovery <-
      input.whs$recovery * input.whs$discountFactor

    ## Calculating Recovery Rate form discounted recovery amount
    input.whs <-
      input.whs %>% mutate(recoveryRate = discountedRecovery / EXPOSURE)
    input.whs <-
      input.whs %>% mutate(recoveryRate = ifelse(is.na(recoveryRate),
                                                 0,
                                                 recoveryRate))

    ## Calculating LGD
    input.whs <-
      input.whs %>% mutate(LGD = pmax(1 - recoveryRate, lgd.floor.rate))

    # Retail (excluding Credit Cards) LGD calculation---------------------------

    ## Extracting product codes
    input.ret$prodCode <-
      substr(input.ret$PRODUCT, start = 1, stop = 4)

    ## Calculating useable value
    input.ret <-
      merge(
        input.ret,
        retail.haircuts,
        by = "prodCode",
        all.x = T,
        all.y = F
      ) %>% mutate(useableValue = EXPOSURE * `useableCollateral%`)

    ## Calculating recovery amount
    input.ret$recovery <-
      pmin(input.ret$EXPOSURE, input.ret$useableValue)

    ## Discounting Recovery amount
    input.ret <-
      input.ret %>% mutate(discountFactor = 1 / ((1 + (PROFIT_RATE)) ^ 3))
    input.ret$discountedRecovery <-
      input.ret$recovery * input.ret$discountFactor

    ## Calculating Recovery Rate form discounted recovery amount
    input.ret <-
      input.ret %>% mutate(recoveryRate = discountedRecovery / EXPOSURE)
    input.ret <-
      input.ret %>% mutate(recoveryRate = ifelse(is.na(recoveryRate),
                                                 0,
                                                 recoveryRate))

    ## Calculating LGD
    input.ret <-
      input.ret %>% mutate(LGD = pmax(1 - recoveryRate, lgd.floor.rate))

    # Credit cards LGD calculation----------------------------------------------
    input.ccr$LGD <- non.collateralised.lgd

    # Banks and Sovereigns LGD calculation--------------------------------------
    input.bns$LGD <- lgd.floor.rate

    # Cleaning up memory
    rm(retail.haircuts,
       wholesale.haircuts)

    # binding the data together for output--------------------------------------
    input.column.names <- colnames(input.data)
    output <- rbind(input.whs[c(input.column.names)],
                    input.ret[c(input.column.names)],
                    input.ccr[c(input.column.names)],
                    input.bns[c(input.column.names)])

    data.row.count.check <- nrow(input.data) == nrow(output)

    if (data.row.count.check == F) {
      return('{ "processSuccess": 0, "reason": "data row count check failed" }')
    }

    # Cleaning up memory
    rm(input.data,
       data.row.count.check,
       input.column.names)

    # Returning Output after LGD calculation-------------------------------------
    return(output)

  }



