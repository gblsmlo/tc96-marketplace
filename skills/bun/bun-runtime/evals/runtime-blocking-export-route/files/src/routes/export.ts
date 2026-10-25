import { execSync } from "node:child_process";
import { readFileSync } from "node:fs";

// GET /export?file=report-2026-10.md -> converts the markdown report to PDF with pandoc
export function exportRoute(req: Request): Response {
  const url = new URL(req.url);
  const file = url.searchParams.get("file") ?? "report.md";
  const dir = process.env.EXPORT_DIR ?? "./exports";

  execSync(`pandoc ${dir}/${file} -o ${dir}/${file}.pdf`);
  const pdf = readFileSync(`${dir}/${file}.pdf`);

  return new Response(pdf, { headers: { "content-type": "application/pdf" } });
}
