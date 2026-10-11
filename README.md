# learn-cli

One-line learnings, ideas and concepts in markdown, plus spaced-repetition study with an AI tutor.
Code only: each learning project gets its own command and keeps its data in `<project>/.learn-cli/`.

```sh
cd ~/pr26/some-project && learn-cli init some-cmd machine learning   # .learn-cli/ + ~/.local/bin/some-cmd
some-cmd cats add eval Metrics, validation, calibration                # categories jev files concepts into
some-cmd c add Overfitting · some-cmd l add ... · some-cmd learn       # from any folder
```

- Install: `ln -s ~/pr26/learn-cli/bin/learn-cli ~/.local/bin/learn-cli`.
- A project command is a 2-line wrapper: `LEARN_DIR=<project>/.learn-cli LEARN_NAME=<cmd> exec learn-cli "$@"`.
- Data per project: `learnings.md`, `ideas.md`, `concepts.md` (`> topic:` line sets the tutor's subject), `state.json`, `cards.json`, `config.json`.
- In use: `zca` (zhul-code-architect), `ml-lab`.
- Tests: `bin/test.sh` (offline, fake AI server).
