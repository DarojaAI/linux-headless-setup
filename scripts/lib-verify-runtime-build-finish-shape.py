import json, sys
j = json.loads(sys.stdin.read())
assert j['status'] in ('delegated', 'unhealthy')
assert set(j['signals'].keys()) == {'sudoers', 'bash-5.3'}
