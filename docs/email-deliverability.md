# Stretch: Email Deliverability — DNS Auth, IP Warming, Monitoring

> Note: I used an AI assistant (Claude) to help research and draft this section. The structure and recommendations were reviewed and are ones I stand behind.

Plan for sending high-volume newsletters through PowerMTA without landing in spam. The short version: authentication proves who you are, warming builds your reputation, monitoring tells you when either is slipping.

## 1. DNS and authentication

Assume sends come from a dedicated subdomain, e.g. `news.dexterlab.com` — never the root domain. If newsletter reputation gets burned, transactional mail (OTPs, receipts — critical for a fintech) is unaffected.

**SPF** — lists which IPs may send for the domain:

```
news.dexterlab.com.  TXT  "v=spf1 ip4:203.0.113.10 ip4:203.0.113.11 -all"
```

Explicit IPs of the PowerMTA senders, hard fail (`-all`) for everything else. Keep it under 10 DNS lookups — a common silent failure when people chain `include:` records.

**DKIM** — cryptographically signs each message. Generate a 2048-bit keypair per sending domain, publish the public key at `pmta._domainkey.news.dexterlab.com`, and configure PowerMTA to sign with the private key (`domain-key` directive in the config). Rotate keys every 6–12 months; publish the new selector alongside the old, switch signing, retire the old after a week.

**DMARC** — tells receivers what to do when SPF/DKIM fail, and sends you reports:

```
_dmarc.news.dexterlab.com.  TXT  "v=DMARC1; p=none; rua=mailto:dmarc@dexterlab.com; adkim=s; aspf=s"
```

Start at `p=none` (monitor only), watch aggregate reports for 2–4 weeks to confirm all legitimate mail authenticates, then step up through `p=quarantine` to `p=reject`. Jumping straight to reject is how you discover forgotten mail sources by breaking them.

Also: **valid PTR (reverse DNS)** on every sending IP matching the HELO name — Gmail hard-requires this — and a proper `List-Unsubscribe` header (one-click, RFC 8058), which Gmail and Yahoo now mandate for bulk senders above 5k/day.

## 2. IP warming

New IPs have no reputation, and mailbox providers treat no reputation as bad reputation. You cannot send 500k emails from a cold IP on day one — you'll be throttled or blocked, and blocks outlast the campaign.

Warming schedule per IP, roughly doubling daily volume: day 1: 200; day 3: 1,000; day 7: 10,000; day 14: 50,000; day 21+: 100k+, then steady state. Rules that matter more than the exact numbers:

- **Send to your most engaged recipients first** (recent openers/clickers). Early positive engagement is the strongest reputation signal.
- **Spread volume across the day**, don't burst — PowerMTA's per-queue rate limits (`max-msg-rate` per domain) handle this.
- **Respect per-provider limits**: Gmail, Yahoo, Outlook each get their own PowerMTA queue with its own ramp; if one provider starts deferring (4xx), back off that queue only.
- Hold at a volume tier if bounce rate exceeds ~2% or complaints exceed 0.1% — pushing through a warning turns it into a block.

## 3. Monitoring

- **PowerMTA accounting files** are the ground truth: per-provider delivered / deferred / bounced rates. Ship them to a dashboard (e.g. Grafana via a small parser, or PowerMTA's own web monitor) and alert on deferral rate >5% or bounce rate >2% per provider.
- **DMARC aggregate reports** (the `rua` address) parsed through something like dmarcian or parsedmarc — catches authentication drift and shows if anyone is spoofing the domain.
- **Google Postmaster Tools** and **Microsoft SNDS** — free, direct view of your reputation with the two providers that matter most.
- **Blocklist monitoring** — automated daily checks of sending IPs against Spamhaus, Barracuda, SpamCop; alert on any listing.
- **Seed list tests** before large sends — mail a set of accounts across providers and check inbox vs spam placement.
- **Feedback loops (FBLs)** — register with Yahoo/Microsoft FBLs so complaints come back programmatically; auto-suppress any complainer immediately.

List hygiene underpins all of it: confirmed opt-in, suppress hard bounces immediately, sunset addresses with no engagement in 6 months. Reputation problems are usually list problems wearing a technical costume.
