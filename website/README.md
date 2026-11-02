# LumenBar official website

The official product site is `https://lumenbar.thoughtseed.space`.

It uses the licensed MotionSites **Lumen** design direction: a dark product hero, tilted desktop frame, layered feature cards, scroll reveals, and a mobile menu. LumenBar's copy, colors, original implementation, and verified product assets replace the template material.

## Host

The site is a static Cloudflare Pages direct upload in the Thoughtseed Labs account:

- account: `9d7cec1b5a32b2df8c6cdc1321ccd00b`
- Pages project: `lumenbar-site`
- custom domain: `lumenbar.thoughtseed.space`
- production branch: `main`

Cloudflare Pages already owns the custom-domain binding. Do not add a Worker route or a second DNS record for this hostname.

## Local preview

```bash
cd website
python3 -m http.server 4173 --directory public
```

## Cloudflare Pages preview

Keep personal Cloudflare variables unset and deploy a named Pages branch before production:

```bash
unset CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_API_KEY CLOUDFLARE_EMAIL CF_API_TOKEN CF_ACCOUNT_ID
npx --yes wrangler@4.156.1 pages deploy website/public \
  --project-name lumenbar-site \
  --branch motionsites-lumen \
  --commit-hash "$(git rev-parse HEAD)" \
  --commit-message "LumenBar MotionSites site preview" \
  --profile thoughtseed-labs
```

Verify the returned preview URL on desktop and mobile. `_headers` supplies the CSP, permission policy, referrer policy, cache rules, and `nosniff` header.

## Production deployment

Deploy only after the Pages preview is accepted:

```bash
unset CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_API_KEY CLOUDFLARE_EMAIL CF_API_TOKEN CF_ACCOUNT_ID
npx --yes wrangler@4.156.1 pages deploy website/public \
  --project-name lumenbar-site \
  --branch main \
  --commit-hash "$(git rev-parse HEAD)" \
  --commit-message "Publish LumenBar MotionSites site" \
  --profile thoughtseed-labs
```

Rollback is a Pages dashboard rollback to the preceding production deployment, or a repeat direct upload of the preceding repository commit's `website/public` directory.
