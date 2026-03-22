# Maestro Flows (360Ghar)

## Structure

- Shared subflows: `.maestro/_shared/`
- Route/journey flows: `.maestro/auth`, `.maestro/dashboard`, `.maestro/discover`, `.maestro/explore`, `.maestro/likes`, `.maestro/visits`, `.maestro/profile`, `.maestro/tools`, `.maestro/deeplink`
- Entrypoints:
  - `.maestro/smoke.yaml`
  - `.maestro/full.yaml`

## Run

```bash
cd /Users/sakshammittal/Documents/360ghar/github/360ghar/app
./scripts/run_maestro_smoke.sh ios
./scripts/run_maestro_full.sh ios
```

For Android:

```bash
cd /Users/sakshammittal/Documents/360ghar/github/360ghar/app
./scripts/run_maestro_smoke.sh android
./scripts/run_maestro_full.sh android
```
