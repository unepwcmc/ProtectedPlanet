const puppeteer = require('puppeteer');
const address = process.argv[2];
const output = process.argv[3];

(async () => {
  // const browser = await puppeteer.launch({headless: false});
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  page.setViewport({
    width: 1200,
    height: 1754,
    deviceScaleFactor: 2
  });

  await page.goto(address, {waitUntil: 'networkidle2'});

  const headerHTML = `<div style="padding-top:10px; padding-right:26px; width: 100%;">
    <p style="float:right; margin-bottom:0;">
      <span style="color:#000; font-family:'Hind Siliguri',Arial; font-size:5pt;">Protected Planet | </span>
      <span style="color:#000; font-family:'Hind Siliguri',Arial; font-size:5pt; font-weight:bold;">Page</span>
      <span style="color:#000; font-family:'Hind Siliguri',Arial; font-size:5pt; font-weight:bold; padding-left:2px;" class="pageNumber"></span>
      <span style="color:#000; font-family:'Hind Siliguri',Arial; font-size:5pt; padding:0 2px; display:inline-block"> of </span> 
      <span style="color:#000; font-family:'Hind Siliguri',Arial; font-size:5pt; font-weight:bold;" class="totalPages"></span>
  </div>`;

  const footerHTML = `<div style="padding-right:26px; width: 100%;">
    <span style="color:#000; float:right; font-family:'Hind Siliguri',Arial; font-size:5pt; font-weight:bold;" class="date"></span>
  </div>`;

  await page.pdf({
    displayHeaderFooter: true,
    headerTemplate: headerHTML,
    footerTemplate: footerHTML,
    format: 'A4',
    margin: {
      top: '60px',
      right: '20px',
      bottom: '60px',
      left: '20px',
    },
    path: output, 
    printBackground: true,
    scale: .63
  });

  await browser.close();
})();


// "use strict";
// var page = require('webpage').create(),
//   system = require('system'),
//   address, output, size;

// address = system.args[1];
// output = system.args[2];
// page.viewportSize = { width: 1200, height: 1697 };

// page.open(address, function (status) {
//   if (status !== 'success') {
//       console.log('Unable to load the address!');
//       phantom.exit(1);
//   } else {
//       window.setTimeout(function () {
//           page.render(output);
//           phantom.exit();
//       }, 200);
//   }
// });
