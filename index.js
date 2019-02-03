#!/usr/bin/env node

const { isString, groupBy } = require("lodash");
const fs = require("fs");
const path = require("path");
const yaml = require("js-yaml");
const moment = require("moment");
const numeral = require("numeral");
const puppeteer = require("puppeteer");
const handlebars = require("handlebars");
const svgToDataURL = require("svg-to-dataurl");

let translation = {};

// Helper functions
const setLanguage = function(lang) {
  if (lang !== "en") {
    require(`numeral/locales/${lang}`);
  }
  numeral.locale(lang);
  moment.locale(lang);
  translation = require(`${__dirname}/locales/${lang}.json`);
};

const replaceExtname = (filename, newExtname) =>
  filename.replace(
    new RegExp(path.extname(filename).replace(/\./g, "\\."), "g"),
    newExtname
  );

const roundToPrecision = function(value, quantityPrecision) {
  if (quantityPrecision == null) {
    quantityPrecision = 0;
  }
  if (isNaN(value)) {
    value = 0;
  }
  return parseFloat(value.toFixed(quantityPrecision));
};

const roundCurrency = value => roundToPrecision(value, 2);

const sum = items => items.reduce((r, a) => r + a, 0);

const calculateNet = items => sum(items.map(a => a.net_value));

const calculateTotal = items => sum(items.map(a => a.total_value));

// Default language setting
setLanguage("de");

// Business logic transformation
const transformData = function(data) {
  data = {
    invoice: {},
    receiver: {},
    items: [],
    intro_text: "",
    outro_text: "",
    ...data
  };

  if (data.invoice.language == null) {
    data.invoice.language = "de";
  }
  setLanguage(data.invoice.language);

  if (data.invoice.date == null) {
    data.invoice.date = new Date();
  }
  if (data.invoice.template == null) {
    data.invoice.template = "default";
  }
  if (data.invoice.location == null) {
    data.invoice.location = data.sender.town;
  }
  if (data.invoice.currency == null) {
    data.invoice.currency = "€";
  }
  if (data.invoice.quantityPrecision == null) {
    data.invoice.quantityPrecision = 0;
  }

  data.items = data.items.map(function(item) {
    item = {
      quantity: 1,
      tax_rate: 0,
      ...item
    };

    if (item.title == null) {
      throw new Error("An invoice item needs a title.");
    }

    if (item.price == null) {
      throw new Error("An invoice item needs a price.");
    }

    if (isString(item.quantity)) {
      item.quantity = new Function(
        `return ${item.quantity.replace(/\#/g, "//")};`
      )();
    }

    item.quantity = roundToPrecision(
      item.quantity,
      data.invoice.quantityPrecision
    );

    item.net_value = item.quantity * item.price;
    item.tax_value = item.net_value * (item.tax_rate / 100);
    item.total_value = item.net_value * (1 + item.tax_rate / 100);

    item.net_value = roundCurrency(item.net_value);
    item.tax_value = roundCurrency(item.tax_value);
    item.total_value = roundCurrency(item.total_value);

    return item;
  });

  data.totals = {
    net: calculateNet(data.items),
    total: calculateTotal(data.items),
    tax: Object.entries(groupBy(data.items, "tax_rate"))
      .map(([tax_rate, tax_group]) => ({
        rate: tax_rate,
        total: sum(tax_group.map(a => a.tax_value))
      }))
      .filter(tax => tax.total !== 0)
  };

  return data;
};

(async () => {
  // Process arguments
  if (process.argv.length < 3) {
    console.error("No input file given.");
    process.exit(2);
  }
  const inFilename = process.argv[2];
  const outFilename = replaceExtname(inFilename, ".pdf");

  try {
    let data = yaml.safeLoad(fs.readFileSync(inFilename, "utf8"));
    data = transformData(data);

    let templateFolder = `${__dirname}/templates/${data.invoice.template}`;
    if (
      fs.existsSync(
        path.join(path.dirname(inFilename), "templates", data.invoice.template)
      )
    ) {
      console.log(`Using custom template \`${data.invoice.template}\``);
      templateFolder = path.join(
        path.dirname(inFilename),
        "templates",
        data.invoice.template
      );
    }

    data.stylesheet = fs.readFileSync(`${templateFolder}/style.css`, "utf8");
    data.logo_url = svgToDataURL(
      fs.readFileSync(`${templateFolder}/logo.svg`, "utf8")
    );

    // Prepare rendering
    handlebars.registerHelper("plusOne", value => value + 1);
    handlebars.registerHelper("number", value =>
      numeral(value).format("0[.]0")
    );
    handlebars.registerHelper(
      "money",
      value => `${numeral(value).format("0,0.00")} ${data.invoice.currency}`
    );
    handlebars.registerHelper("percent", value =>
      numeral(value / 100).format("0 %")
    );
    handlebars.registerHelper("date", value => moment(value).format("LL"));
    handlebars.registerHelper("lines", function(options) {
      let contents = options.fn();
      contents = contents.split(/<br\s*\/?>/);
      contents = contents.map(a => a.trim()).filter(a => a != null && a !== "");
      contents = contents.join("<br>");
      return contents;
    });
    handlebars.registerHelper(
      "pre",
      contents =>
        new handlebars.SafeString(
          contents
            .split(/\n/)
            .map(a => handlebars.Utils.escapeExpression(a))
            .join("<br>")
        )
    );
    handlebars.registerHelper("t", phrase =>
      translation[phrase] != null ? translation[phrase] : phrase
    );

    // Rendering
    const mainTemplate = handlebars.compile(
      fs.readFileSync(`${templateFolder}/main.html`, "utf8")
    );
    const headerTemplate = handlebars.compile(
      fs.readFileSync(`${templateFolder}/header.html`, "utf8")
    );
    const footerTemplate = handlebars.compile(
      fs.readFileSync(`${templateFolder}/footer.html`, "utf8")
    );

    const browser = await puppeteer.launch();
    const page = await browser.newPage();
    await page.setContent(mainTemplate(data), {
      waitUntil: "networkidle2"
    });
    await page.pdf({
      path: outFilename,
      format: "A4",
      headerTemplate: headerTemplate(data),
      footerTemplate: footerTemplate(data),
      displayHeaderFooter: true,
      printBackground: true,
      margin: {
        top: "45mm",
        bottom: "45mm"
      }
    });
    await browser.close();
    console.log(`Created ${outFilename}`);
  } catch (err) {
    console.error(`Error creating ${outFilename}.`);
    console.error(err);
    process.exit(2);
  }
})();
