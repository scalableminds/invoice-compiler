#!/usr/bin/env coffee

_    = require("lodash")
fs   = require("fs")
path = require("path")
exec = require("child_process").exec
yaml = require("js-yaml")
moment = require("moment")
mkdirp = require("mkdirp")

moment.lang("de")
DATE_FORMAT = 'DD. MMMM YYYY'

replaceExtname = (filename, newExtname) ->
  return filename.replace(new RegExp(path.extname(filename).replace(/\./g, "\\."), "g"), newExtname)

roundCurrency = (value) ->
  if isNaN(value)
    value = 0
  return Math.round(value * 100) / 100


formatCurrency = (value) ->
  parts = roundCurrency(value).toString().split(".")
  if parts.length == 1
    parts.push("00")

  while parts[1].length < 2
    parts[1] += "0";

  return parts.join(",") + " €"

sum = (items) ->
  items.reduce(((r, a) -> r + a), 0)

calculateNet = (items) ->
  return sum(_.pluck(items, "net_value"))

calculateTotal = (items) ->
  return sum(_.pluck(items, "total_value"))


transformData = (data) ->

  _.defaults(data,
    invoice: {}
    receiver: {}
    items: []
    intro_text: ""
    outro_text: ""
  )

  data.invoice.date = moment(data.invoice.date).format(DATE_FORMAT)
  data.invoice.template ?= "default"

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
      item.quantity = (new Function("return #{item.quantity};"))()

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

inFilename = process.argv[2]
tmpFilename = path.join(__dirname, "tmp", "invoice-#{Math.round(Math.random() * 1e5)}.tex")
outFilename = replaceExtname(inFilename, ".pdf")

# console.log(tmpFilename)

data = yaml.safeLoad(fs.readFileSync(inFilename, "utf8"))
data = transformData(data)

template = _.template(fs.readFileSync("#{__dirname}/templates/#{data.invoice.template}.tex.template", "utf8"))

mkdirp.sync(path.dirname(tmpFilename))
fs.writeFileSync(tmpFilename, template(data), "utf8")

exec(
  "xelatex #{path.basename(tmpFilename)}"
  cwd : path.join(__dirname, "tmp")
  env : _.extend(
    {}
    process.env
    TEXINPUTS : ".:#{path.join(__dirname, "resources")}:"
  )
  (err) ->

    if fs.existsSync(replaceExtname(tmpFilename, ".aux"))
      fs.unlinkSync(replaceExtname(tmpFilename, ".aux"))

    if fs.existsSync(replaceExtname(tmpFilename, ".log"))
      fs.unlinkSync(replaceExtname(tmpFilename, ".log"))

    if fs.existsSync(replaceExtname(tmpFilename, ".out"))
      fs.unlinkSync(replaceExtname(tmpFilename, ".out"))

    if err
      throw err
    else
      fs.renameSync(replaceExtname(tmpFilename, ".pdf"), outFilename)

      if fs.existsSync(replaceExtname(tmpFilename, ".tex"))
        fs.unlinkSync(replaceExtname(tmpFilename, ".tex"))

      console.log("Saved to #{path.relative(process.cwd(), outFilename)}")
)

