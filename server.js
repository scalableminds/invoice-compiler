const express = require("express");
const fs = require("fs");
const path = require("path");
const { compile } = require("./lib");

const port = process.env.PORT || 3000;

const app = express();
app.use(express.raw({ type: "*/*" }));

app.get("/", (req, res) => {
  res.type("html").send(fs.readFileSync(path.join(__dirname, "index.html")));
});

app.post("/compile", async (req, res) => {
  try {
    const tmpDir = fs.mkdtempSync(process.env.TMPDIR);
    const inFilename = path.join(tmpDir, "invoice.yaml");
    const outFilename = path.join(tmpDir, "invoice.pdf");
    fs.writeFileSync(inFilename, req.body);
    await compile(inFilename, outFilename);
    res.download(outFilename);
  } catch (err) {
    console.error(err);
    res.status(500).send(`${err}\n${err.stack}`);
  }
});

app.listen(port, "0.0.0.0");
console.log(`Listening to ${port}`);
