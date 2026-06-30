# OPA Bundles

Full reference: https://www.openpolicyagent.org/docs/latest/management-bundles/

## Bundle Structure

```
bundle.tar.gz
  /policies/
    authz.rego
    rbac.rego
  /data/
    data.json           # loaded as data.*
  /.manifest            # required for roots
```

`.manifest` file:

```json
{
  "revision": "20240101-v1",
  "roots": ["authz", "rbac"],
  "metadata": {
    "required_builtins": {
      "builtin_names": []
    }
  }
}
```

**`roots` semantics:**
- Omitting `roots` defaults to `[""]` -- OPA treats the bundle as owning ALL
  policy and data. No other source can write to any path.
- Specify roots to allow multiple bundles to coexist. Each bundle owns its
  listed root paths.
- REST API blocks modification of bundle-owned paths by default.

## OPA Config for Bundle Polling

```yaml
bundles:
  authz:
    resource: "/bundles/authz.tar.gz"
    polling:
      min_delay_seconds: 10
      max_delay_seconds: 60
    persist: true               # cache to disk for cold-start resilience
    signing:
      keyid: my-key
      verification_key: |
        -----BEGIN PUBLIC KEY-----
        ...
        -----END PUBLIC KEY-----

services:
  default:
    url: https://bundle-server.example.com
    credentials:
      bearer:
        token_path: /var/run/secrets/bundle-token
```

## Serving Bundles

### nginx (simplest)

```nginx
server {
    listen 443 ssl;
    root /var/bundles;
    location /bundles/ {
        autoindex off;
    }
}
```

Rebuild + replace the tarball; OPA polls and reloads automatically.

### S3 / GCS

Use a pre-signed URL or service account with object read. OPA supports AWS,
GCS, and Azure Blob via `credentials` config:

```yaml
services:
  s3:
    url: https://my-bucket.s3.amazonaws.com
    credentials:
      s3_signing:
        environment_credentials: {}   # uses AWS_ACCESS_KEY_ID etc.
```

### OCI Bundles

OPA can pull bundles stored as OCI artifacts:

```yaml
bundles:
  authz:
    resource: "my-registry.example.com/policies/authz:v1"
    type: oci
```

Use `opa build --bundle` to create the tarball, then push with
`oras push` or similar.

## Building Bundles

```bash
# Basic build
opa build -b ./policies/ -o bundle.tar.gz

# Optimized (partial eval)
opa build -O2 -b ./policies/ -o bundle.tar.gz

# Target Wasm
opa build -t wasm -e 'authz/allow' ./policies/authz.rego -o bundle.tar.gz

# Target plan (IR)
opa build -t plan -e 'authz/allow' ./policies/authz.rego -o bundle.tar.gz

# Sign the bundle
opa build --signing-key private.pem --signing-plugin jwt_plugin \
  -b ./policies/ -o signed-bundle.tar.gz
```

## Delta Bundles

Delta bundles patch data without a full re-download. Constraints:

- Can only modify **data**, not policies or Wasm resolvers.
- Not persisted to disk even when `persist: true` is configured.
- Require a snapshot bundle to have been loaded first.
- Use JSON Patch format (`add`, `remove`, `replace`, `copy`, `move`).

```json
{
  "data": [
    {"op": "add",    "path": "/roles/alice", "value": ["admin"]},
    {"op": "remove", "path": "/roles/bob"}
  ]
}
```

## Bundle Status and Activation

OPA exposes bundle status via `/v1/status`:

```json
{
  "bundles": {
    "authz": {
      "active_revision": "20240101-v1",
      "code": "",
      "type": "snapshot",
      "etag": "...",
      "last_successful_activation": "2024-01-01T00:00:00Z",
      "last_successful_download": "2024-01-01T00:00:00Z",
      "last_successful_request": "2024-01-01T00:00:00Z"
    }
  }
}
```

Once a bundle is downloaded and parsed, policies and data are enforced
atomically at activation time -- no partial state window.

## Bundle Signing

```bash
# Generate key pair
openssl genrsa -out private.pem 2048
openssl rsa -in private.pem -pubout -out public.pem

# Sign during build
opa build --signing-key private.pem -b ./policies/ -o signed.tar.gz

# Config to verify
bundles:
  authz:
    resource: /bundles/signed.tar.gz
    signing:
      keyid: mykey
      verification_key_path: /etc/opa/public.pem
```

If verification fails, OPA refuses to activate the bundle and logs an error.
