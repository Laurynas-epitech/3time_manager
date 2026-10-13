"""Read-only authenticated smoke on a pre-provisioned fictional manager account.
JSON keys: url (HTTPS origin), email, password, team_id. Never prints credentials.
"""
import datetime
import http.cookiejar
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

config = json.load(open(sys.argv[1], encoding="utf-8"))
origin = config["url"].rstrip("/")
assert urllib.parse.urlsplit(origin).scheme == "https"
jar = http.cookiejar.CookieJar()
client = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))

def request(path, body=None, csrf=None):
    headers = {"Content-Type": "application/json"}
    if csrf:
        headers["X-CSRF-Token"] = csrf
    req = urllib.request.Request(origin + "/api" + path,
        data=json.dumps(body).encode() if body is not None else None, headers=headers)
    with client.open(req, timeout=15) as response:
        data = response.read()
        return json.loads(data) if data else None

for attempt in range(12):
    try:
        request("/auth/me")
        raise AssertionError("Anonymous API request succeeded")
    except urllib.error.HTTPError as error:
        if error.code == 401:
            break
        if attempt == 11:
            raise
    except urllib.error.URLError:
        if attempt == 11:
            raise
    time.sleep(5)

login = request("/auth/login", {"email": config["email"], "password": config["password"]})
csrf = login["csrf_token"]
cookie = next(cookie for cookie in jar if cookie.name == "tm_jwt")
assert cookie.secure and cookie.has_nonstandard_attr("HttpOnly")
user = request("/auth/me", csrf=csrf)["data"]
assert user["role"] == "manager", "Use a restricted fictional manager fixture"
request(f'/workingtime/{user["id"]}', csrf=csrf)
request(f'/clocks/{user["id"]}', csrf=csrf)
today = datetime.datetime.now(datetime.timezone.utc).date().isoformat()
query = urllib.parse.urlencode({"start": today, "end": today, "timezone": "UTC"})
request(f'/teams/{int(config["team_id"])}/report?{query}', csrf=csrf)
try:
    request("/teams", {"team": {"name": "Forbidden smoke"}}, csrf)
    raise AssertionError("Manager created an admin-only team")
except urllib.error.HTTPError as error:
    assert error.code == 403
request("/auth/logout", {}, csrf)
print("PASS: trusted HTTPS, anonymous denial, Secure/HttpOnly login, CSRF, authorized report/clock reads and role denial")
