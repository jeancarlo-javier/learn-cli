# learn-cli

One-line learnings, ideas and concepts in markdown, plus spaced-repetition study with an AI tutor.
Code only: each learning project gets its own command and keeps its data in `<project>/.learn-cli/`.

```sh
learn-cli add mll machine learning --dir ~/pr26/ml-lab   # .learn-cli/ there + the command mll in ~/.local/bin
learn-cli                                                   # list projects · learn-cli -h
mll cats add eval Metrics, validation, calibration       # inside a project, from any folder
mll c add Overfitting · mll l add ... · mll learn · mll -h
```

- `learn-cli` alone manages projects: `ls`, `add`, `edit --name|--topic`, `rm` (removes the command, keeps the data).
- Install: `ln -s ~/pr26/learn-cli/bin/learn-cli ~/.local/bin/learn-cli`.
- A project command is a small wrapper in `~/.local/bin` (`LEARN_BIN` overrides) tagged `# learn-cli project`: those files are the registry.
- Data per project: `learnings.md`, `ideas.md`, `concepts.md` (`> topic:` line sets the tutor's subject), `state.json`, `cards.json`, `config.json`.
- Tests: `bin/test.sh` (offline, fake AI server).
