# Rego Built-in Functions

Full reference: https://www.openpolicyagent.org/docs/latest/policy-reference/

## Strings

| Function | Signature | Notes |
|----------|-----------|-------|
| `concat` | `concat(delim, arr_or_set)` | Join strings |
| `contains` | `contains(str, search)` | Substring check |
| `startswith` | `startswith(str, prefix)` | |
| `endswith` | `endswith(str, suffix)` | |
| `lower` | `lower(str)` | |
| `upper` | `upper(str)` | |
| `trim` | `trim(str, cutset)` | Remove chars in cutset from both ends |
| `trim_prefix` | `trim_prefix(str, prefix)` | |
| `trim_suffix` | `trim_suffix(str, suffix)` | |
| `split` | `split(str, delim)` | Returns array |
| `replace` | `replace(str, old, new)` | |
| `sprintf` | `sprintf(fmt, values)` | Printf-style |
| `format_int` | `format_int(num, base)` | |
| `substring` | `substring(str, start, length)` | |
| `indexof` | `indexof(str, search)` | -1 if not found |
| `regex.match` | `regex.match(pattern, str)` | |
| `regex.find_all_string_submatch_n` | | Named capture groups |
| `glob.match` | `glob.match(pattern, delimiters, str)` | Shell-style glob |

## Numbers and Aggregates

```rego
count(collection)           # length of array, set, object, or string
sum([1, 2, 3])              # 6
product([2, 3, 4])          # 24
min([3, 1, 2])              # 1
max([3, 1, 2])              # 3
abs(-5)                     # 5
round(3.6)                  # 4
floor(3.9)                  # 3
ceil(3.1)                   # 4
numbers.range(1, 5)         # [1, 2, 3, 4, 5]
```

## Arrays

```rego
array.concat([1,2], [3,4])  # [1, 2, 3, 4]
array.slice([1,2,3,4], 1, 3) # [2, 3]
array.reverse([1,2,3])       # [3, 2, 1]
```

## Sets

```rego
intersection({s1, s2})      # elements in all sets
union({s1, s2})             # elements in any set
s1 & s2                     # intersection (operator)
s1 | s2                     # union (operator)
s1 - s2                     # difference (operator)
s1 < s2                     # proper subset
```

## Objects

```rego
object.get(obj, key, default)        # safe access with default
object.keys(obj)                     # set of keys
object.values(obj)                   # array of values
object.remove(obj, keys)             # remove keys (keys is array or set)
object.filter(obj, keys)             # keep only listed keys
object.union(obj1, obj2)             # merge (obj2 wins on conflicts)
object.union_n([obj1, obj2, obj3])   # merge N objects
json.filter(obj, paths)              # filter by dot-separated paths
json.remove(obj, paths)              # remove by dot-separated paths
json.patch(obj, patches)             # RFC 6902 JSON Patch
```

## Type Checking

```rego
is_string(x)
is_number(x)
is_boolean(x)
is_array(x)
is_set(x)
is_object(x)
is_null(x)
type_name(x)    # returns "string", "number", etc.
```

## Encoding / Decoding

```rego
json.marshal(x)                 # value -> JSON string
json.unmarshal(s)               # JSON string -> value
json.is_valid(s)                # bool
base64.encode(str)
base64.decode(str)
base64url.encode(str)
base64url.decode(str)
urlquery.encode(str)
urlquery.decode(str)
urlquery.encode_object(obj)
hex.encode(str)
hex.decode(str)
yaml.marshal(x)
yaml.unmarshal(s)
yaml.is_valid(s)
```

## Cryptography

```rego
crypto.md5(str)
crypto.sha1(str)
crypto.sha256(str)
crypto.hmac.md5(str, key)
crypto.hmac.sha1(str, key)
crypto.hmac.sha256(str, key)
crypto.hmac.sha512(str, key)
crypto.x509.parse_certificate(pem)
crypto.x509.parse_certificates(pem)
crypto.x509.parse_certificate_request(pem)
crypto.x509.parse_rsa_private_key(pem)
crypto.x509.verify_certificate_chain([cert, ...])
```

## Time

```rego
time.now_ns()                           # current time as nanoseconds
time.parse_rfc3339_ns("2024-01-01T00:00:00Z")
time.parse_ns(layout, value)            # Go time layout
time.format(ns)                         # ns -> RFC 3339 string
time.date(ns)                           # [year, month, day]
time.clock(ns)                          # [hour, minute, second]
time.weekday(ns)                        # "Monday", etc.
time.add_date(ns, years, months, days)
time.diff(ns1, ns2)                     # [years, months, days, hours, minutes, seconds]
```

## JWT / Tokens

```rego
io.jwt.decode(token)                    # [header, payload, sig] -- no verify
io.jwt.decode_verify(token, constraints) # [valid, header, payload]
io.jwt.verify_hs256(token, secret)
io.jwt.verify_rs256(token, cert_pem)
io.jwt.verify_es256(token, cert_pem)
io.jwt.encode_sign(header, payload, key)
io.jwt.encode_sign_raw(header_str, payload_str, key)
```

`constraints` object: `{"iss": "...", "aud": "...", "time": time.now_ns(), "cert": pem, "secret": str}`

## Networking

```rego
net.cidr_contains("192.168.1.0/24", "192.168.1.5")  # true
net.cidr_intersects("10.0.0.0/8", "10.1.0.0/16")    # true
net.cidr_expand("192.168.0.0/30")                    # set of IPs
net.cidr_merge(["10.0.0.0/8", "10.0.1.0/24"])       # ["10.0.0.0/8"]
net.lookup_ip_addr(name)                              # {"1.2.3.4"}
```

## OPA-Specific

```rego
opa.runtime()               # {"version": "...", "env": {...}, "config": {...}}
rego.metadata.rule()        # metadata annotations on current rule
rego.metadata.chain()       # metadata chain from current rule to package
trace(msg)                  # emit trace event (visible in --explain)
print(...)                  # debug print (disabled in bundles by default)
```

## HTTP (use with caution)

```rego
http.send({
  "method": "GET",
  "url": "https://...",
  "headers": {"Authorization": "Bearer ..."},
  "timeout": "5s",
  "cache": true,            # cache response
  "force_json_decode": true
})
# Returns: {"status_code": 200, "body": {...}, "headers": {...}}
```

`http.send` makes OPA I/O-bound instead of CPU-bound. Cache aggressively or
avoid in hot paths.

## Comprehensions and Iteration Patterns

```rego
# Iterate object keys
some key in object.keys(obj)

# Iterate array with index
some i, v in arr

# Exists quantifier (v1 syntax)
some x in collection
x == target

# Every quantifier (v1 syntax)
every x in collection {
    x > 0
}
```
