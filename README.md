# Accounting software for Chads

## Description
`accounthing.sh` is a command line accounting system that keeps tracks of customer and transactions, with the ability to generate invoices.

This project was created for a relative of mine,
therefore everything is made for the German accounting system,
but you could modify this project to fit your local needs.

Click [here](./invoice_example.pdf) to see an example invoice. \
Click [here](https://stuerz.xyz/generic-accounthing.1.html) to read the online manual.

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
- Unit price
- Short Description

### How data is stored
The customer and transaction information is stored in two separate CSV files ("databases").
By default, databases are encrypted using GPG and contain the information in a stripped down version of the CSV format,
where fields that contain text enclosed in double-quotes (e.g., "House cleaning, other stuff") are not allowed.

Customer information is stored in `customers.csv.gpg` and the transaction information is stored in `transactions_YEAR.csv.gpg`,
where year matches the year of the transaction (`YYYY`).
(If encryption with GPG is disabled, the `.gpg` file extension is dropped.)

Both files are typically stored in the `${prefix}/db` directory, where `${prefix}` is the path `accounthing.sh` and supporting files are located.

### Invoice generation
The files used to generate invoices are found under `${prefix]/invoice/`.

Invoices are generated from a `template.tex` file which uses a customized `invoice.cls` class. The template is written in LaTeX and the resulting invoice is a PDF.

By default, a logo `Logo.png` is used at the top of the invoice. The template file `Logo.xcf` is provided that should be edited with GIMP. You should only change the size of the logo if you intend to use a different paper format than DIN A4.

Feel free to modify these files to fit your need.

## Usage
### Managing Customers
To create a new customer:
```
accounthing -ac
```
*This same option can be used to edit an existing customer: execute `accounthing.sh -ac` and provide an existing CID, which will allow you to change any values when prompted by the interactive tool.*

To search a customer:
```
accounthing -sc name/ID
```

To remove a customer:
```
accounthing -rc name/ID
```

To list all customers:
```
accounthing -lc
```

### Managing Transactions
To create a new transaction:
```
accounthing -at
```

To create a new transaction directly from the command line:
```
accounthing -atc CID date num [price] description
```
Where `CID` is the customer ID, and the `price`, if not specified, is taken from the default customer price.

To list all transactions:
```
accounthing -lt [year]
```
If no `year` is provided, the current year is used.

*Currently there is no option to list transactions of multiple years.*

### Creating Invoices
To generate invoices for all matching transactions:
```
accounthing -i [term]
```
By default `term` is the current month.
For more information on which terms are allowed,
please refer to the [manual](https://stuerz.xyz/generic-accounthing.1.html).

### Dump Database Contents
To dump the contents of the customer database:
```
accounthing -pc
```

To dump the contents of the transactions database (for the current year):
```
accounthing -pt
```
### Interactive Mode
There is an (currently incomplete) interactive mode accessible by running:
```
accounthing -I
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

### GPG does not work
1. Make sure GPG is installed and properly configured.

2. Confirm the default key can be used to encrypt and decrypt:
    ```
    echo "Hello World" | gpg -e --default-recipient-self | gpg -d
    ```
    This should print "Hello World" to the screen.

3. Confirm `GPG_TTY` is set in the current shell:
    ```
    export GPG_TTY=$(tty)
    ```

    If nothing helps, you can disable encryption with GPG in the config.
