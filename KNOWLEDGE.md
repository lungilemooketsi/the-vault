# Investec API notes for The Vault

Checked against the docs and a read-only sandbox probe on 16 November 2026. Secret values are not copied here.

## Where the sandbox credentials live

Investec publishes a sandbox `client_id`, `client_secret`, and `x-api-key` in the Sandbox credentials table:

- https://developer.investec.com/api-reference/SA%20PB%20Account%20Information
- Linked from https://developer.investec.com/individuals under "Use the Sandbox"
- Auth quickstart: https://developer.investec.com/api-reference/SA%20Open%20API%20-%20Authorization
- Wiki, flow only: https://investec.gitbook.io/programmable-banking-community-wiki/get-started/api-quick-start-guide/how-to-authenticate

They work on `https://openapisandbox.investec.com` and not on `https://openapi.investec.com`. Treat them as credentials anyway: environment variables only, never the repo. The token request is OAuth2 client credentials with an extra `x-api-key` header and `Authorization: Basic base64(client_id:client_secret)`. The body is `grant_type=client_credentials`. A successful probe returned `expires_in` 1799 and scope `accounts balances beneficiarypayments transactions transfers`. There is no `cards` scope.

## Accounts

`GET /za/pb/v1/accounts` returns eight accounts across three profiles (the public sandbox personas). Only the product `Private Bank Account` has a rich history. The others are PrimeSaver, MoneyFund Tracker, Cash Management Account, and Investec Youth Account, mostly interest. The coach selects the Private Bank Account and uses the PrimeSaver on the same `profileId` as the savings vault.

`accountId` is a 25-digit integer in the JSON. `jsondecode` will round it. Quote integers of 16 digits or more before decoding (`vault.decodeApiJson`).

`GET /za/pb/v1/accounts/{accountId}/balance` returns `currentBalance`, `availableBalance`, `currency`, and also `budgetBalance`, `cashBalance`, `straightBalance` (zeroes on the snapshot). The Private Bank Account balance on the snapshot is R33,607.16.

## Transactions

`GET /za/pb/v1/accounts/{accountId}/transactions?fromDate=YYYY-MM-DD&toDate=YYYY-MM-DD`

Always send both dates. The docs say an omitted `fromDate` defaults to today minus 180 days and that filtering uses `postingDate`. Empirically, an unfiltered call on 16 November 2026 returned 263 rows starting 17 August and dropped one card purchase with `transactionDate` 2026-08-11 and `postingDate` 2026-09-04. `fromDate=2020-01-01&toDate=2026-11-16` returns all 264 posted rows. Nothing exists before 11 August 2026. A 2024 window returns zero. Repeating the call returns the same payload.

Posted fields: `accountId`, `type` (`DEBIT` / `CREDIT`), `transactionType`, `status` (`POSTED`), `description`, `cardNumber`, `postedOrder`, `postingDate`, `valueDate`, `actionDate`, `transactionDate`, `amount`, `runningBalance`, `uuid`.

Counts on the Private Bank Account: CardPurchases 199, DebitOrders 24, OnlineBankingPayments 14, Deposits 9, FeesAndInterest 9, ATMWithdrawals 5, VASTransactions 2, FasterPay 2. There is no category field.

`actionDate` is 2026-11-16 on every row. Do not use it for habits. Use `transactionDate` for the day the customer swiped, and remember the API's own filter is documented against `postingDate`. `postingDate` can fall after `toDate` even when the row is returned (a few November rows post on the 17th and 18th). The offline fixture therefore filters on `transactionDate`, which matches the wide-window count of 264.

Amounts are positive rands with `type` saying which way they went. Card code is different: authorisations are in cents.

`postedOrder` of 0 means not settled (community FAQ). The posted snapshot has none of those. Drop them if they appear.

Month counts by `transactionDate`: August 43, September 83, October 81, November 57 (through the 16th). August is a partial month.

Salary-like credits are `STANSAL` in August (R29,659.92) and `STANCOM` in September and October (R29,733.26 on the 16th and the 22nd). November has not received that credit yet on the snapshot. A smaller STANCOM weekly payment (about R768) must not be grouped with the salary. Stripping digits and keeping the first three real words does that: `stancom kjoe smith` versus `stancom ksss weekly`.

