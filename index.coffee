#!/usr/bin/env coffee

_           = require("lodash")
fs          = require("fs")
path        = require("path")
exec        = require("child_process").exec
yaml        = require("js-yaml")
moment      = require("moment")
numeral     = require("numeral")
wkhtmltopdf = require("wkhtmltopdf")
handlebars  = require("handlebars")

translation = {}

# Helper functions
setLanguage = (lang) ->
  moment.locale(lang)
  try
    numeral.language(lang, require("numeral/languages/#{lang}"))
  catch e
  numeral.language(lang)
  translation = require("./languages/#{lang}.json")

replaceExtname = (filename, newExtname) ->
  return filename.replace(new RegExp(path.extname(filename).replace(/\./g, "\\."), "g"), newExtname)

roundCurrency = (value) ->
  if isNaN(value)
    value = 0
  return parseFloat(value.toFixed(2))

sum = (items) ->
  items.reduce(((r, a) -> r + a), 0)

calculateNet = (items) ->
  return sum(_.pluck(items, "net_value"))

calculateTotal = (items) ->
  return sum(_.pluck(items, "total_value"))


# Default language setting
setLanguage("de")

# Business logic transformation
transformData = (data) ->

  _.defaults(data,
    invoice: {}
    receiver: {}
    items: []
    intro_text: ""
    outro_text: ""
  )

  data.invoice.language ?= "de"
  setLanguage(data.invoice.language)

  data.invoice.date ?= new Date()
  data.invoice.template ?= "default"
  data.invoice.location ?= data.sender.town
  data.invoice.currency ?= "€"

  data.items = data.items.map((item) ->

    item = _.defaults(item,
      quantity: 1
      tax_rate: 0
    )

    if not item.title?
      throw new Error("An invoice item needs a title.")

    if not item.price?
      throw new Error("An invoice item needs a price.")

    if _.isString(item.quantity)
      item.quantity = (new Function("return #{item.quantity.replace(/\#/g, "//")};"))()

    item.quantity = Math.ceil(item.quantity)

    item.net_value = item.quantity * item.price
    item.tax_value = item.net_value * (item.tax_rate / 100)
    item.total_value = item.net_value * (1 + item.tax_rate / 100)

    item.net_value = roundCurrency(item.net_value)
    item.tax_value = roundCurrency(item.tax_value)
    item.total_value = roundCurrency(item.total_value)

    return item
  )

  data.totals =
    net: calculateNet(data.items)
    total: calculateTotal(data.items)
    tax: _.map(_.groupBy(data.items, "tax_rate"), (tax_group, tax_rate) ->
        return {
          rate : tax_rate,
          total : sum(_.pluck(tax_group, "tax_value"))
        }
      ).filter((tax) -> tax.total != 0)

  data


# Process arguments
inFilename = process.argv[2]
outFilename = replaceExtname(inFilename, ".pdf")

# console.log(tmpFilename)

data = yaml.safeLoad(fs.readFileSync(inFilename, "utf8"))
data = transformData(data)

tmpFilename = "#{__dirname}/templates/#{data.invoice.template}/#{"xxxx-xxxx-xxxx".replace(/x/g, -> ((Math.random() * 16) | 0).toString(16))}.html"


# Prepare rendering
handlebars.registerHelper("plusOne", (value) -> 
  return value + 1
)
handlebars.registerHelper("number", (value) ->
  return numeral(value).format("0[.]0")
)
handlebars.registerHelper("money", (value) ->
  return "#{numeral(value).format("0,0.00")} #{data.invoice.currency}"
)
handlebars.registerHelper("percent", (value) ->
  return numeral(value / 100).format("0 %")
)
handlebars.registerHelper("date", (value) ->
  return moment(value).format("LL")
)
handlebars.registerHelper("lines", (options) ->
  contents = options.fn()
  contents = contents.split(/<br\s*\/?>/)
  contents = _.compact(contents.map((a) -> a.trim()))
  contents = contents.join("<br>")
  return contents
)
handlebars.registerHelper("pre", (contents) ->
  return new handlebars.SafeString(contents.split(/\n/).map((a) -> handlebars.Utils.escapeExpression(a)).join("<br>"))
)
handlebars.registerHelper("t", (phrase) ->
  return translation[phrase] ? phrase
)

# Rendering
template = handlebars.compile(fs.readFileSync("#{__dirname}/templates/#{data.invoice.template}/main.html", "utf8"))
fs.writeFileSync(tmpFilename, template(data), "utf8")

wkhtmltopdf("file://#{tmpFilename}", { 
  output: outFilename,
  headerHtml: "#{__dirname}/templates/#{data.invoice.template}/header.html",
  footerHtml: "#{__dirname}/templates/#{data.invoice.template}/footer.html",
  marginLeft: "0mm",
  marginRight: "0mm",
}, ->
  console.log("Created #{outFilename}")
  fs.unlinkSync(tmpFilename)
)
