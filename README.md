# qa-automation-scripts
Collection of bash scripts used on the QA automation machine for environment setup, test execution, and utility tasks.

## tools_script

Backup of `~/tools_script` from the device-farm PC (Marcella). Secrets are not hardcoded; scripts read them from env vars listed in `tools_script/.env.example`.

Secrets are stored encrypted in `tools_script/.env.gpg` (GPG symmetric, AES256). The passphrase is kept outside the repo.

```bash
cd tools_script
./secrets.sh decrypt        # .env.gpg -> .env (gitignored), then edit values
./secrets.sh encrypt        # .env -> .env.gpg, commit .env.gpg
source ./secrets.sh load    # export secrets into the current shell without writing .env
```

Set `TOOLS_SCRIPT_GPG_PASSPHRASE` to skip the passphrase prompt.
