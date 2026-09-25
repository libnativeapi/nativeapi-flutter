// The glue every deno desktop example needs: serving the page, and finding the
// nativeapi Window behind a Deno.BrowserWindow.

import { Window, WindowManager } from "../../bindings/js/lib/index.ts";

const TYPES: Record<string, string> = {
  html: "text/html",
  js: "text/javascript",
  css: "text/css",
  svg: "image/svg+xml",
};

/**
 * Serves `files` (paths relative to this example) from the local server the
 * webviews load; every other path gets `index`, so routes like `/panel/x`
 * render the same page.
 */
export async function serve(index: string, files: string[]): Promise<void> {
  const read = async (path: string) => await Deno.readTextFile(new URL(path, import.meta.url));
  const pages = new Map<string, [string, string]>();
  for (const path of files) {
    pages.set("/" + path.replace(/^\.\//, ""), [TYPES[path.split(".").pop()!] ?? "text/plain", await read(path)]);
  }
  const html = await read(index);
  Deno.serve((request) => {
    const page = pages.get(new URL(request.url).pathname);
    const [type, body] = page ?? ["text/html", html];
    return new Response(body, { headers: { "content-type": type } });
  });
}

/** An absolute URL on the local server, for `BrowserWindow.navigate()`. */
export function serverUrl(path: string): string {
  const port = Deno.env.get("DENO_SERVE_ADDRESS")!.split(":").pop();
  return `http://127.0.0.1:${port}${path}`;
}

/**
 * The nativeapi Window behind a Deno.BrowserWindow. The two libraries number
 * windows independently, so find it by a title only it carries for a moment.
 */
export async function nativeWindowOf(browser: Deno.BrowserWindow, title: string): Promise<Window> {
  const token = `${title} #${crypto.randomUUID()}`;
  browser.setTitle(token);
  try {
    for (let attempt = 0; attempt < 300; attempt++) {
      const match = WindowManager.getAll().find((window) => window.title === token);
      if (match) {
        return match;
      }
      await new Promise((resolve) => setTimeout(resolve, 10));
    }
    throw new Error(`no native window titled ${token}`);
  } finally {
    browser.setTitle(title);
  }
}

/**
 * A new window with a transparent webview. Creation-only options like
 * `transparent` do not apply to the window `deno desktop` opens at startup,
 * which the first `new Deno.BrowserWindow()` adopts, so that one is closed
 * once the new one exists. (`transparent` is not in the BrowserWindowOptions
 * typings yet.)
 */
export function transparentWindow(options: Deno.BrowserWindowOptions, path = "/"): Deno.BrowserWindow {
  const startup = new Deno.BrowserWindow({ title: options.title });
  const browser = new Deno.BrowserWindow({ ...options, transparent: true } as Deno.BrowserWindowOptions);
  browser.navigate(serverUrl(path));
  startup.close();
  return browser;
}
