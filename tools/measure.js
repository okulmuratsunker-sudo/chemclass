const { chromium } = require('/opt/node22/lib/node_modules/playwright');
(async () => {
  const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
  const page = await browser.newPage();
  const file = process.argv[2];
  await page.goto('file://' + file);
  const heights = await page.evaluate(() => {
    const sections = document.querySelectorAll('.page');
    return Array.from(sections).map((s, i) => {
      const r = s.getBoundingClientRect();
      return { i, heightMM: (r.height / 96 * 25.4).toFixed(2), heightPX: r.height };
    });
  });
  console.log(heights);
  await browser.close();
})();
