import json
from http.server import BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# not a db, but it works so
# this is the only part you'd wanna edit for this to work
STAFF_DATA = {
    "FinallyDefined": "Head Moderator",
    "AlternativelyZolars": "Senior Moderator",
    "Roblox": "VIP",
    "JonathanOOMF": "Moderator",
    "ARandomTMod": "Trial Moderator"
}

# this is the part where you shouldn't touch things
# unless, you wanted to modify the code to be more stable
# or just editing it overall, if you don't know how it works
# touching it might just break the entire thing

# cases stuff
STAFF_LOOKUP = {
    username.casefold(): rank
    for username, rank in STAFF_DATA.items()
}

# the entire brain of this thing
class handler(BaseHTTPRequestHandler):
    # handle gets
    def do_GET(self):
        query = parse_qs(urlparse(self.path).query)
        usernames = query.get("user", [])
        self.respond_safe(usernames)
    # handle posts
    def do_POST(self):
        content_length = int(
            self.headers.get("Content-Length", 0)
        )

        try:
            raw = self.rfile.read(content_length)
            body = json.loads(raw.decode("utf-8"))
            usernames = body.get("users", [])

            if not isinstance(usernames, list):
                usernames = []

        except json.JSONDecodeError:
            usernames = []

        self.respond_safe(usernames)
    # safe response
    def respond_safe(self, usernames):
        try:
            result = self.process_users(usernames)
            self.send_json_response(result)
        except Exception as e:
            self.send_error(500, str(e))
    # final formation
    def process_users(self, usernames):
        return [
            {
                "user": u,
                "is": STAFF_LOOKUP.get(
                    u.casefold()
                )
            }
            for u in usernames
        ]
    # server responding to your request
    def send_json_response(self, data):
        self.send_response(200)
        self.send_header(
            "Content-type",
            "application/json"
        )
        self.end_headers()

        payload = json.dumps(
            data,
            ensure_ascii=False
        ).encode("utf-8")

        self.wfile.write(payload)
