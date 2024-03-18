#!/usr/bin/env node

const path = require("path");
const { compile } = require("./lib");

const replaceExtname = (filename, newExtname) =>
  filename.replace(
    new RegExp(path.extname(filename).replace(/\./g, "\\."), "g"),
    newExtname,
  );

(async () => {
  // Process arguments
  if (process.argv.length < 3) {
    console.error("No input file given.");
    process.exit(2);
  }
  const inFilename = process.argv[2];
  const outFilename = replaceExtname(inFilename, ".pdf");

  try {
    await compile(inFilename, outFilename);
  } catch (err) {
    console.error(`Error creating ${outFilename}.`);
    console.error(err);
    process.exit(2);
  }
})();
