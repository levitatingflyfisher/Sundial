# ADR-0004: Local-first, Ghost tier default, no account

- **Status:** Accepted
- **Date:** 2026-07-03 (documenting a choice load-bearing since the first commit)

## Context

Time spent outdoors is intimate family data: when a household is home, where the
kids play, the rhythm of their days. The obvious cloud incumbent in this space is a
subscription SaaS that keeps your data on its servers and gates basic features (like
editing) behind payment. Sundial exists partly as the opposite of that. The question
is whether an account and a server are *required* for the product to work.

## Decision

**No.** The default and only shipped tier is **Ghost**: zero identity, zero server
contact, all data in a local Drift/SQLite database. The app makes **no network
calls** and works fully offline. There is no account, no login, no sign-up.

A three-tier model is *designed* — Ghost (local), Token (anonymous multi-device
sync), Named (family accounts) — but only Ghost is built. `GhostAuthRepository` is
the live implementation; `upgradeToToken()` and `upgradeToNamed()` throw
`UnimplementedError`. When sync ships, it must move **encrypted blobs through a dumb
relay** (a server that only stores and returns ciphertext), keyed by a shared seed
phrase — never a Backend-as-a-Service, never plaintext, never a required account.

## Consequences

- **Buys:** the strongest possible privacy story (nothing to leak because nothing
  leaves the device — see [privacy-model.md](../privacy-model.md)); instant,
  offline, friction-free onboarding; no server to run, secure, or pay for.
- **Costs:** no cross-device sync and no shared family view *yet* — those are the
  headline items on the roadmap, and they're hard precisely because they must be
  done without a trusted server (conflict resolution + key management).
- **Forecloses:** any design that assumes a server can read the data, and any
  feature that would make the core require a network or an account.

## Alternatives considered

- **A BaaS (Firebase / Supabase / Auth0):** fastest path to sync and accounts, but it
  puts a household's data on a third party's servers and makes an account the price
  of entry — the exact thing this app rejects. Explicitly out (an early design that
  named Supabase for sync was dropped). Rejected.
- **Local-only, forever (drop sync entirely):** honest, but families genuinely want a
  shared view across phones. Better to keep Ghost complete *and* pursue
  encrypted-blob sync than to foreclose it. Rejected.
