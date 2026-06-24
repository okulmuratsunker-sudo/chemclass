const { chromium } = require('/opt/node22/lib/node_modules/playwright');
const fs = require('fs');
const os = require('os');
const path = require('path');

(async () => {
  const src = process.argv[2];
  const outPdf = process.argv[3];
  const scale = Number(process.argv[4] || 2);

  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'rasterize-'));

  const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
  const page = await browser.newPage({ deviceScaleFactor: scale });
  await page.goto('file://' + src);

  const sections = await page.$$('section.page');
  let imgTags = '';
  for (let i = 0; i < sections.length; i++) {
    const file = path.join(tmpDir, `pg-${String(i + 1).padStart(3, '0')}.png`);
    await sections[i].screenshot({ path: file });
    imgTags += `<div class="pg"><img src="file://${file}"></div>\n`;
  }

  const html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><style>
  *{margin:0;padding:0;}
  @page{ size:A4; margin:0; }
  .pg{ width:210mm; height:297mm; page-break-after:always; }
  .pg:last-child{ page-break-after:auto; }
  .pg img{ width:210mm; height:297mm; display:block; }
  </style></head><body>
  ${imgTags}
  </body></html>`;

  const wrapperPath = path.join(tmpDir, 'wrapper.html');
  fs.writeFileSync(wrapperPath, html);

  const page2 = await browser.newPage();
  await page2.goto('file://' + wrapperPath);
  await page2.pdf({ path: outPdf, format: 'A4', printBackground: true, margin: { top: 0, bottom: 0, left: 0, right: 0 } });

  await browser.close();
  fs.rmSync(tmpDir, { recursive: true, force: true });
  console.log(sections.length, 'pages ->', outPdf);
})();
