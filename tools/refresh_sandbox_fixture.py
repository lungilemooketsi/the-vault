#!/usr/bin/env python3
"""Refresh matlab/fixtures from the Investec public sandbox.

Reads INVESTEC_CLIENT_ID, INVESTEC_CLIENT_SECRET and INVESTEC_API_KEY from the
environment. Never prints those values and never writes them to disk.

Where to copy them from (they are public sandbox credentials, not yours):
https://developer.investec.com/api-reference/SA%20PB%20Account%20Information
Look for the Sandbox credentials table. Same values are linked from
https://developer.investec.com/individuals under "Use the Sandbox".
"""

import base64
import json
import os
import re
import sys
import urllib.parse
import urllib.request

BASE = os.environ.get("INVESTEC_BASE_URL", "https://openapisandbox.investec.com").rstrip("/")
FROM_DATE = "2020-01-01"
TO_DATE = os.environ.get("VAULT_AS_OF", "2026-11-16")


def required(name):
    value = os.environ.get(name, "").strip()
    if not value:
        sys.stderr.write(
            f"Missing {name}. Copy the sandbox client id, secret and x-api-key from\n"
            "https://developer.investec.com/api-reference/SA%20PB%20Account%20Information\n"
            "into the environment. Do not commit them.\n"
        )
        sys.exit(1)
    return value


def call(method, url, headers, data=None):
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=90) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read()


def mask_desc(text):
    return re.sub(r"\d{8,}", "****", text or "")


def as_str(value):
    return "" if value is None else str(value)


def mask_card(value):
    digits = re.sub(r"\D", "", str(value or ""))
    if len(digits) >= 4:
        return "****" + digits[-4:]
    return "****" if value else ""


def clean_tx(row, account_id, uuid):
    row["accountId"] = as_str(row.get("accountId", account_id))
    row["description"] = mask_desc(row.get("description"))
    row["uuid"] = uuid
    if row.get("cardNumber"):
        row["cardNumber"] = mask_card(row.get("cardNumber"))
    return row


def main():
    client_id = required("INVESTEC_CLIENT_ID")
    client_secret = required("INVESTEC_CLIENT_SECRET")
    api_key = required("INVESTEC_API_KEY")
    basic = base64.b64encode(f"{client_id}:{client_secret}".encode()).decode()
    status, body = call(
        "POST",
        BASE + "/identity/v2/oauth2/token",
        {
            "Authorization": "Basic " + basic,
            "x-api-key": api_key,
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded",
        },
        urllib.parse.urlencode({"grant_type": "client_credentials"}).encode(),
    )
    if status != 200:
        sys.stderr.write(f"Token request failed with HTTP {status}. The token was not printed.\n")
        sys.exit(1)
    token = json.loads(body)["access_token"]
    auth = {"Authorization": "Bearer " + token, "Accept": "application/json"}
    status, body = call("GET", BASE + "/za/pb/v1/accounts", auth)
    if status != 200:
        sys.stderr.write(f"Accounts request failed with HTTP {status}.\n")
        sys.exit(1)
    accounts = json.loads(body)
    for account in accounts["data"]["accounts"]:
        for key in ("accountId", "accountNumber", "profileId"):
            if key in account:
                account[key] = as_str(account[key])
    pba = next(a for a in accounts["data"]["accounts"] if a.get("productName") == "Private Bank Account")
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "matlab", "fixtures"))
    os.makedirs(root, exist_ok=True)
    query = urllib.parse.urlencode({"fromDate": FROM_DATE, "toDate": TO_DATE})
    balances = {}
    pending = {}
    others = {}
    posted = 0
    for account in accounts["data"]["accounts"]:
        aid = account["accountId"]
        sb, bb = call("GET", f"{BASE}/za/pb/v1/accounts/{aid}/balance", auth)
        if sb == 200:
            bal = json.loads(bb)
            if "accountId" in bal.get("data", {}):
                bal["data"]["accountId"] = as_str(bal["data"]["accountId"])
            balances[aid] = bal
        sp, bp = call("GET", f"{BASE}/za/pb/v1/accounts/{aid}/pending-transactions", auth)
        if sp == 200:
            payload = json.loads(bp)
            rows = payload.get("data", {}).get("transactions", [])
            for row in rows:
                row["accountId"] = as_str(row.get("accountId", aid))
                row["description"] = mask_desc(row.get("description"))
            pending[aid] = {"status": 200, "body": payload}
        else:
            pending[aid] = {"status": sp, "body": {"title": "An error occurred while processing your request.", "status": sp}}
        st, tb = call("GET", f"{BASE}/za/pb/v1/accounts/{aid}/transactions?{query}", auth)
        if st != 200:
            if aid != pba["accountId"]:
                others[aid] = {"status": st, "body": {"data": {"transactions": []}, "meta": {"totalPages": 1}}}
            continue
        payload = json.loads(tb)
        rows = payload.get("data", {}).get("transactions", [])
        for index, row in enumerate(rows):
            prefix = "pba" if aid == pba["accountId"] else f"other-{aid[-4:]}"
            clean_tx(row, aid, f"{prefix}-{index + 1:05d}")
        if aid == pba["accountId"]:
            payload["meta"] = {"totalPages": 1}
            posted = len(rows)
            with open(os.path.join(root, "transactions.json"), "w") as handle:
                json.dump(payload, handle, indent=2)
                handle.write("\n")
        else:
            others[aid] = {"status": 200, "count": len(rows), "body": payload}
    with open(os.path.join(root, "accounts.json"), "w") as handle:
        json.dump(accounts, handle, indent=2)
        handle.write("\n")
    with open(os.path.join(root, "balances.json"), "w") as handle:
        json.dump(balances, handle, indent=2)
        handle.write("\n")
    with open(os.path.join(root, "pending.json"), "w") as handle:
        json.dump(pending, handle, indent=2)
        handle.write("\n")
    with open(os.path.join(root, "other-transactions.json"), "w") as handle:
        json.dump(others, handle, indent=2)
        handle.write("\n")
    with open(os.path.join(root, "snapshot.json"), "w") as handle:
        json.dump({
            "source": "Investec public sandbox",
            "baseUrl": BASE,
            "pulledOn": TO_DATE,
            "fromDate": FROM_DATE,
            "toDate": TO_DATE,
            "privateBankProduct": "Private Bank Account",
            "postedCount": posted,
            "note": "Credentials are not stored. Long digit runs in descriptions were masked."
        }, handle, indent=2)
        handle.write("\n")
    sys.stderr.write(f"Wrote sandbox snapshot with {posted} Private Bank Account transactions.\n")


if __name__ == "__main__":
    main()
