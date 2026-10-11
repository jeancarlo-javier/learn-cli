#!/bin/bash
# Self-check: runs zca against a temp dir. Exit 0 = pass.
Z=$(cd "$(dirname "$0")" && pwd)/zca
# a clean env: no AI settings inherited (LLM_*, the keys, the removed per-tool vars)
unset ZCA_HOME
for v in $(env | grep -oE '^(LLM_[A-Z_]*|OPENAI_API_KEY|TYPESAFE_API_KEY|ZCA_MODEL|ZCA_API_URL)'); do unset "$v"; done
export ZCA_DIR=$(mktemp -d); trap 'rm -rf "$ZCA_DIR"' EXIT
fail() { echo "FAIL: $1"; exit 1; }
rc() { "$Z" "$@" >/dev/null 2>&1; echo $?; }
[ "$(rc)" = 0 ] || fail "overview"
[ "$(rc learnings)" = 0 ] || fail "ls empty"
T='a/b & c | d "q" '"'s' \\1 \\n"
"$Z" learnings add "$T" >/dev/null || fail add
"$Z" learnings add second >/dev/null
[ "$(head -1 "$ZCA_DIR/learnings.md")" = "# Learnings" ] || fail heading
"$Z" learnings | grep -qF "$T" || fail "special text"
id=$("$Z" learnings | awk 'NR==2{print $2}')
[ "$("$Z" learnings add third | awk '{print $1}')" = 3 ] || fail "add prints #"
"$Z" learnings edit 2 'new & text' >/dev/null || fail "edit #"
"$Z" learnings edit "$id" 'newer | text' >/dev/null || fail "edit id"
"$Z" learnings | awk 'NR==2' | grep -q "$id .*newer | text" || fail "edit result"
"$Z" learnings rm "$id" | grep -q "newer | text" || fail "rm prints"
[ "$("$Z" learnings | wc -l | tr -d ' ')" = 2 ] || fail "rm count"
"$Z" ideas add idea >/dev/null; grep -q '^# Ideas' "$ZCA_DIR/ideas.md" || fail ideas
[ "$(rc learnings rm 9)" = 1 ] || fail "unknown #"
[ "$(rc learnings rm 1234)" = 1 ] || fail "unknown id"
for c in "x" "learnings nope" "learnings add" "learnings edit 1" \
  "learnings rm" "learnings rm 1 2" "learnings rm abc" "learnings rm 12345" "--bogus" "-h x" "ideas -h x" "learnings ls"; do
  [ "$(rc $c)" = 2 ] || fail "strict: $c"
