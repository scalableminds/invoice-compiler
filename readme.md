# invoice-compiler
Generate invoices from YAML files using [wkhtmltopdf](http://wkhtmltopdf.org/).

## Install
```bash
npm install -g invoice-compiler
```

## Usage
```bash
invoice invoice.yml
# Outputs invoice.pdf
```

See `samples` directory for an annotated sample.


## Dependencies
* node & npm
* [wkhtmltopdf](https://github.com/devongovett/node-wkhtmltopdf#installation)
* [Open Sans](http://www.fontsquirrel.com/fonts/open-sans) font


## Credits
The default template is based on a LaTeX class by Patrick Lühne, [http://www.luehne.de/](http://www.luehne.de/).

## License
MIT &copy; scalable minds 2014