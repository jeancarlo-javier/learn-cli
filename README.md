# learn-cli

`zca`: one-line learnings, ideas and concepts in markdown, plus spaced-repetition study with an AI tutor.
Code only: each learning project keeps its own data next to its `concepts.md`.

```sh
cd ~/pr26/some-project && zca init machine learning   # concepts.md with "> topic: ..." + inbox
zca cats add eval Metrics, validation, calibration      # categories jev files concepts into
zca c add Overfitting · zca l add ... · zca learn
```

- Project = nearest folder up from `$PWD` with a `concepts.md`; else `$ZCA_HOME`; `$ZCA_DIR` overrides both.
- Data per project: `learnings.md`, `ideas.md`, `concepts.md`, `.zca-learn.json`, `.zca-cards.json`, `.zca-config.json`.
- Tests: `bin/zca-test.sh` (offline, fake AI server).
