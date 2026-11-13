# learn-cli

A terminal learning notebook with an AI tutor. Each subject gets its own command; its learnings, ideas and
concepts live as plain markdown in that project, and the tutor teaches, quizzes and answers with your map in mind.

```sh
learn-cli add mll machine learning --dir ~/ml-lab   # new project + the command `mll`
mll goal Ship an ML side project by March           # why you study it: shown and given to the tutor
mll c add Overfitting                               # concept: the AI files it and writes a one-line description
mll l add Always split before scaling               # learning · mll i add … for ideas
mll learn                                           # spaced repetition: lesson, 3 questions, graded
mll ask why does dropout regularize?                # tutor chat that knows your concepts, progress and goal
```

- **Concepts** are grouped in categories (`mll cats add <cat> <description>`); without `-c`, [jev](https://typesafe.ai) picks one.
- **learn** schedules reviews (Leitner boxes); a weak concept gets a lesson first, cached once written.
- **ask** keeps the thread for follow-ups; `/c` saves a concept it suggests, `/l` `/i` save notes.
- `mll` alone shows an overview; `mll -h` and `learn-cli -h` list everything.

## Install

```sh
git clone https://github.com/jeancarlo-javier/learn-cli && ln -s "$PWD/learn-cli/bin/learn-cli" ~/.local/bin/
export OPENAI_API_KEY=…    # or LLM_BASE_URL + LLM_API_KEY (+ LLM_MODEL) for any OpenAI-compatible API
export TYPESAFE_API_KEY=…  # optional: auto-filing concepts; without it they go to inbox
```

Needs bash and Python 3.12+, no packages. Per project: `<cmd> ai --model <id> --effort <e> --url <u>`.

## Data

`<project>/.learn-cli/`: `learnings.md`, `ideas.md`, `concepts.md` (topic, goal, categories, entries), plus
`state.json` (schedule), `cards.json` (lessons), `config.json` (AI settings). Project commands are small wrappers
in `~/.local/bin` (`LEARN_BIN` overrides); `learn-cli rm` removes one and keeps the data.

Tests: `bin/test.sh` (offline, fake AI server).
