import json, sys
with open(sys.argv[1]) as f:
    base = json.load(f)
with open("/dev/stdin") as f:
    defaults = json.load(f)
for k, v in defaults.items():
    if k not in base:
        base[k] = v
print(json.dumps(base, indent=2))
