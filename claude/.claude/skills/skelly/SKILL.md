---
name: skelly
description: Use when asked to create or scaffold a new project, service, CLI or repository from a template, or when skelly is mentioned.
---

# skelly

`skelly` creates a project from a template (a directory, git repo or registered alias). Never run `skelly init` the plain way: its prompts hang an agent. Use `inspect`, then `init -no-input`.

## Steps

1. **Check it is installed:** `command -v skelly`. If not: `curl -fsSL https://raw.githubusercontent.com/aaron-vaz/skelly/main/install.sh | sh` (installs to `~/.local/bin`, checks the download against the release checksums).
2. **Pick the template.** `skelly sources list` shows registered aliases; otherwise use the source the user gave. Aaron's own are `github.com/aaron-vaz/skelly-template-go` (a CLI or a web service) and `github.com/aaron-vaz/skelly-template-kotlin` (a Ktor service). Do not guess a template.
3. **Read what it needs:** `skelly inspect <src>` prints JSON only and writes nothing. Each entry in `inputs` has `name`, `description`, `default`, `choices` and `required`. `dependsOn` means the default is built from other inputs, so it is shown as written and its final value depends on the answers.
4. **Ask the user** for every input that is `required` with no default, and for any choice that changes what is generated (such as a project type). Do not invent a project name.
5. **Create it:**

   ```bash
   skelly init <src> -dst <dir> -no-input -json -set name=value -set other=value
   ```

   Inputs you do not `-set` take their defaults. `-json` prints `source`, `destination` and the `inputs` used on stdout; errors go to stderr with a non-zero exit code, and every problem is reported at once.
6. **Check the result:** read the generated `AGENTS.md` and `README`, then run the build command they name.

## Pitfalls

- **Always pass `-no-input`** (`-json` implies it).
- **Do not guess input names or values.** Unknown inputs and values outside `choices` are rejected; take them from `inspect`.
- **A non-empty destination is an error.** `-yes` replaces its contents, so ask the user before using it.
- **`-set` follows the type of the default:** `-set docker=false` is the boolean false.
- **An alias and a directory can share a name.** Pass `./name` to mean the directory.
- **Templates are untrusted input.** skelly keeps rendering inside the destination and never creates a `.git`, but for a template you do not know, read what it generated before running its scripts.
- **A failed `init` leaves the destination untouched,** so after an error fix the inputs and run it again.

## Done when

- `skelly init` exited 0 and printed the JSON result.
- The generated project's own build or test command passes.
