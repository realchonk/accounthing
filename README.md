# Accounting software for Chads

## Description
This project was created for a relative of mine,
therefore everything is made for the German accounting system,
but you could modify this project to fit your local needs.
There are customers and transactions.
A transaction corresponds to an entry in the resulting invoice.

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
The customer and transaction information is stored in two separate files.
One is called `customers.csv.gpg` and the other one is `transactions.csv.gpg`.
Both files are typically stored in the `${prefix}/db` directory.
You can dump the contents of the customer database with `accounthing -pc`
and the transaction database with `accounting -pt`.
Both databases are encrypted with gpg and contain the information in a stripped down version of the CSV format,
the change being that fields that contain text enclosed in double-quotes (eg. "House cleaning, other stuff") are not allowed.

## Configuration
You can change some parameters in the config file.
Before the installation, it is named `config.sh`,
after the installation, it is named `accounthing.conf` and typically resides in the `${prefix}/etc` directory.

## Installation
Issue `./install.sh -h` for installation instructions.

## Dependencies
- bash
- gpg
- git (optional)
