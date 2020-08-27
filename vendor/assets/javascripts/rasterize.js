const puppeteer = require('puppeteer');
const address = system.args[1];
const output = system.args[2];
console.log('pup')
(async () => {
  const browser = await puppeteer.launch({headless: false});
  // const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto(address, {waitUntil: 'networkidle2'});
  await page.pdf({path: output, format: 'A4'});

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
