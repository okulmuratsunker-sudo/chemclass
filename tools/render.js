const { chromium } = require('/opt/node22/lib/node_modules/playwright');
(async () => {
  const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
  const page = await browser.newPage();
  const file = process.argv[2];
  const out = process.argv[3];
  await page.goto('file://' + file);
  await page.pdf({ path: out, format: 'A4', printBackground: true, margin: { top: 0, bottom: 0, left: 0, right: 0 } });
  await browser.close();
})();
