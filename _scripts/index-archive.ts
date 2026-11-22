// Post-render step: add the pre-rendered distill posts (listed in
// posts/archive.yml) to the site's sitemap.xml and search index, since Quarto
// only indexes pages it renders itself. Runs with Quarto's bundled Deno.
import { parse } from "https://deno.land/std@0.224.0/yaml/mod.ts";

const out = Deno.env.get("QUARTO_PROJECT_OUTPUT_DIR") ?? "_site";
const siteUrl = "https://opensourcefootball.com/";

type Item = { path: string; title: string; description?: string; date: string };
const items = parse(await Deno.readTextFile("posts/archive.yml")) as Item[];

const decode = (s: string) =>
  s.replace(/&nbsp;/g, " ").replace(/&amp;/g, "&").replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&#39;|&#x27;/g, "'");

function articleText(html: string): string {
  const clean = html
    .replace(/<script[\s\S]*?<\/script>/g, " ")
    .replace(/<style[\s\S]*?<\/style>/g, " ");
  // distill puts the post body in <div class="d-article"> ... <div class="d-appendix">
  const start = clean.indexOf('class="d-article"');
  const end = clean.indexOf('class="d-appendix"', start);
  const body = start >= 0
    ? clean.slice(clean.indexOf(">", start) + 1, end > start ? end : undefined)
    : clean;
  return decode(body.replace(/<[^>]+>/g, " ")).replace(/\s+/g, " ").trim().slice(0, 20000);
}

// --- search.json ---------------------------------------------------------
const searchPath = `${out}/search.json`;
try {
  const search = JSON.parse(await Deno.readTextFile(searchPath));
  for (const it of items) {
    const html = await Deno.readTextFile(`${out}/${it.path}`);
    search.push({
      objectID: it.path,
      href: it.path,
      title: it.title,
      section: "",
      text: `${it.description ?? ""} ${articleText(html)}`.trim(),
      crumbs: [],
    });
  }
  await Deno.writeTextFile(searchPath, JSON.stringify(search, null, 2));
} catch (e) {
  if (!(e instanceof Deno.errors.NotFound)) throw e; // partial render: no search.json
}

// --- sitemap.xml ---------------------------------------------------------
const sitemapPath = `${out}/sitemap.xml`;
try {
  const sitemap = await Deno.readTextFile(sitemapPath);
  const urls = items.map((it) =>
    `  <url>\n    <loc>${siteUrl}${it.path}</loc>\n    <lastmod>${it.date}</lastmod>\n  </url>`
  ).join("\n");
  await Deno.writeTextFile(sitemapPath, sitemap.replace("</urlset>", `${urls}\n</urlset>`));
} catch (e) {
  if (!(e instanceof Deno.errors.NotFound)) throw e;
}

console.log(`Indexed ${items.length} archived posts (sitemap + search).`);
