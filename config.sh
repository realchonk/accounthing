## Vendor Information

vendor_name='Marxisum GmbH'
vendor_owner='Max Musterman'
vendor_address='Musteralle 42'
vendor_zip='12345 Musterhausen'
vendor_email='max@mustermann.example'
vendor_iban='DE02120300000000202051'
vendor_bic='BYLADEM1001'
vendor_bank='Deutsche Kreditbank Berlin'
vendor_taxID='079/123/12347'


## Git Integration

# Enable versioning of the databases with git (true/false).
enable_git=true

# Header of the commit message.
git_commit_msg="Automatic Update"

# Path to the git binary. (Leave empty for auto-detection)
GIT=""


## GNU Privacy Guard (gpg) Integration

# Enable encryption of the databases with gpg (true/false).
enable_gpg=true

# Path to the gpg binary. (Leave empty for auto-detection)
GPG=""


## Other options

# Enable caching of files (true/false)
# With this enabled, the program should run much faster.
enable_caching=true

# Enable debug output (true/false)
enable_debug=false

# The default description of a transaction.
tdb_default_desc="Homestuff"

# Directory, where invoices will be placed.
invoice_output_dir="$PWD"
