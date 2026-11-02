# LumenBar website

Official product site for `https://lumenbar.thoughtseed.space`.

The site uses the licensed MotionSites **Lumen** design direction: a dark product hero, tilted desktop frame, layered feature cards, scroll reveals, and a mobile menu. LumenBar's copy, colors, original implementation, and verified product assets replace the template material. A small Worker serves the assets and enforces privacy and security headers; it has no data bindings or telemetry.

## Preview

```bash
cd website
python3 -m http.server 4173 --directory public
```

## Deploy

Use the Labs profile and keep personal Cloudflare variables unset.

```bash
unset CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_API_KEY CLOUDFLARE_EMAIL CF_API_TOKEN CF_ACCOUNT_ID
cd website
npx --yes wrangler@4.156.1 preview -c wrangler.preview.labs.jsonc --profile thoughtseed-labs --name lumenbar-launch --json
# Once the isolated Preview URL is verified:
npx --yes wrangler@4.156.1 deploy -c wrangler.labs.jsonc --profile thoughtseed-labs
```

The production config pins account `9d7cec1b5a32b2df8c6cdc1321ccd00b` and attaches the custom domain `lumenbar.thoughtseed.space`.
