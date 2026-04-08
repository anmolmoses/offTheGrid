# Off The Grid

A command-line app blocker that intercepts terminal commands and prevents you from accessing apps you've chosen to block — on a schedule or on demand.

When you try to run a blocked app, `otg` hijacks the command and displays an animated "ACCESS DENIED" screen with a random motivational quote, then returns you to the prompt.

```
  ╔════════════════════════════════════════════════╗
  ║                                                ║
  ║     O F F   T H E   G R I D                    ║
  ║                                                ║
  ╠════════════════════════════════════════════════╣
  ║                                                ║
  ║     >>> ACCESS DENIED <<<                      ║
  ║                                                ║
  ║     App:     claude                            ║
  ║     Status:  BLOCKED                           ║
  ║     Until:   17:00                             ║
  ║                                                ║
  ║     "Focus is your superpower."                ║
  ║                                                ║
  ╚════════════════════════════════════════════════╝
```

---

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Commands](#commands)
  - [otg add](#otg-add)
  - [otg remove](#otg-remove)
  - [otg list](#otg-list)
  - [otg on](#otg-on)
  - [otg off](#otg-off)
  - [otg status](#otg-status)
  - [otg schedule](#otg-schedule)
  - [otg install](#otg-install)
  - [otg uninstall](#otg-uninstall)
  - [otg help](#otg-help)
- [Scheduling](#scheduling)
  - [Day Options](#day-options)
  - [Time Format](#time-format)
  - [Overnight Schedules](#overnight-schedules)
- [Workflow Examples](#workflow-examples)
- [Config & Data](#config--data)
- [Aliases](#aliases)
- [Troubleshooting](#troubleshooting)
- [Uninstalling](#uninstalling)

---

## Installation

**Requirements:** macOS or Linux with `zsh` as your shell.

1. Clone or download this repo anywhere on your machine:

   ```bash
   git clone <repo-url> ~/offTheGrid
   ```

2. Run the install command:

   ```bash
   ~/offTheGrid/otg install
   ```

   This adds a single `source` line to your `~/.zshrc` that loads the shell hooks.

3. Restart your terminal, or reload your shell:

   ```bash
   source ~/.zshrc
   ```

That's it. The `otg` command is now available in every terminal session.

---

## Quick Start

```bash
# 1. Add apps you want to block
otg add claude
otg add chatgpt
otg add cursor

# 2. Turn it on
otg on

# 3. Try running a blocked app
claude
# → Shows the animated ACCESS DENIED screen

# 4. Turn it off when you're done focusing
otg off

# 5. Apps work again
claude
# → Runs normally
```

---

## How It Works

Off The Grid operates through **zsh shell hooks**. Here's the mechanism:

1. When you run `otg install`, a `source` line is added to your `~/.zshrc` that loads `hooks.zsh`.

2. `hooks.zsh` reads your blocklist (`~/.offthegrid/apps/`) and creates **zsh functions** with the same name as each blocked app. For example, if you block `claude`, a function named `claude()` is created in your shell.

3. When you type `claude` and hit Enter, zsh calls the `claude()` function instead of the real binary. The function checks:
   - Is the master switch on? (`otg on`)
   - Is the current time within the app's schedule?

4. If blocked: the animated "ACCESS DENIED" box is displayed.
   If allowed: the function calls through to the real `claude` binary with all your arguments intact.

5. Whenever you change settings (`otg add`, `otg remove`, `otg on`, `otg off`, `otg schedule`), the hooks automatically refresh in your current shell session. No restart needed.

---

## Commands

### otg add

Add an app to the blocklist.

```
otg add <app> [--from HH:MM --to HH:MM] [--days <days>]
```

**Arguments:**

| Argument | Short | Description |
|---|---|---|
| `<app>` | | The command name to block (e.g. `claude`, `chatgpt`, `cursor`) |
| `--from HH:MM` | `-f` | Start time for the block window (24-hour format) |
| `--to HH:MM` | `-t` | End time for the block window (24-hour format) |
| `--days <days>` | `-d` | Which days the schedule applies. Default: `all` |

**App names** must only contain letters, numbers, hyphens (`-`), dots (`.`), and underscores (`_`).

**Examples:**

```bash
# Block always (whenever otg is active)
otg add claude

# Block during work hours, every day
otg add claude --from 09:00 --to 17:00

# Block during work hours, weekdays only
otg add claude --from 09:00 --to 17:00 --days weekdays

# Short flags
otg add chatgpt -f 09:00 -t 17:00 -d weekdays

# Block specific days
otg add cursor --from 08:00 --to 18:00 --days mon,wed,fri

# Block overnight (crosses midnight)
otg add claude --from 22:00 --to 06:00
```

If no `--from`/`--to` is given, the app is blocked **always** when `otg` is active.

If the app already exists in the blocklist, running `add` again will overwrite its schedule.

---

### otg remove

Remove an app from the blocklist.

```
otg remove <app>
```

**Alias:** `otg rm`

**Examples:**

```bash
otg remove claude
otg rm chatgpt
```

---

### otg list

Display all blocked apps and their schedules.

```
otg list
```

**Alias:** `otg ls`

**Output:**

```
  Off The Grid  ● ACTIVE
  ────────────────────────────────────
  chatgpt               09:00-17:00 weekdays
  claude                always
  cursor                08:00-18:00 mon,wed,fri
```

Shows whether `otg` is currently active or inactive, and each app with its schedule.

---

### otg on

Activate blocking. This is the master switch.

```
otg on
```

When you turn `otg on`:
- Apps with no schedule (set to `always`) are blocked immediately.
- Apps with a schedule are blocked only during their designated time windows.

The hooks refresh instantly in your current shell — no restart needed.

**Output:**

```
  ● Off The Grid is now ACTIVE
  3 app(s) blocked
```

---

### otg off

Deactivate blocking. All apps become accessible again.

```
otg off
```

**Output:**

```
  ○ Off The Grid is now INACTIVE
  All apps accessible
```

This is the quickest way to regain access to everything. Your blocklist and schedules are preserved — just run `otg on` to re-enable.

---

### otg status

Show the current state: whether blocking is active, how many apps are in the blocklist, and which ones are currently blocked.

```
otg status
```

**Alias:** `otg st`

**Output when active:**

```
  ● Off The Grid is ACTIVE
  3 app(s) in blocklist

  Blocked apps:
    ■ claude
    ■ chatgpt  09:00-17:00 weekdays
    ■ cursor   08:00-18:00 mon,wed,fri
```

**Output when inactive:**

```
  ○ Off The Grid is INACTIVE
  3 app(s) in blocklist
```

---

### otg schedule

Update or clear the schedule for an app that's already in the blocklist.

```
otg schedule <app> --from HH:MM --to HH:MM [--days <days>]
otg schedule <app> --clear
```

**Alias:** `otg sched`

**Arguments:**

| Argument | Short | Description |
|---|---|---|
| `--from HH:MM` | `-f` | Start time (24-hour format) |
| `--to HH:MM` | `-t` | End time (24-hour format) |
| `--days <days>` | `-d` | Day specification. Default: `all` |
| `--clear` | | Remove the schedule — app becomes "always blocked" |

The app must already exist in the blocklist. If it doesn't, use `otg add` first.

**Examples:**

```bash
# Set a weekday work-hours schedule
otg schedule claude --from 09:00 --to 17:00 --days weekdays

# Change to weekend-only blocking
otg schedule claude --from 10:00 --to 16:00 --days weekends

# Clear the schedule (block always when active)
otg schedule claude --clear
```

---

### otg install

Set up the shell integration by adding a `source` line to your `~/.zshrc`.

```
otg install
```

This does two things:
1. Creates the config directory at `~/.offthegrid/` (if it doesn't exist).
2. Appends a `source` line to `~/.zshrc` that loads `hooks.zsh`.

If already installed, it tells you and does nothing.

After installing, restart your terminal or run `source ~/.zshrc`.

---

### otg uninstall

Remove the shell integration from `~/.zshrc`.

```
otg uninstall
```

This removes the `source` line and the comment from your `~/.zshrc`. Your blocklist data in `~/.offthegrid/` is **not** deleted — you can reinstall later and your settings will still be there.

After uninstalling, restart your terminal.

---

### otg help

Display the built-in help text with all commands and examples.

```
otg help
```

Also available as `otg --help` or `otg -h`.

---

## Scheduling

Schedules control **when** an app is blocked during the time that `otg` is active.

### Day Options

| Value | Meaning |
|---|---|
| `all` | Every day of the week (this is the default) |
| `weekdays` | Monday through Friday |
| `weekends` | Saturday and Sunday |
| `mon,tue,wed,...` | Specific days, comma-separated (3-letter lowercase abbreviations) |

**Day abbreviations:** `mon`, `tue`, `wed`, `thu`, `fri`, `sat`, `sun`

**Examples:**

```bash
--days all                    # Every day
--days weekdays               # Mon-Fri
--days weekends               # Sat-Sun
--days mon,wed,fri            # Only Monday, Wednesday, Friday
--days tue,thu                # Only Tuesday, Thursday
```

### Time Format

All times use **24-hour format** as `HH:MM`.

| Input | Meaning |
|---|---|
| `00:00` | Midnight |
| `09:00` | 9:00 AM |
| `12:00` | Noon |
| `13:30` | 1:30 PM |
| `17:00` | 5:00 PM |
| `23:59` | 11:59 PM |

### Overnight Schedules

Schedules that cross midnight work correctly. If the start time is later than the end time, `otg` treats it as an overnight range.

```bash
# Block from 10 PM to 6 AM
otg add claude --from 22:00 --to 06:00
```

This blocks the app from 22:00 in the evening through midnight and until 06:00 the next morning.

### No Schedule (Always)

If you add an app without `--from`/`--to`, or clear its schedule with `--clear`, it's blocked at **all times** whenever `otg on` is active.

```bash
otg add claude            # Blocked whenever otg is on
otg schedule claude --clear  # Same — always blocked
```

---

## Workflow Examples

### Deep work session (on-demand)

Block AI assistants while you focus. Turn off when you're done.

```bash
otg add claude
otg add chatgpt
otg add cursor
otg on

# ... do focused work ...

otg off
```

### Work hours auto-blocking (scheduled)

Set it once, turn on, and forget. Apps are only blocked during the scheduled windows.

```bash
otg add claude --from 09:00 --to 12:00 --days weekdays
otg add chatgpt --from 09:00 --to 12:00 --days weekdays
otg on
```

Now `claude` and `chatgpt` are blocked every weekday morning from 9 AM to noon, but accessible in the afternoon. Since `otg on` stays active across terminal restarts (the state persists on disk), you don't need to turn it on again.

### Mixed: some always, some scheduled

```bash
otg add twitter-cli               # Always blocked when active
otg add claude --from 09:00 --to 17:00 --days weekdays  # Work hours only
otg on
```

### Night owl mode

Block distracting tools late at night so you go to sleep:

```bash
otg add claude --from 23:00 --to 07:00
otg add chatgpt --from 23:00 --to 07:00
otg on
```

### Quick toggle

Already have your blocklist set up? Just toggle:

```bash
otg on    # Going dark
# ... focus ...
otg off   # Back online
```

---

## Config & Data

All configuration is stored in `~/.offthegrid/`:

```
~/.offthegrid/
├── state           # Contains "on" or "off" (master switch)
└── apps/           # One file per blocked app
    ├── claude      # Contains "always" or a schedule
    ├── chatgpt     # Contains "09:00-17:00 weekdays"
    └── cursor      # Contains "08:00-18:00 mon,wed,fri"
```

### State file

`~/.offthegrid/state` contains a single word: `on` or `off`. This persists across terminal sessions.

### App files

Each file in `~/.offthegrid/apps/` is named after the command it blocks. The file content defines the schedule:

- `always` — blocked at all times when the master switch is on
- `HH:MM-HH:MM days` — blocked only during the specified time window on the specified days

You can edit these files by hand if you prefer, though using the `otg` commands is recommended.

---

## Aliases

Several commands have shorter aliases:

| Command | Alias |
|---|---|
| `otg remove` | `otg rm` |
| `otg list` | `otg ls` |
| `otg status` | `otg st` |
| `otg schedule` | `otg sched` |
| `otg help` | `otg -h`, `otg --help` |

---

## Troubleshooting

### "otg: command not found"

The shell hooks aren't loaded. Make sure you've run `otg install` and then either:
- Restarted your terminal, **or**
- Run `source ~/.zshrc`

### Blocked app still runs after `otg add`

The master switch must be on. Run `otg on` to activate blocking.

### App is blocked outside its scheduled time

Check your schedule with `otg list`. If the schedule crosses midnight (e.g. `22:00-06:00`), the block is active from 10 PM through 6 AM. Use `otg schedule <app> --clear` to reset and re-add with the correct times.

### Changes don't take effect

If you run `otg` commands in a shell session that was started before installation, the hooks aren't loaded. Run `source ~/.zshrc` to load them, or open a new terminal.

### I want to block an app that uses a different command name

Block the **command name** you type, not the app's display name. For example, if you launch an app by typing `code`, block `code`:

```bash
otg add code
```

### I locked myself out and need to bypass

If you can't run `otg off` for some reason, you can manually fix it:

```bash
echo "off" > ~/.offthegrid/state
source ~/.zshrc
```

Or delete the app's config file directly:

```bash
rm ~/.offthegrid/apps/claude
source ~/.zshrc
```

---

## Uninstalling

To fully remove Off The Grid:

```bash
# 1. Remove shell hooks from .zshrc
otg uninstall

# 2. Delete all config data (optional)
rm -rf ~/.offthegrid

# 3. Restart your terminal
```

Step 1 removes the integration. Step 2 deletes your blocklist and settings. If you skip step 2, you can reinstall later and your previous settings will still be there.
