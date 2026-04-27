#!/usr/bin/env python3
"""Generate the Sign-in-with-Apple JWT for the Supabase Auth provider.

Apple's spec:
  - Header: { alg: "ES256", kid: <Key ID> }
  - Payload:
      iss = Team ID
      iat = now (unix seconds)
      exp = iat + up to 6 months   (Apple's hard cap: 15 552 000 sec)
      aud = "https://appleid.apple.com"
      sub = Services ID
  - Signed with the .p8 private key, ECDSA over P-256.

The output JWT goes into Supabase → Authentication → Providers → Apple
→ Secret Key (for OAuth). It expires after 6 months by default; rerun
this script and update Supabase before that to rotate.

Dependencies:
    Fedora:  sudo dnf install python3-pyjwt python3-cryptography
    pip:     pip install --user pyjwt cryptography

Usage:
    python3 tools/generate_apple_jwt.py \\
        --p8 /path/to/AuthKey_XXXXXXXXXX.p8 \\
        --team-id WWMRM77FM3 \\
        --services-id com.heffelhoff.heffelhoff-sudoku.signin \\
        --key-id ABCDEFGHIJ \\
        --validity-days 180

The .p8 file is read locally and never leaves your machine. Don't
commit the .p8 to the repo (it's covered by .gitignore — *.p8).
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from datetime import datetime, timezone

try:
    import jwt
except ImportError:
    sys.exit(
        "ERROR: PyJWT not installed.\n"
        "  Fedora: sudo dnf install python3-pyjwt python3-cryptography\n"
        "  pip:    pip install --user pyjwt cryptography"
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate a Sign-in-with-Apple JWT for Supabase Auth."
    )
    parser.add_argument("--p8", required=True, help="Path to the .p8 private key file")
    parser.add_argument("--team-id", required=True, help="Apple Team ID (10 chars)")
    parser.add_argument("--services-id", required=True, help="Apple Services ID (e.g. com.heffelhoff.heffelhoff-sudoku.signin)")
    parser.add_argument("--key-id", required=True, help="Apple Key ID (10 chars, shown next to the .p8 in Apple Developer)")
    parser.add_argument(
        "--validity-days",
        type=int,
        default=180,
        help="Token lifetime in days. Apple max is 180. Default: 180.",
    )
    args = parser.parse_args()

    if not os.path.exists(args.p8):
        sys.exit(f"ERROR: .p8 file not found: {args.p8}")

    if args.validity_days > 180:
        sys.exit("ERROR: Apple caps the JWT lifetime at 180 days (6 months).")

    with open(args.p8, "rb") as f:
        private_key = f.read()

    iat = int(time.time())
    exp = iat + args.validity_days * 24 * 3600

    headers = {"alg": "ES256", "kid": args.key_id}
    payload = {
        "iss": args.team_id,
        "iat": iat,
        "exp": exp,
        "aud": "https://appleid.apple.com",
        "sub": args.services_id,
    }

    try:
        token = jwt.encode(payload, private_key, algorithm="ES256", headers=headers)
    except Exception as e:
        sys.exit(f"ERROR: failed to sign JWT — {e}")

    if isinstance(token, bytes):
        token = token.decode("ascii")

    iat_iso = datetime.fromtimestamp(iat, tz=timezone.utc).isoformat()
    exp_iso = datetime.fromtimestamp(exp, tz=timezone.utc).isoformat()

    print()
    print("=" * 72)
    print("Apple Sign-in JWT generated")
    print("=" * 72)
    print(f"  Team ID:     {args.team_id}")
    print(f"  Services ID: {args.services_id}")
    print(f"  Key ID:      {args.key_id}")
    print(f"  Issued:      {iat_iso}")
    print(f"  Expires:     {exp_iso}  (rotate before this date)")
    print("=" * 72)
    print()
    print(token)
    print()
    print(
        "Paste the line above into Supabase → Authentication → "
        "Providers → Apple → Secret Key (for OAuth)."
    )
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
