# invoice-compiler
Generate invoices from YAML files using [puppeteer](https://pptr.dev/).

## Install
```bash
npm install -g invoice-compiler
```

## Usage
```bash
invoice invoice.yml
# Outputs invoice.pdf
```

See `samples` directory for [an annotated sample](https://github.com/scalableminds/invoice-compiler/blob/master/samples/42.yml).

## Credits
The default template is based on a LaTeX class by Patrick Lühne, [https://www.luehne.de/](https://www.luehne.de/).

## License
MIT &copy; scalable minds 2019