# Accounting software for Chads

## Description
This project was created for a relative of mine,
therefore everything is made for the German accounting system,
but you could modify this project to fit your local needs.

There are customers and transactions, where a transaction corresponds to an entry in the resulting invoice.

Click [here](./invoice_example.pdf) to see an example invoice.

#### Each customer has the following information:
- A unique customer ID
- Full name of the customer
- Address of the customer (incl. ZIP code and City)
- Default hourly/unit cost

#### Each transaction has the following information:
- A unique transaction ID
- Related customer ID
- Date
- Number of hours/units
- Total
- Short Description

### How data is stored
The customer and transaction information is stored in two separate CSV files ("databases").
By default, databases are encrypted using GPG and contain the information in a stripped down version of the CSV format,
where fields that contain text enclosed in double-quotes (e.g., "House cleaning, other stuff") are not allowed.

Customer information is stored in `customers.csv.gpg` and the transaction information is stored in `transactions_YEAR.csv.gpg`,
where year matches the year of the transaction (`YYYY`).
(If encryption with GPG is disabled, the `.gpg` file extension is dropped.)

Both files are typically stored in the `${prefix}/db` directory, where `${prefix}` is the path `accounthing.sh` and supporting files are located.

## Usage

### Interactive Mode
There is an (currently incomplete) interactive mode accessible by running `accounthing -I`.

### Managing Customers
New customers can be created with `accounthing -ac`.
Customers can also be similarly edited, by providing the customer ID.
A list of customers can be optained with the `accounthing -lc`
You can also search (`accounthing -sc term`) and remove (`accounthing -rc ID/name`) customers.

### Managing Transactions
The options for managing transactions are the same as managing customer,
but instead of `c`, you'll use `t`.
For example, to create a transaction you type `accounthing -at`.
You can also add transactions, for example from an external script with `accounthing -atc CID date num [total] description`,
with CID being the customer ID, which can be found with `accounthing -lc`.
The only exception is listing transactions, for which you'll use `accounthing -lt [year]`.
If no year is specified, the current year is used.
Currently there is no option to list transaction of multiple years.

### Creating Invoices
You can generate all invoices for the current month with `accounthing -ia`.
If you want to generate invoices for a different month, for example the July of 2021,
run `accounthing -ia 2021-07`.
You can also create an invoice for a single customer with `accounthing -i customer month`. 
Invoices are generated from a `template.tex` file which uses a customized `invoice.cls` class.
The template is written in LaTeX and the resulting invoice is a PDF.
By default, a logo (`${prefix}/invoice/Logo.png`) is used at the top of the invoice.
The template file `Logo.xcf` is provided that should be edited with GIMP.
You should only change the size of the logo if you intend to use a different paper format than DIN A4.
Feel free to modify these files to fit your need.

### Dump Database Contents
To dump the contents of the customer database:
```
accounthing -pc
```

To dump the contents of the transactions database (for the current year):
```
accounthing -pt
```

## Configuration
The default configuration path is `${prefix}/etc/${conffile}`, where `${conffile}` is `config.sh` and later renamed to `accounthing.conf`.

You can customize the configuration of `accounthing.sh`, including, but not limited to:

- Git version control integration
- GPG encryption
- Accounting system default information

## Installation
You don't have to install this project,
to use it, but if you want to
issue `./install.sh -h` for installation instructions.

### Dependencies
- bash
- gpg (optional)
- git (optional)
- dialog (optional, only for interactive mode)
- pdflatex and LaTeX modules (`texlive-most` on Arch Linux)

## Troubleshooting

#### GPG does not work.
Make sure GPG is installed and properly configured. \
Run `echo "Hello World" | gpg -e --default-recipient-self | gpg -d`. \
This should print "Hello World" to the screen. \
If not, something is wrong with your GPG setup. \
Sometimes you just need to `export GPG_TTY=$(tty)`. \
If nothing helps, you can disable encryption with GPG in the config.
