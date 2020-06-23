# LGD Engine

- [LGD Engine](#lgd-engine)
  - [Add Renviron file](#add-renviron-file)
  - [API Documentation](#api-documentation)
  - [LGD models and methodologies](#lgd-models-and-methodologies)
    - [Introduction](#introduction)
    - [Corporate and SME LGD model](#corporate-and-sme-lgd-model)
    - [Retail (excluding Credit Cards) LGD model](#retail-excluding-credit-cards-lgd-model)
    - [Credit Cards LGD model](#credit-cards-lgd-model)
    - [Banks and Sovereigns LGD model](#banks-and-sovereigns-lgd-model)
    - [Conclusion](#conclusion)

## Add Renviron file

```{}
env="dev"

dev.host="0.0.0.0"
dev.port=3005
dev.secret="Secret"

test.host="0.0.0.0"
test.port=3006
test.secret="Secret"

prod.host="0.0.0.0"
prod.port=3010
prod.secret="Secret"
```

## API Documentation

[https://documenter.getpostman.com/view/9006400/SzzobbXD?version=latest](https://documenter.getpostman.com/view/9006400/SzzobbXD?version=latest)

## LGD models and methodologies

### Introduction

Loss given default (LGD) is the amount of money we as a bank lose when a borrower defaults on a loan, depicted as a percentage of total exposure at the time of default.

The simple formula for LGD is as follows:

$$LGD = 1 - Recovery\ Rate$$

So the goal is to arrive at the recovery rates for each contract we have.

In case we have LGD lower than 10%, we have taken 10% as the floor rate as prescribed by BASEL II *paragraph 266*. Even though this is only for retail exposures secured by residential properties, we have applied this floor rate across the portfolio when our LGD estimates fall below 10% as a prudential step.

So at alizz islamic bank our LGD formula is as follows in most cases:

$$LGD = max(1 - Recovery\ Rate, 10\%)$$

### Corporate and SME LGD model

Most of our Corporate and SME customers have collaterals in place which could be used to recover our exposures as a last resort. Due to lack of enough past recovery data all models involving techniques like regression would fail in this segment at our bank. So we have taken a logical and expert judgement route to arrive at recovery rate for each contract in our portfolio. Care has been taken to keep it simple and mathematical at every chance.

We have observed that it would take on average three (3) years to recover our exposures after default of an account incase they are not cured. So we are using a discounting period of 3 years to arrive at the discounted useable collateral value (after haircut).

At alizz islamic bank we recognize the following collaterals for the purposes of recovery/LGD. Their corresponding $1-Haircut\%$ are also listed in the table below:

| Recognised Collateral Types | 1-Haircut | Description                             |
| --------------------------- | --------- | --------------------------------------- |
| Building                    | 70%       | Building                                |
| Land                        | 80%       | Land                                    |
| Deposit                     | 100%      | Cash Deposit                            |
| MotorVehicle                | 50%       | Motor Vehicle                           |
| PersonalGuarantees          | 70%       | Personal Guarantees on exposure         |
| CorporateGuarantee          | 50%       | Corporate Guarantees on exposure        |
| LocalGovtGuarantee          | 80%       | Local Government Guarantees on exposure |
| GeneralPlantMachinery       | 50%       | General Plant and machinery             |
| QuotedShares                | 70%       | Listed Shares                           |
| NotQuotedShares             | 50%       | Non Listed Shares                       |

After applying haircuts we arrive at a customer level useable collateral values.

Eg: A customer has pledged 2 collaterals. One is Land with a valuation of OMR 1,000,000 and the second is a Building with a valuation of OMR 500,000 for all loans he has taken from alizz islamic bank. so the useable collateral value is as follows:

$$Useable\ collateral\ value = \\ (OMR\ \ 1,000,000\ *\ 80\%) + (OMR\ \ 500,000\ *\ 70\%)$$

$$Useable\ collateral\ value = OMR\ \ 1,150,000$$

Once we have the customer level useable collateral value, we apportion it to all the customer's contracts on a pro rata basis based on their Exposure at Default **(EAD)**.

We then arrive at the recovery amount. Recovery is the minimum of useable collateral value and Exposure at Default **(EAD)**.

$$Recovery\ Amount = min(EAD, useable\ collateral\ value)$$

This recovery amount is then discounted for 3 years using the contract's Effective Interest Rate.

$$Discounted\ Recovery = \frac{Recovery\ Amount}{1+(\frac{EIR}{100})^{3}}$$

Our Recovery Rate is the percentage of discounted recovery on exposure at default:

$$Recovery\ Rate = \frac{Discounted\ Recovery}{EAD} *100\%$$

And finally LGD:

$$LGD = max(1 - Recovery\ Rate, 10\%)$$

### Retail (excluding Credit Cards) LGD model

In retail we have fifty (50) products in place and for recovery amount we take a percentage of the Exposure at Default **(EAD)** based on the following table. This table has been made using expert judgement and industry best practices. Where industry best practices are not relevant or meeting our prudential needs, we have tweaked the useable collateral percentages to meet our prudential needs.

| Retail Products                          | Product Code | Useable Collateral % |
| ---------------------------------------- | ------------ | -------------------- |
| CL02-CL Goods Murabaha Finance- Retail   | CL02         | 10%                  |
| CL03-CL Property Murabaha Finance-Retail | CL03         | 90%                  |
| CL41-CL DM Finance - Retail              | CL41         | 10%                  |
| R101-Auto Murabaha Finance-Retail OC     | R101         | 75%                  |
| R102-Goods Murabaha Financing -Retail-OC | R102         | 10%                  |
| R103-Property Murabaha Finance-Retail-OC | R103         | 90%                  |
| R111-Auto Murabaha Finance-Staff-OC      | R111         | 75%                  |
| R112-Goods Murabaha Finance-Staff-OC     | R112         | 10%                  |
| R114-Property Murabaha Finance - Staff   | R114         | 90%                  |
| R201-Ijarah Finance - Retail -OC         | R201         | 90%                  |
| R202-Forward Ijarah Finance -Retail-OC   | R202         | 90%                  |
| R203-Service Ijarah Finance- Retail      | R203         | 90%                  |
| R204-Ijarah Finance FXD_PRIN-Retail-OC   | R204         | 90%                  |
| R211-Ijarah Finance - Staff -OC          | R211         | 90%                  |
| R212-Forward Ijarah Finance -Staff-OC    | R212         | 90%                  |
| R213-Service Ijarah Finance - Staff      | R213         | 90%                  |
| R301-IjarahFinance H_Taveover-Retail-OC  | R301         | 90%                  |
| R302-Ijarah Finance P_Takeover-Retail-OC | R302         | 90%                  |
| R311-Ijarah Finance H_Takeover Staff-OC  | R311         | 90%                  |
| R312-Ijarah Finance P_Takeover-Staff-OC  | R312         | 90%                  |
| R401-DM Property Finance-Retail          | R401         | 90%                  |
| R404-DM Land Finance -Retail             | R404         | 90%                  |
| R411-DM Property Finance - Staff         | R411         | 90%                  |
| R412-DM Personal Takeover - Staff        | R412         | 10%                  |
| R414-DM Land Finance -Staff              | R414         | 90%                  |
| R420-DM Under Construction -Retail       | R420         | 70%                  |
| R421-DM Under Construction -Staff        | R421         | 70%                  |
| RF01-Ijarah Finance - Retail             | RF01         | 90%                  |
| RF02-Forward Ijarah Finance - Retail     | RF02         | 90%                  |
| RF11-Ijarah Finance - Staff              | RF11         | 90%                  |
| RF12-Forward Ijarah Finance - Staff      | RF12         | 90%                  |
| RF15-Ijarah Finance H_Takeover -Staff    | RF15         | 90%                  |
| RF16-Ijarah Finance P_Takeover- Staff    | RF16         | 90%                  |
| RM01-Auto Murabaha Finance Mora-Retail   | RM01         | 75%                  |
| RM03-GoodsMurabaha Finance Mora-Retail   | RM03         | 10%                  |
| RM21-Ijarah Finance _Mora- Staff         | RM21         | 90%                  |
| RT01-Auto Murabaha Finance - Retail      | RT01         | 75%                  |
| RT02-Goods Murabaha Finance - Retail     | RT02         | 10%                  |
| RT03-Property Murabaha Finance-Retail    | RT03         | 90%                  |
| RT11-Auto Murabaha Finance-Staff         | RT11         | 75%                  |
| RT12-Goods Murabaha Finance- Staff       | RT12         | 10%                  |
| RT13-Property Murabaha Finance -Staff    | RT13         | 90%                  |
| CL01-CL Auto Finance - Retail            | CL01         | 75%                  |
| CL21-CL Ijarah Finance - Retail          | CL21         | 90%                  |
| CL42-DM Under Construction -CL           | CL42         | 70%                  |
| CL43-DM Land Finance -CL                 | CL43         | 90%                  |
| RF05-IjarahFinance H_Takeover-Retail     | RF05         | 90%                  |
| RF06-Ijarah Finance P_Takeover -Retail   | RF06         | 90%                  |
| CL22-CL Forward Ijarah Finance -Retail   | CL22         | 90%                  |
| R402-DM Personal Takeover -Retail        | R402         | 10%                  |

Eg: A retail customer has an Auto Murabaha, the recovery amount will be 75% of EAD.

$$Recovery\ Amount = EAD * Useable\ Collateral \%$$

This recovery amount is then discounted for 3 years using the contract's Effective Interest Rate.

$$Discounted\ Recovery = \frac{Recovery\ Amount}{1+(\frac{EIR}{100})^{3}}$$

Our Recovery Rate is the percentage of discounted recovery on exposure at default:

$$Recovery\ Rate = \frac{Discounted\ Recovery}{EAD} *100\%$$

And finally LGD:

$$LGD = max(1 - Recovery\ Rate, 10\%)$$

### Credit Cards LGD model

For credit cards we are using BASEL prescribed forty five percent (45%) LGD.

$$LGD = 45\%$$

### Banks and Sovereigns LGD model

Usually Banks and Sovereigns have low PDs (Probability of Defaults) and LGD (Loss Given Defaults), so we are using our floor rate LGD ten percent (10%).

$$LGD = 10\%$$

### Conclusion

To sum up:

| Segment     | LGD Formula                     |
| ----------- | ------------------------------- |
| Corporate   | $max(1 - Recovery\ Rate, 10\%)$ |
| SME         | $max(1 - Recovery\ Rate, 10\%)$ |
| Retail      | $max(1 - Recovery\ Rate, 10\%)$ |
| Credit Card | $45\%$                          |
| Banks       | $10\%$                          |
| Sovereigns  | $10\%$                          |

<br/><br/><br/>
<p style="float:right; width: auto;">
alizz islamic bank&copy;2020. All rights reserved
</p>