done
for c in -h --help "learnings -h" "ideas -h"; do [ "$(rc $c)" = 0 ] || fail "help $c"; done
"$Z" i | grep -q idea || fail "alias i"
[ "$("$Z" l | wc -l | tr -d ' ')" = 2 ] || fail "alias l"
"$Z" l add viaalias >/dev/null; grep -q viaalias "$ZCA_DIR/learnings.md" || fail "alias add"
# the seed is only an inbox; these two stand in for a project's own categories
printf '# Concepts\n\n## principles\n> Design rules.\n\n## architecture\n> System structure.\n\n## inbox\n> Concepts not filed yet.\n' > "$ZCA_DIR/concepts.md"
# concepts: offline (no key) -> inbox; -c files directly; jev itself is checked by hand
"$Z" c add SOLID -c principles >/dev/null 2>&1 || fail "c add -c"
"$Z" cats principles | grep -q SOLID || fail "cats <cat>"
[ "$(rc c add solid)" = 1 ] || fail "dup"
[ "$(rc c add X -c nope)" = 2 ] || fail "unknown cat"
[ "$(rc l add X -c principles)" = 2 ] || fail "-c on learnings"
"$Z" c add MVP 2>&1 >/dev/null | grep -q inbox || fail "offline -> inbox"
"$Z" cats inbox | grep -q MVP || fail "in inbox"
"$Z" c mv 2 architecture >/dev/null 2>&1; "$Z" cats architecture | grep -q MVP || fail "mv"
[ "$("$Z" c | grep -c '^[a-z]')" = 2 ] || fail "grouped headers"
[ "$(rc cats add Bad_Name desc)" = 2 ] || fail "kebab"
"$Z" cats add mobile Apps móviles --not "web frontends" >/dev/null 2>&1 || fail "cats add"
grep -A2 '^## mobile' "$ZCA_DIR/concepts.md" | grep -q '> not: web frontends' || fail "cats add --not"
[ "$(rc cats add mobile x)" = 1 ] || fail "cats dup"
[ "$(rc cats rm architecture)" = 1 ] || fail "rm non-empty"
"$Z" cats rm mobile >/dev/null 2>&1 && ! grep -q '## mobile' "$ZCA_DIR/concepts.md" || fail "cats rm"
"$Z" cats | grep -q '^principles *1' || fail "cats counts"
# learn + ai: fake OpenAI server; its log counts model calls by kind (lesson / quiz / grade)
# shared LLM_*: model + effort under the saved choice, a key only to its own URL, unknown effort never sent
LLM_EFFORT=' High ' "$Z" ai | grep -q '^effort  high .*LLM_EFFORT' || fail "LLM_EFFORT normalized"
LLM_EFFORT=turbo "$Z" ai | grep -q '^effort  none' || fail "unknown LLM_EFFORT ignored"
OPENAI_API_KEY=k LLM_BASE_URL=https://x.test/v1 "$Z" ai | grep -q 'LLM_API_KEY missing' || fail "key paired with its URL"
python3 - "$ZCA_DIR/srv" <<'PY' &
import json, sys, http.server
p = sys.argv[1]
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def send(self, o):
        b = json.dumps(o).encode(); self.send_response(200); self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_GET(self): open(p + ".auth", "a").write(f"{self.headers.get('Authorization')}\n"); self.send({"data": [{"id": "gpt-6-luna"}, {"id": "gpt-6-luna-mini"}]})
    def do_POST(self):
        b = json.loads(self.rfile.read(int(self.headers["Content-Length"]))); ask = b["messages"][-1]["content"]
        kind = "lesson" if "Write a lesson" in ask else "quiz" if "Design 3" in ask else "grade"
        open(p + ".log", "a").write(f"{kind} {b.get('reasoning_effort')}\n"); open(p + ".sys", "a").write(b["messages"][0]["content"] + "\n"); open(p + ".auth", "a").write(f"{self.headers.get('Authorization')}\n")
        o = {"lesson": {"what": "LESSON-WHAT", "why": "w", "how": "h", "example": "e", "tradeoffs": ["t1", 7], "confuse": "", "remember": "REMEMBER"},
             "quiz": {"questions": [{"q": f"Q{i}?", "a": f"REF{i}"} for i in (1, 2, 3)]},
             "grade": {"score": 2, "per": [{"ok": 2, "fix": ""}, {"ok": 0, "fix": "FIX2"}, {"ok": 2}], "feedback": "FB", "note": "N"}}[kind]
        self.send({"choices": [{"message": {"content": json.dumps(o)}}]})
