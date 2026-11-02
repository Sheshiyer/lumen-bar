const securityHeaders = {
  "Content-Security-Policy": "default-src 'self'; img-src 'self' data:; style-src 'self' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; script-src 'self'; connect-src 'none'; frame-ancestors 'none'; base-uri 'self'; form-action 'none'",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=(), interest-cohort=()",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "X-Content-Type-Options": "nosniff",
};

export default {
  async fetch(request, env) {
    const response = await env.ASSETS.fetch(request);
    const headers = new Headers(response.headers);
    const { pathname } = new URL(request.url);

    for (const [name, value] of Object.entries(securityHeaders)) {
      headers.set(name, value);
    }

    headers.set(
      "Cache-Control",
      pathname.startsWith("/assets/")
        ? "public, max-age=3600, stale-while-revalidate=86400"
        : "public, max-age=300",
    );

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    });
  },
};
