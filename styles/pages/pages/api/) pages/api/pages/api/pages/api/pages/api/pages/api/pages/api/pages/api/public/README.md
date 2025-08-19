# Auto Comps — ChatGPT Powered (No MMR/KBB) — Photos + Links Enabled

- Manual entry: Year, Make, Model, Trim, Mileage (or VIN)
- MarketCheck active with photo + link + listed date (robust mapping)
- eBay MI sold (demo until approved)
- Bring a Trailer demo / optional light fetch (`BAT_ENABLE=1`)
- 30/60/90 averages (sold; listings if dates available)
- ChatGPT brief (`OPENAI_API_KEY`)

Env Vars (Vercel → Settings → Environment Variables):
- `MARKETCHECK_API_KEY`
- `EBAY_CLIENT_ID`, `EBAY_CLIENT_SECRET`, `EBAY_SCOPE=https://api.ebay.com/oauth/api_scope`, `EBAY_ENABLE_MI=1` (after approval)
- `OPENAI_API_KEY`
- `BAT_ENABLE=1` (optional)