s = http.server.ThreadingHTTPServer(("127.0.0.1", 0), H); open(p, "w").write(str(s.server_port)); s.serve_forever()
PY
SRV=$!; trap '{ kill $SRV; wait $SRV; } 2>/dev/null; rm -rf "$ZCA_DIR"' EXIT
while [ ! -s "$ZCA_DIR/srv" ]; do sleep 0.1; done
S=http://127.0.0.1:$(cat "$ZCA_DIR/srv"); export LLM_BASE_URL=$S
L=$ZCA_DIR/srv.log; calls() { grep -c "^$1" "$L" 2>/dev/null; }
"$Z" | grep -q '2 due today' || fail "overview due"
o=$(printf '\n\n?\n\n' | "$Z" learn solid 2>&1)   # new -> lesson first; no answers -> refs shown, 0 by code
echo "$o" | grep -q LESSON-WHAT && echo "$o" | grep -q REF3 && echo "$o" | grep -q 'not yet' || fail "learn new: $o"
[ "$(calls lesson) $(calls quiz) $(calls grade)" = "1 1 0" ] || fail "learn new calls"
grep -q 'lesson none' "$L" || fail "effort none for gpt-6"
grep -q 'expert in software engineering' "$ZCA_DIR/srv.sys" || fail "default topic"
python3 -c "import json,sys; s=json.load(open(sys.argv[1]))" "$ZCA_DIR/.zca-learn.json" || fail "state json"
o=$(printf '\na\nb\nc\nq\n' | "$Z" learn 1 2>&1)  # box 0 again: cached lesson; graded early -> box stays
[ "$(calls lesson) $(calls grade)" = "1 1" ] || fail "lesson cached"
echo "$o" | grep -q FIX2 && echo "$o" | grep -q 'box 0/5' && echo "$o" | grep -q 'keeps the schedule' || fail "early: $o"
echo "$o" | grep -q 'Enter: next (MVP)' || fail "chains to next due"
[ "$(rc ai --effort bogus)" = 2 ] || fail "ai bad effort"
[ "$(rc ai --model nope)" = 1 ] || fail "ai unknown model"
"$Z" ai --model gpt-6-luna-mini --effort low | grep -q 'effort  low' || fail "ai set"
printf '\n\n\n\n' | "$Z" learn MVP >/dev/null 2>&1; grep -q 'quiz low' "$L" || fail "chosen effort sent"
[ "$(rc learn nothing-like-this)" = 1 ] || fail "learn unknown ref"
due() { python3 -c "import json,sys; p=sys.argv[1]; d=json.load(open(p)); d[sys.argv[2]].update(due='2000-01-01', box=2); json.dump(d, open(p,'w'))" "$ZCA_DIR/.zca-learn.json" "$1"; }
sid=$(grep -o '\[[0-9]*\] [0-9-]* SOLID' "$ZCA_DIR/concepts.md" | cut -c2-5); due "$sid"
o=$(printf 'a\n?\nc\nq\n' | "$Z" learn SOLID 2>&1)   # due, model says solid, one peek -> partial, box stays
echo "$o" | grep -q 'partial' && echo "$o" | grep -q 'box 2/5' || fail "peek caps score: $o"
due "$sid"; printf '?\nq\n' | "$Z" learn SOLID >/dev/null 2>&1   # peek then q -> recorded as not known
grep -A1 "\"$sid\"" "$ZCA_DIR/.zca-learn.json" | grep -q '"box": 0' || fail "peek then q counts"
# ai settings: saved > LLM_* > default for model/effort/url, clearing, --url, the key follows the url
AD=$ZCA_DIR/ai; mkdir "$AD"; A() { ZCA_DIR=$AD "$Z" "$@"; }; N() { env -u LLM_BASE_URL ZCA_DIR=$AD "$Z" "$@"; }
cfg() { python3 -c "import json,sys; print(json.dumps(json.load(open(sys.argv[1])), sort_keys=True))" "$AD/.zca-config.json"; }
DEAD=http://127.0.0.1:1
A ai | grep -q "^model   gpt-6-luna .*(default)" || fail "label model default"
A ai | grep -q "^effort  none .*(default)" || fail "label effort default"
N ai | grep -q "^api     https://api.openai.com/v1 .*(default) · OPENAI_API_KEY missing" || fail "label url default"
A ai | grep -q "^api     $S .*(set by LLM_BASE_URL)" || fail "label url LLM_BASE_URL"
LLM_MODEL=m1 LLM_EFFORT=low A ai | grep -q "^model   m1 .*(set by LLM_MODEL)" || fail "LLM_MODEL beats default"
A ai --model gpt-6-luna-mini --effort high --url "$S/" >/dev/null || fail "ai set all"
[ "$(cfg)" = "{\"effort\": \"high\", \"model\": \"gpt-6-luna-mini\", \"url\": \"$S\"}" ] || fail "saved, url without slash"
o=$(LLM_MODEL=m1 LLM_EFFORT=low LLM_BASE_URL=$DEAD A ai)
echo "$o" | grep -qx "model   gpt-6-luna-mini" && echo "$o" | grep -qx "effort  high" && echo "$o" | grep -qx "api     $S · none" || fail "saved beats LLM_*, no label: $o"
[ "$(LLM_BASE_URL=$DEAD rc ai)" = 0 ] || fail "ai without flags needs no network"
LLM_BASE_URL=$DEAD A ai --model '' --effort default --url '' >/dev/null || fail "clear, no network"
[ "$(cfg)" = "{}" ] || fail "cleared with ''/default"
A ai --url "$S" --effort low >/dev/null; A ai --effort '' >/dev/null; [ "$(cfg)" = "{\"url\": \"$S\"}" ] || fail "clear one field only"
A ai --url '' >/dev/null
[ "$(ZCA_DIR=$AD rc ai --effort low --url ftp://x)" = 2 ] && [ "$(cfg)" = "{}" ] || fail "bad url saves nothing"
[ "$(ZCA_DIR=$AD rc ai --effort low --model nope)" = 1 ] && [ "$(cfg)" = "{}" ] || fail "bad model saves nothing"
LLM_BASE_URL=$DEAD A ai --url "$S" --model gpt-6-luna-mini >/dev/null || fail "--model validated at the --url of the same call"
A ai --url '' --model '' >/dev/null
# the key follows the effective url: OPENAI_API_KEY never to LLM_BASE_URL or a custom url, LLM_API_KEY never to OpenAI
J=$ZCA_DIR/srv.auth; : > "$J"
o=$(OPENAI_API_KEY=oai-k LLM_API_KEY=llm-k A ai --model gpt-6-luna 2>&1)
grep -q 'Bearer llm-k' "$J" && ! grep -q oai-k "$J" && ! echo "$o" | grep -q -e llm-k -e oai-k || fail "LLM_BASE_URL gets LLM_API_KEY only"
: > "$J"; OPENAI_API_KEY=oai-k LLM_API_KEY=llm-k LLM_BASE_URL=$DEAD A ai --url "$S" --model gpt-6-luna >/dev/null || fail "custom url"
! grep -q Bearer "$J" || fail "custom url gets no key"
A ai --url '' >/dev/null
LLM_API_KEY=llm-k N ai | grep -q 'OPENAI_API_KEY missing' || fail "LLM_API_KEY not for OpenAI"
OPENAI_API_KEY=oai-k N ai | grep -q 'OPENAI_API_KEY set' || fail "OPENAI_API_KEY for OpenAI"
LLM_BASE_URL=https://x.test/v1 A ai --model foo 2>&1 | grep -q 'export LLM_API_KEY' || fail "hint names the url's key var"
A ai --url https://y.test/v1 | grep -q 'key missing' || fail "custom remote url: key missing"
echo '[]' > "$ZCA_DIR/.zca-learn.json"; [ "$(rc)" = 0 ] || fail "bad state shape"
# projects: init writes the topic, any subfolder finds its project, no project -> exit 1
P=$ZCA_DIR/proj; mkdir -p "$P/a/b"; U() { (cd "$1" && shift && env -u ZCA_DIR "$Z" "$@" >/dev/null 2>&1; echo $?); }
[ "$(U "$P" init machine learning)" = 0 ] && grep -qx '> topic: machine learning' "$P/concepts.md" || fail "init"
[ "$(U "$P" init x)" = 1 ] || fail "init twice"
U "$P/a/b" l add deep >/dev/null; grep -q deep "$P/learnings.md" || fail "walk up"
[ "$(cd / && env -u ZCA_DIR -u ZCA_HOME "$Z" l >/dev/null 2>&1; echo $?)" = 1 ] || fail "no project"
[ "$(cd / && env -u ZCA_DIR ZCA_HOME=$P "$Z" l | grep -c deep)" = 1 ] || fail "ZCA_HOME fallback"
ZCA_DIR=$P "$Z" c add Overfitting >/dev/null 2>&1; printf '\n\n\n\n' | ZCA_DIR=$P "$Z" learn Overfitting >/dev/null 2>&1
grep -q 'expert in machine learning' "$ZCA_DIR/srv.sys" || fail "topic in prompt"
echo PASS
