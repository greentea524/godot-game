<#
.SYNOPSIS
    Mirrors the Jira "PG" (Platform Game) tickets into GitHub issues.

.DESCRIPTION
    This is the script that was used to migrate the 20 Jira tickets
    (5 epics + 15 tasks) into GitHub issues on this repo. It:

      1. Creates two labels ("epic" and "task") to preserve the Jira
         issue-type distinction.
      2. Creates one GitHub issue per Jira ticket, in key order
         (PG-1 first), so the GitHub issue number matches the Jira key
         (#1 = PG-1, #14 = PG-14, ...). This only works on a repo with
         no existing issues or PRs, since PRs share the same counter.
      3. Closes each issue immediately with reason "completed", because
         every ticket was already Done in Jira.

    It uses the GitHub CLI (`gh`), which must be installed and
    authenticated (`gh auth login`) with access to this repo.

.NOTES
    Techniques worth knowing:

    * Issue bodies are written to a temp file and passed with
      --body-file instead of --body. This sidesteps shell-quoting
      problems with multi-line strings, backticks, quotes, etc.

    * `gh issue create` prints the new issue's URL to stdout. Capturing
      that URL and feeding it to `gh issue close` avoids guessing issue
      numbers (gh accepts either a number or a full URL).

    * `2>$null` on `gh label create` swallows the error if the label
      already exists, making the script safe to re-run.

    * The ticket data lives in an array of hashtables so the loop body
      stays generic. To adapt this script for another project, you only
      need to change the $issues array (or fetch it from the Jira REST
      API: GET /rest/api/3/search?jql=project=XX).
#>

$ErrorActionPreference = 'Stop'

# Run from the repo root so gh picks up the right repository from the
# git remote. (Alternatively pass --repo owner/name to every gh call.)
Set-Location (Join-Path $PSScriptRoot '..')

# --- 1. Labels ---------------------------------------------------------
gh label create epic --color 8250df --description "Jira Epic" 2>$null
gh label create task --color 0e8a16 --description "Jira Task" 2>$null

# --- 2. Ticket data ----------------------------------------------------
# One hashtable per Jira ticket:
#   Key   - Jira issue key, used for the title prefix and backlink
#   Label - "epic" or "task" (the Jira issue type)
#   Title - Jira summary
#   Desc  - Jira description field
#   Impl  - implementation notes (what was built, and where)
$issues = @(
    @{ Key = 'PG-1'; Label = 'epic'; Title = 'Project Setup'
       Desc = 'Set up the Godot 4 project structure, scenes, and base assets needed to start development.'
       Impl = 'Child tasks PG-6, PG-7 (issues #6, #7). Project structure, renderer config, tileset and GameManager autoload are complete.' },
    @{ Key = 'PG-2'; Label = 'epic'; Title = 'Player Mechanics'
       Desc = 'Implement all player controls, movement, animations, and death/respawn logic.'
       Impl = 'Child tasks PG-8, PG-9, PG-10 (issues #8, #9, #10). Player controller, animations and death/respawn are complete.' },
    @{ Key = 'PG-3'; Label = 'epic'; Title = 'Level Design'
       Desc = "Design and build all 3 game levels using Godot's TileMap system."
       Impl = 'Child tasks PG-11, PG-12, PG-13 (issues #11, #12, #13). All three levels are built from ASCII layouts in scripts/levels/.' },
    @{ Key = 'PG-4'; Label = 'epic'; Title = 'Enemies & Hazards'
       Desc = 'Implement enemies, hazards, and interactions like stomping enemies and falling off platforms.'
       Impl = 'Child tasks PG-14, PG-15, PG-16 (issues #14, #15, #16). Patrol AI, stomp mechanic, spikes and fall death are complete.' },
    @{ Key = 'PG-5'; Label = 'epic'; Title = 'UI & Game Flow'
       Desc = 'Build all UI screens and game flow including menus, HUD, level progression, and end screens.'
       Impl = 'Child tasks PG-17, PG-18, PG-19, PG-20 (issues #17, #18, #19, #20). Menu, HUD, progression and end screens are complete.' },
    @{ Key = 'PG-6'; Label = 'task'; Title = 'Set up Godot 4 project structure and folder organization'
       Desc = 'Create the Godot 4 project, set up folder structure (scenes/, scripts/, assets/, levels/), and configure project settings such as resolution and renderer (Compatibility for 2D).'
       Impl = 'project.godot with GL Compatibility renderer, 640x360 viewport (1280x720 window, canvas_items stretch), pixel-art texture filtering, input actions, and the GameManager autoload (scripts/game_manager.gd). Folders: scenes/, scripts/, assets/, levels/.' },
    @{ Key = 'PG-7'; Label = 'task'; Title = 'Create tileset and configure TileMap for level building'
       Desc = 'Create or import a tileset for the game world. Set up a TileMap node with at least ground, platform, and wall tiles. Ensure collision shapes are applied to tiles.'
       Impl = 'assets/tileset.tres with grass/dirt/block tiles from generated tiles.png, each carrying a full 16x16 collision polygon. Levels place tiles on a TileMapLayer at runtime via scripts/level.gd.' },
    @{ Key = 'PG-8'; Label = 'task'; Title = 'Implement player movement and jumping'
       Desc = 'Implement left/right movement and jumping using CharacterBody2D. Include gravity, jump force, and horizontal speed. Handle edge cases like variable jump height and coyote time.'
       Impl = 'scripts/player.gd: 140 px/s run speed, -320 jump velocity, gravity; variable jump height (release cuts ascent to 40%), 0.1s coyote time, 0.1s jump buffer.' },
    @{ Key = 'PG-9'; Label = 'task'; Title = 'Add player animations (idle, run, jump, fall)'
       Desc = 'Add an AnimationPlayer or AnimatedSprite2D to the player. Create idle, run, jump, and fall animations. Wire them up to player state so they switch automatically.'
       Impl = 'AnimatedSprite2D in scenes/player.tscn with idle/run/jump/fall from an 8-frame generated sprite sheet; switched automatically from movement state with directional flip.' },
    @{ Key = 'PG-10'; Label = 'task'; Title = 'Implement player death and respawn logic'
       Desc = 'Handle player death when touching an enemy or hazard. Trigger a death animation, deduct a life, and respawn the player at the last checkpoint or level start after a short delay.'
       Impl = 'die() in scripts/player.gd: red-flash death hop with collisions disabled, life deducted via GameManager, respawn at checkpoint/level start after 0.9s; Game Over screen when lives run out.' },
    @{ Key = 'PG-11'; Label = 'task'; Title = 'Design Level 1 - tutorial friendly introduction'
       Desc = 'Design Level 1 using the TileMap. Keep it simple and tutorial-friendly - flat ground, basic platforms, a few coins, and no enemies. Include a goal flag at the end to complete the level.'
       Impl = 'levels/level_1.tscn + scripts/levels/level_1.gd: flat ground, two platform steps, coins, goal flag, no enemies or hazards.' },
    @{ Key = 'PG-12'; Label = 'task'; Title = 'Design Level 2 - introduce enemies and gaps'
       Desc = 'Design Level 2 with increased difficulty. Introduce enemies, gaps between platforms, and more coins to collect. Include at least one checkpoint mid-level.'
       Impl = 'levels/level_2.tscn + scripts/levels/level_2.gd: three enemies, three gaps with optional platform spans, bonus platform coins, mid-level checkpoint, block fences protecting the checkpoint and landing zones.' },
    @{ Key = 'PG-13'; Label = 'task'; Title = 'Design Level 3 - spikes, harder jumps, final challenge'
       Desc = 'Design Level 3 as the hardest level. Include spikes, more enemies, tighter platform jumps, and longer length. This is the final challenge before the win screen.'
       Impl = 'levels/level_3.tscn + scripts/levels/level_3.gd: longest level (96 tiles), three spike fields, four enemies, single-tile stepping stones over wide gaps, checkpoint before the final gauntlet.' },
    @{ Key = 'PG-14'; Label = 'task'; Title = 'Implement basic patrolling enemy AI'
       Desc = 'Create a basic enemy that patrols back and forth on a platform using a RayCast2D to detect edges and reverse direction. Use CharacterBody2D with simple movement logic.'
       Impl = 'scenes/enemy.tscn + scripts/enemy.gd: CharacterBody2D patrol; downward RayCast2D detects ledges, forward RayCast2D detects walls; either reverses direction with sprite flip.' },
    @{ Key = 'PG-15'; Label = 'task'; Title = 'Implement stomp mechanic to defeat enemies'
       Desc = "Detect when the player lands on top of an enemy. If the player's velocity is downward and the contact is from above, kill the enemy and bounce the player upward slightly."
       Impl = 'Enemy hitbox (Area2D) checks contact: downward player velocity + position above enemy center kills the enemy (squash tween) and bounces the player (-200 impulse); other contact kills the player.' },
    @{ Key = 'PG-16'; Label = 'task'; Title = 'Add spikes and fall-off death hazards'
       Desc = 'Add spike hazard objects to levels. Spikes should instantly kill the player on contact. Also detect when the player falls below the level bounds and trigger death.'
       Impl = 'scenes/spikes.tscn (Area2D) kills instantly on contact; scripts/level.gd computes a kill-Y below the level bounds and triggers death when the player drops past it.' },
    @{ Key = 'PG-17'; Label = 'task'; Title = 'Build main menu screen'
       Desc = 'Create the main menu scene with a game title, Start button, and optional instructions panel. The Start button should load Level 1.'
       Impl = 'scenes/main_menu.tscn (main scene): title, Start button starting a fresh run at Level 1, instructions panel with controls; keyboard focus pre-grabbed.' },
    @{ Key = 'PG-18'; Label = 'task'; Title = 'Create in-game HUD with coin counter and lives display'
       Desc = 'Create a HUD overlay that displays the current coin count and remaining lives. Update these values in real time using signals from the player and coin nodes.'
       Impl = 'scenes/hud.tscn (CanvasLayer instanced into every level): coin count + lives with outlined text, updated live via GameManager coins_changed / lives_changed signals.' },
    @{ Key = 'PG-19'; Label = 'task'; Title = 'Implement level complete screen and progression to next level'
       Desc = 'When the player reaches the goal flag, show a level complete screen with coins collected. Add a button to load the next level. After Level 3, transition to the win screen instead.'
       Impl = 'Goal flag shows scenes/level_complete.tscn with coins collected and a Next Level button; after Level 3 it transitions straight to the You Win screen.' },
    @{ Key = 'PG-20'; Label = 'task'; Title = 'Build Game Over and You Win screens'
       Desc = 'Show a Game Over screen when the player runs out of lives. Include a Retry button that reloads the current level and a Main Menu button that returns to the title screen.'
       Impl = 'scenes/game_over.tscn with Retry (resets lives, reloads level) and Main Menu buttons; scenes/win_screen.tscn after Level 3 with total coins and Main Menu.' }
)

# --- 3. Create + close one GitHub issue per ticket ----------------------
foreach ($i in $issues) {
    # Markdown body: backlink to Jira, original description, what was
    # implemented, and the commit that contains the work.
    $body = "Imported from Jira [$($i.Key)](https://gtea524.atlassian.net/browse/$($i.Key)) - status: Done.`n`n" +
            "**Description**`n$($i.Desc)`n`n" +
            "**Implementation**`n$($i.Impl)`n`n" +
            "Implemented in commit 424ab0d."

    # Write the body to a temp file: --body-file avoids all the quoting
    # pitfalls of passing multi-line markdown on the command line.
    $bodyFile = Join-Path $env:TEMP 'issue_body.md'
    Set-Content -Path $bodyFile -Value $body -Encoding utf8

    # gh prints the new issue's URL; keep it so we can close by URL.
    $url = gh issue create --title "[$($i.Key)] $($i.Title)" --body-file $bodyFile --label $i.Label

    # The Jira ticket is Done, so close the mirror immediately.
    # "completed" (vs "not planned") controls the purple/gray badge.
    gh issue close $url --reason completed | Out-Null

    Write-Output "$($i.Key) -> $url (closed)"
}