Debit-order references change every month (`VODACOM 0397` / `0399` / `0401`, and the same pattern on Afrihost and AON). Exact description keys miss them. The stemmer drops digits and one-letter tokens, so those three Vodacom rows become `vodacom`. Amounts for levy, medical (`MOMMED`), Momentum, and the service charge are stable. NEDBHL and the FNB home loan move a little but stay inside 15%.

Some descriptions embed a long account number. The committed fixture replaces runs of 8 or more digits with `****`. Printed output does the same.

## Pending

`GET /za/pb/v1/accounts/{accountId}/pending-transactions` returns three PENDING debits on the Private Bank Account (Amazon R999, MRP Home R560, YouTube R110) with a thinner schema and no `transactionType`. The same call returns HTTP 500 on the other seven accounts. The client treats that as an empty list plus a warning. Pending rows are not used as habits.

## Transfers

`POST /za/pb/v1/accounts/{accountId}/transfermultiple`

```json
{
  "transferList": [
    {
      "beneficiaryAccountId": "DESTINATION",
      "amount": "250.00",
      "myReference": "Vault floor",
      "theirReference": "Savings vault"
    }
  ],
  "profileId": "PROFILE"
}
```

Amounts are strings in rands, not cents. The destination must already be a beneficiary; for an own-account move the sandbox examples pass the other account id. The bounty rule is stricter than the API: a physical or simulated input must not complete the movement without a review. `vault.transferMultiple` throws unless `vault.decideApproval` was called with the verb `APPROVE` for that exact payload. Even then, a sandbox client will not POST unless `VAULT_ALLOW_LIVE_TRANSFER=1`, because this sandbox is shared.

`paymultiple` exists and is not used.

## Cards

`beforeTransaction(authorization)` returns `true` or `false`. Limit: 2 seconds. Do not call MATLAB or the network.

`afterTransaction(transaction)` runs after a processed transaction. Limit: 15 seconds. `fetch` / `node-fetch` is available. `afterDecline` runs when the card declines.

`env.json` values arrive as `process.env` strings. Nested objects are not a good place to hide structure; The Vault stores the budget as one JSON string, `VAULT_BUDGET_JSON`.

Authorisation fields that matter: `centsAmount` (R55 is 5500), `merchant.name`, `merchant.category.key`, `reference` (`simulation` inside the IDE simulator), `accountNumber`. The IDE is `main.js` plus `env.json`.

Card API, production host in the wiki (`https://openapi.investec.com`, sandbox host for everything else):

- `GET /za/v1/cards`
- `POST /za/v1/cards/{cardKey}/code` with `{ "code": "..." }`
- `POST /za/v1/cards/{cardKey}/publish` with `{ "codeid": "...", "code": "" }`
- `POST /za/v1/cards/{cardKey}/code/execute` with `simulationcode`, `centsAmount`, `currencyCode`, `merchantCode`, `merchantName`, `merchantCity`, `countryCode`

`GET /za/v1/cards` on the sandbox returned 403 HTML ("We weren't banking on that happening!"). The client records that and does not throw. Exercise the card with `card-code` and the Investec IDE. Community note: https://github.com/Investec-Developer-Community/.github/issues/32

The card VM is a short Node environment. Community guidance for generated card code: `node-fetch` and `moment` may exist; `URLSearchParams` and `Buffer` should not be relied on. `main.js` uses global `fetch` only after the decision, and only from `afterTransaction` / `afterDecline`.

## What failed so we would not do it again

- Calling MATLAB from `beforeTransaction`. Two seconds, and the floor is not on the authorisation path.
- Omitting `fromDate`. One real purchase disappears.
- Grouping merchants on the raw description. Monthly references split one debit order into many.
- Using `actionDate`. It is the snapshot day for the whole history.
- Trusting `jsondecode` with account ids.
- Treating a sandbox token as a cards token.
- Letting the demo POST `transfermultiple` on every run. The fixture is static until somebody writes to it.
