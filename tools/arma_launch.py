#!/usr/bin/env python3
r"""
ACE3 debug launcher
===================
Starts Arma 3 itself with the debug command line from your latest
session, and boots straight into the 3DEN editor with a mission
loaded.

Command line
------------
By default the launcher builds the command itself, so any agent can
start any mission without a previous session:

    <exe> -noPause -filePatching -debug -nosplash -world=empty
          -preprocDefine=CMD__ACE3DEBUG_MP
          -mod=@cba_a3;@acedev;@wolf_tfar;@ace3debug
          <path to mission.sqm>

The last argument is always the mission: Arma skips the main menu and
opens 3DEN with that mission already loaded.  The process runs with the
game folder as its working directory (the engine resolves -mod= from
there), found by walking up from the executable - a custom client may
live in a subfolder such as @wolf_arma.  The mission defaults to
<Documents>\Arma 3 - Other Profiles\dedmen\missions\tacPhoneTestACE2.Altis
(detected from the user profile, not hardcoded); --mission, --mods and
--extra override any part.  -noPause is always on: a paused game (Esc,
debugger break) would stall the unattended flow with no signal in the
RPT.

With --last the launcher reuses the last session's command line
instead: the game logs its own command line as the first lines of
every RPT (log in %LOCALAPPDATA%\\Arma 3), and the tool relaunches
exactly what you ran last.  --rpt picks which RPT to read (a path, a
file name in that directory, or an index into the newest-first list,
0 = newest), and --drop removes a flag from the reused line.

The game's window stays visible by default.  A minimized window is a 0x0
client area, which can hang the mission preview (use --minimize to
background it anyway, at that risk).

Ready report
------------
After start, the launcher tails the session's RPT (the auto-start mod
logs milestones there) and reports progress:
    ready: 3DEN editor loaded
    ready: mission loaded [singleplayer]
    ready: multiplayer mission loaded   (--mp)
"Mission loaded" is the first of three RPT markers, all of which mean
the mission is running in the game: the auto-start mod's PreInit line
in the loaded mission context (the local-MP preview is a single listen
server there, isServer=true, so there is no separate client load), the
TacPhone web host start (eval bridge up), or the OnMissionPreview
confirmation.  In the multiplayer preview the role screen and the
briefing are auto-confirmed by the mod, and the launcher keeps
waiting: it exits 0
only once the player has actually entered the world, signalled by the
mod's 'lobby: world entered' line (client state reached BRIEFING
READ, i.e. the briefing closed).  A run that never gets there reaches
the mod's terminal instead, which logs a diagnostic line with the
reason and the client state at failure; the launcher reports that
line and kills the game.  It exits 1 on the terminal, on timeout, if
the game quits first, or if the RPT reports a missing file (e.g.
'Warning Message: Script <path> not found'): that error parks 3DEN
behind a modal error dialog, so the launcher kills the game and
reports the failure.  Use --no-wait to return right after start, and
--ready-timeout SECONDS to change the deadline (default 300, 600 with
--mp).

Auto-start
----------
The launcher also attaches a tiny mod (extras/autoStart, built with
hemtt and synced to the game directory as @ace3debug) that hooks the
3DEN main display loading and performs the "MissionPreview" editor action
once the scenario is loaded, i.e. the mission starts in preview mode
automatically — exactly as if the Start button had been pressed.
The "MissionPreviewMP" action (multiplayer preview: 3DEN boots a local
dedicated server and connects to it) is selected by
-preprocDefine=CMD__ACE3DEBUG_MP, which the mod's SQF (shipped as text
in the PBO) tests with #ifdef; in the default explicit mode that flag
is always on, with --last --mp turns it on.  The mod also
auto-confirms the screens the
preview opens on the client: the host-server dialog, then role
assignment and the briefing - the EachFrame poller re-attaches itself
in the mission context (PreInit hook), so it keeps ticking while those
screens are up.  Use --no-autostart to disable this.

Typical use
-----------
    python tools/arma_launch.py                        # default mission, MP preview, unattended
    python tools/arma_launch.py --mission SomeMission  # a different mission
    python tools/arma_launch.py --mods @cba_a3;@acedev # different mods
    python tools/arma_launch.py --extra devide         # append more flags
    python tools/arma_launch.py --last                 # reuse last session's command line
    python tools/arma_launch.py --last --rpt 2         # ...from the 3rd newest RPT
    python tools/arma_launch.py --kill                 # kill a running game, then relaunch
    python tools/arma_launch.py --autotest --wait      # run the mission directly, exit code = pass/fail
    python tools/arma_launch.py --build                # hemtt build first
    python tools/arma_launch.py --dry-run              # print command, don't start
    python tools/arma_launch.py --no-autostart         # don't auto-start the preview

The mission argument accepts a full path to a mission folder or its
mission.sqm, or a bare mission name which is resolved against your
profile mission folders, .hemtt/missions and extras/ in this repo.
"""

import argparse
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# tiny mod that makes 3DEN start the mission preview after the scenario loads
AUTO_START_MOD = "@ace3debug"
AUTO_START_SRC = REPO_ROOT / "extras" / "autoStart"

# startup parameter that switches the auto-start mod to the multiplayer
# preview action (#ifdef in eachframe.sqf).  Stripped from reused RPT
# flags so the mode does not persist across launches; re-added only with
# --mp.  Requires the PBO to keep the SQF as text (addon.toml in the
# autoStart mod disables hemtt binarization), so the engine evaluates the
# #ifdef at load time.
MP_PREVIEW_FLAG = "-preprocDefine=CMD__ACE3DEBUG_MP"

# Default explicit command line (without --last): the unattended agent
# flow.  BASE_FLAGS are always on; MP_PREVIEW_FLAG and the auto-start
# mod are always on together, since the preview action needs both.
BASE_FLAGS = ("-noPause", "-filePatching", "-debug", "-nosplash",
              "-world=empty")
DEFAULT_MODS = "@cba_a3;@acedev;@wolf_tfar"
# Default mission, resolved against the user profile (no hardcoded
# username).
DEFAULT_MISSION = (Path.home() / "Documents"
                   / "Arma 3 - Other Profiles" / "dedmen" / "missions"
                   / "tacPhoneTestACE2.Altis" / "mission.sqm")

HEMTT_VERSION = "v1.23.1"

# engine lines for a file it cannot load (e.g. preprocessFileLineNumbers on a
# missing file: 'Warning Message: Script <path> not found').  In 3DEN that
# error parks the editor behind a modal script-error dialog, so the preview
# can never start - report it as a failure.
MISSING_FILE_RE = re.compile(
    r'(?:Warning Message: Script (\S+) not found'
    r'|File "([^"]+)" could not be loaded)')

# Arma 3 client/server image names (taskkill is case-insensitive)
ARMA_PROCESSES = (
    "Arma3Retail.exe", "Arma3Retail_x64.exe",
    "Arma3Retail_DX11.exe", "Arma3Retail_DX11_x64.exe",
    "Arma3.exe", "Arma3_x64.exe", "Arma3_DX11.exe", "Arma3_DX11_x64.exe",
    "Arma3Server.exe", "Arma3Server_x64.exe",
)


def kill_game():
    """Terminate running Arma 3 processes. Returns the names that were killed."""
    killed = []
    for name in ARMA_PROCESSES:
        try:
            rc = subprocess.run(["taskkill", "/F", "/IM", name],
                                capture_output=True, text=True).returncode
        except OSError:
            continue
        if rc == 0:
            killed.append(name)
    return killed


def write_autotest_cfg(mission):
    """Write an autotest.cfg that runs the given mission. Returns the cfg path.

    -autotest makes the game run the mission(s) directly (no 3DEN); a mission
    that does not end with END1 is logged as <AutoTest result=...> in the RPT
    and the game exits with a non-zero error level (use with --wait).
    """
    cfg = Path(tempfile.gettempdir()) / "ace3_autotest.cfg"
    folder = mission.parent if mission.name.lower() == "mission.sqm" else mission
    cfg.write_text(
        "class TestMissions\n"
        "{\n"
        "    class TestCase01\n"
        "    {\n"
        '        campaign = "";\n'
        f'        mission = "{folder.as_posix()}";\n'
        "    };\n"
        "};\n",
        encoding="utf-8",
    )
    return cfg


def ensure_hemtt():
    """Return a path to the hemtt build tool, downloading it on demand."""
    exe_name = "hemtt.exe" if os.name == "nt" else "hemtt"
    exe = Path(__file__).resolve().parent / "bin" / exe_name
    if exe.is_file():
        return exe
    if os.name == "nt":
        import urllib.request
        import zipfile
        asset = "windows-x64.zip"
        url = (f"https://github.com/BrettMayson/HEMTT/releases/download/"
               f"{HEMTT_VERSION}/{asset}")
        tmp_zip = Path(__file__).resolve().parent / "bin" / f".{asset}"
        exe.parent.mkdir(parents=True, exist_ok=True)
        print(f"downloading hemtt {HEMTT_VERSION} ...")
        try:
            urllib.request.urlretrieve(url, tmp_zip)
            with zipfile.ZipFile(tmp_zip) as zf:
                for name in zf.namelist():
                    if name.split("/")[-1] in (exe_name, "hemtt", "hemtt.exe"):
                        with zf.open(name) as src, open(exe, "wb") as dst:
                            dst.write(src.read())
                        break
        finally:
            tmp_zip.unlink(missing_ok=True)
        if exe.is_file():
            return exe
    return shutil.which("hemtt")


def rpt_log_dir():
    return Path(os.environ.get("LOCALAPPDATA", "")) / "Arma 3"


def find_rpt(selector=None):
    """Return the RPT to read.

    Without a selector: the newest by mtime.  A selector is a path, a
    file name in the RPT directory, or an index into the newest-first
    list (0 = newest).  None when nothing matches.
    """
    rpt_dir = rpt_log_dir()
    if not rpt_dir.is_dir():
        return None
    rp = sorted(rpt_dir.glob("*.rpt"), key=lambda p: p.stat().st_mtime,
                reverse=True)
    if not rp:
        return None
    if selector is None:
        return rp[0]
    if str(selector).isdigit():
        idx = int(selector)
        return rp[idx] if idx < len(rp) else None
    p = Path(selector)
    if p.is_file():
        return p
    p = rpt_dir / selector
    return p if p.is_file() else None


def parse_rpt(rpt):
    """Extract executable, flags, mods and mission from the RPT header."""
    info = {"exe": None, "flags": [], "mods": None, "mission": None}
    try:
        lines = rpt.read_text(errors="replace").splitlines()
    except OSError as e:
        print(f"warning: cannot read {rpt}: {e}", file=sys.stderr)
        return info

    # header lines: "== <exe path>" (unquoted, may contain spaces) followed by
    # '== "<exe>" <args> "<mission>"'; skip the all-'=' separator line
    header = [l for l in lines[:5]
              if l.startswith("==") and set(l.strip()) != {"="}]
    if len(header) >= 2:
        info["exe"] = header[0][2:].strip()
        tokens = shlex.split(header[1][2:].strip())
        for tok in tokens[1:]:
            if tok.startswith("-mod="):
                info["mods"] = [m for m in tok[len("-mod="):].split(";") if m]
            elif tok.startswith("-"):
                info["flags"].append(tok)
            else:
                info["mission"] = tok
    return info


def resolve_mission(name, rinfo):
    """Return a Path to mission.sqm for `name` (path or bare mission name)."""
    p = Path(name)
    if p.is_file() and p.name == "mission.sqm":
        return p
    if p.is_dir():
        sqm = p / "mission.sqm"
        return sqm if sqm.is_file() else None
    if not p.is_absolute() and "\\" not in name and "/" not in name:
        # bare mission name: search profile mission folders, then the repo
        docs = Path(os.environ.get("USERPROFILE", "")) / "Documents"
        bases = [docs / "Arma 3" / "profiles", docs / "Arma 3 - Other Profiles"]
        for base in bases:
            if base.is_dir():
                for sqm in sorted(base.glob("*/missions/*/mission.sqm")):
                    if sqm.parent.name == name:
                        return sqm
        for sub in (".hemtt/missions", "extras"):
            for sqm in sorted((REPO_ROOT / sub).rglob("mission.sqm")):
                if sqm.parent.name == name:
                    return sqm
    return None


def game_root(exe):
    """Return the working directory (game folder) to start `exe` from.

    The engine resolves -mod= directories and loose files against the
    process working directory, so it must be the game folder - not the
    exe's own directory, where a custom client may live in a subfolder
    (e.g. @wolf_arma\\arma3client_x64_profiling_..._v14.exe).  Walk up
    from the exe looking for the standard client image (the game folder
    always ships arma3_x64.exe / arma3retail_x64.exe); fall back to the
    exe's own directory when nothing matches (non-standard install).
    """
    markers = {"arma3_x64.exe", "arma3retail_x64.exe"}
    start = Path(exe).resolve().parent
    d = start
    for _ in range(3):
        try:
            if any(p.is_file() and p.name.lower() in markers
                   for p in d.iterdir()):
                return d
        except OSError:
            break
        if d.parent == d:
            break
        d = d.parent
    return start


def minimize_game_window(pid, timeout=20, guard=45):
    """Minimize the game's top-level window(s) once they appear (Windows only).

    The window can take a few seconds to show up after the process starts,
    and Arma restores/foregrounds it again when loading finishes — so keep
    re-minimizing for `guard` seconds after the first success (0 = no guard).
    """
    import ctypes
    from ctypes import wintypes

    user32 = ctypes.windll.user32
    SW_MINIMIZE = 6

    def _find():
        found = []

        @ctypes.WINFUNCTYPE(ctypes.c_bool, wintypes.HWND, wintypes.LPARAM)
        def _enum(hwnd, _lparam):
            pid_out = wintypes.DWORD()
            user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid_out))
            if pid_out.value == pid and user32.IsWindowVisible(hwnd):
                found.append(hwnd)
            return True

        user32.EnumWindows(_enum, 0)
        return found

    hws = []
    deadline = time.time() + timeout
    while time.time() < deadline and not hws:
        hws = _find()
        if not hws:
            time.sleep(0.5)
    if not hws:
        return False
    for hwnd in hws:
        user32.ShowWindow(hwnd, SW_MINIMIZE)

    guard_end = time.time() + guard
    while time.time() < guard_end:
        for hwnd in _find():
            if not user32.IsIconic(hwnd):
                user32.ShowWindow(hwnd, SW_MINIMIZE)
        time.sleep(1)
    return True


def wait_for_ready(proc, start_ts, pre_rpts, timeout=300, mp=False):
    """Tail the new RPT and report readiness milestones.

    The game creates a fresh RPT (named with a timestamp) when the
    process starts, and the auto-start mod logs milestone lines there.
    The new file is identified as one that did not exist before launch
    (mtime alone is not reliable: the previous session's RPT is written
    right up until its kill, moments before this launch).  Without mp it
    returns 0 at the first "mission loaded" marker.  With mp it waits
    until the player has entered the world ('lobby: world entered'); a
    run that is stuck reaches the machine's terminal instead, which
    fails the run.  1 on the terminal, on timeout, on a missing-file
    error, or if the game exits first.
    """
    rpt_dir = rpt_log_dir()
    deadline = time.time() + timeout
    rpt = None
    offset = 0
    buf = ""
    editor_seen = False
    mission_ready_at = None
    while time.time() < deadline:
        if rpt is None:
            if rpt_dir.is_dir():
                for p in sorted(rpt_dir.glob("*.rpt"),
                                key=lambda q: q.stat().st_mtime, reverse=True):
                    if p.name not in pre_rpts:
                        rpt = p
                        break
            if rpt is None:
                time.sleep(1)
                continue
            print(f"watching {rpt.name}")
        rc = proc.poll()
        if rc is not None:
            print(f"game exited with code {rc} before the mission preview "
                  f"started", file=sys.stderr)
            return 1
        try:
            with open(rpt, "rb") as f:
                f.seek(offset)
                data = f.read()
                offset = f.tell()
        except OSError:
            data = b""
        if data:
            buf += data.decode("utf-8", errors="replace")
            nl = buf.rfind("\n")
            if nl >= 0:
                chunk, buf = buf[:nl + 1], buf[nl + 1:]
                for line in chunk.splitlines():
                    m = MISSING_FILE_RE.search(line)
                    if m:
                        print(f"failure: file not found: {m.group(1) or m.group(2)}\n"
                              f"        3DEN parks behind a modal error dialog "
                              f"for this, the preview can never start.\n"
                              f"        log: {rpt}\n"
                              f"        rebuild the failing mod or fix the "
                              f"file path, then relaunch.", file=sys.stderr)
                        killed = kill_game()
                        if killed:
                            print("killed:", ", ".join(killed))
                        return 1
                    if not editor_seen and "[ace3debug] Display3DEN loaded" in line:
                        editor_seen = True
                        print("ready: 3DEN editor loaded")
                    elif "[ace3debug] lobby: world entered" in line:
                        # --mp only: the mod's machine saw the client
                        # state reach BRIEFING READ (briefing closed,
                        # mission playable) - the unattended pass
                        now = time.time()
                        where = (f"{now - mission_ready_at:.0f}s after "
                                 f"mission load" if mission_ready_at else "")
                        print(f"ready: multiplayer world entered "
                              f"(unattended pass) "
                              f"[{now - start_ts:.0f}s after launch"
                              + (f", {where}" if where else "") + "]")
                        # after the briefing closes the engine shows a
                        # small loading screen and the mission's init
                        # scripts need a couple of seconds to run
                        time.sleep(3)
                        return 0
                    elif "[ace3debug] lobby: terminal" in line:
                        # --mp only: the machine's own timeout - 360 s
                        # without world entry, or 30 s without the OK
                        # control.  The line carries the reason and the
                        # diagnostics; kill and fail.
                        print(f"failure: MP run did not reach the world, machine terminal:\n"
                              f"        {line.strip()}\n"
                              f"        log: {rpt}\n"
                              f"        the line above carries the reason and the client "
                              f"state at failure",
                              file=sys.stderr)
                        killed = kill_game()
                        if killed:
                            print("killed:", ", ".join(killed))
                        return 1
                    elif "[ace3debug] mission ready: mission context loaded" in line:
                        # attach.sqf, PreInit in the loaded mission
                        # context; in the 3DEN local-MP preview that
                        # context is a single listen server
                        # (isServer=true).  --mp keeps waiting: world
                        # entry is the real done signal (see above).
                        print("ready:"
                              + (" multiplayer " if mp else " ")
                              + "mission loaded")
                        if mission_ready_at is None:
                            mission_ready_at = time.time()
                        if not mp:
                            return 0
                    elif "[TacPhone] Webhost started" in line:
                        # mission postInit ran and the eval bridge is up
                        print("ready:"
                              + (" multiplayer " if mp else " ")
                              + "mission loaded (eval bridge up)")
                        if mission_ready_at is None:
                            mission_ready_at = time.time()
                        if not mp:
                            return 0
                    elif "[ace3debug] mission preview started" in line:
                        print("ready:"
                              + (" multiplayer " if mp else " ")
                              + "mission preview started")
                        if mission_ready_at is None:
                            mission_ready_at = time.time()
                        if not mp:
                            return 0
        time.sleep(1)
    if mp:
        # a machine terminal would have failed the run earlier; reaching
        # the backstop means no terminal line appeared in the log at all
        print(f"failure: player did not enter the world within {timeout}s "
              f"(no machine terminal in the log); log: {rpt or 'no RPT found'}",
              file=sys.stderr)
        killed = kill_game()
        if killed:
            print("killed:", ", ".join(killed))
    else:
        print(f"warning: mission preview did not start within {timeout}s",
              file=sys.stderr)
    return 1


def sync_autostart_mod(game_exe):
    """Build the auto-start mod with hemtt and stage it in the game folder.

    The mod must sit in the working directory (the game folder) because
    that is where the engine resolves -mod=@ace3debug from - even when
    the executable runs from a subfolder.

    The Arma 3 engine ignores loose config files in an addon folder, so
    the addon must be a PBO.  hemtt builds it, compiling config.cpp into
    config.bin.  The SQF stays as text (addon.toml disables binarization)
    so the engine's preprocessor runs at load time and the
    -preprocDefine=CMD__ACE3DEBUG_MP parameter can switch the preview
    action per launch.
    """
    if not AUTO_START_SRC.is_dir():
        print(f"warning: auto-start mod not found at {AUTO_START_SRC}", file=sys.stderr)
        return None
    hemtt = ensure_hemtt()
    if not hemtt:
        print("warning: hemtt not found; cannot build auto-start mod",
              file=sys.stderr)
        return None
    build_out = AUTO_START_SRC / ".hemttout" / "build"
    try:
        proc = subprocess.run([str(hemtt), "build"], cwd=AUTO_START_SRC,
                              capture_output=True, text=True)
    except OSError as e:
        print(f"warning: could not run hemtt: {e}", file=sys.stderr)
        return None
    if proc.returncode != 0:
        print(f"error: hemtt build failed:\n{proc.stdout}{proc.stderr}", file=sys.stderr)
        return None
    dst = game_root(game_exe) / AUTO_START_MOD
    # a freshly killed game can hold the staged PBO's file handles for a
    # few seconds; retry until the OS releases them
    for attempt in range(15):
        try:
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(build_out, dst)
            return AUTO_START_MOD
        except OSError as e:
            if attempt == 14:
                print(f"error: could not sync auto-start mod: {e}\n"
                      f"        (staged PBO locked - is Arma 3 still running "
                      f"or another process holding the file?)",
                      file=sys.stderr)
            else:
                time.sleep(1)
    return None


def build_command(rinfo, args, mission, autostart=None, autotest_cfg=None):
    exe = args.game or rinfo["exe"]
    if not exe:
        print("error: no Arma 3 executable found (no RPT header, no --game)", file=sys.stderr)
        return None

    if args.last:
        # reuse the last session's command line, minus the dropped
        # flags and minus the per-launch MP flag (re-added below)
        drop = {"-" + d.lstrip("-") for d in args.drop}
        flags = [f for f in rinfo["flags"] if f not in drop and f != MP_PREVIEW_FLAG]
        mp_run = args.mp
    else:
        # explicit: fixed base flags.  With the auto-start mod the MP
        # preview is always on - that is the unattended agent flow.
        flags = list(BASE_FLAGS)
        mp_run = args.mp or autostart is not None

    if mp_run and MP_PREVIEW_FLAG not in flags:
        flags.append(MP_PREVIEW_FLAG)
    if args.profile:
        flags.append(f"-profile={args.profile}")
    flags.extend("-" + e.lstrip("-") for e in args.extra)
    # -noPause is always on: a paused game (Esc, debugger break) hangs
    # the unattended flow with no signal in the RPT
    if "-noPause" not in flags:
        flags.append("-noPause")

    if args.mods:
        mods = [m for m in args.mods.split(";") if m]
    elif args.last:
        mods = rinfo["mods"] or []
    else:
        mods = [m for m in DEFAULT_MODS.split(";") if m]
    if autostart and autostart not in mods:
        mods.append(autostart)
    if autotest_cfg is not None:
        mods = [m for m in mods if m != AUTO_START_MOD]  # no 3DEN in autotest mode
    if mods:
        flags.append("-mod=" + ";".join(mods))
    if autotest_cfg is not None:
        flags.append(f"-autotest={autotest_cfg}")

    cmd = [exe] + flags
    if mission is not None and autotest_cfg is None:
        # the mission path must be the last argument for Arma to open it in 3DEN
        cmd.append(str(mission))
    return cmd


def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--game", metavar="EXE",
                    help="Arma 3 executable to start (default: from the "
                         "newest RPT)")
    ap.add_argument("--mission", metavar="PATH_OR_NAME",
                    help="mission to open in 3DEN (path to mission.sqm / "
                         "mission folder, or bare mission name; default: "
                         "tacPhoneTestACE2.Altis from your Documents folder)")
    ap.add_argument("--mods", metavar="A;B;C",
                    help="-mod list (default: @cba_a3;@acedev;@wolf_tfar in "
                         "explicit mode, from the last session with --last; "
                         "@ace3debug is added automatically for auto-launch)")
    ap.add_argument("--drop", action="append", default=[], metavar="FLAG",
                    help="with --last: flag from the reused command line to "
                         "remove, without dash, e.g. noSound (repeatable)")
    ap.add_argument("--extra", action="append", default=[], metavar="FLAG",
                    help="extra flag to append, without dash, e.g. devide "
                         "(repeatable)")
    ap.add_argument("--profile", metavar="NAME", help="Arma profile (-profile=NAME)")
    ap.add_argument("--last", action="store_true",
                    help="reuse the last session's command line from the RPT "
                         "instead of building the default explicit command "
                         "(see --rpt, --drop)")
    ap.add_argument("--rpt", metavar="PATH_OR_INDEX",
                    help="with --last: which RPT to read - a path, a file "
                         "name in %%LOCALAPPDATA%%\\Arma 3, or an index into "
                         "the newest-first list (0 = newest; default: newest)")
    ap.add_argument("--no-autostart", action="store_true",
                    help=f"do not attach {AUTO_START_MOD} (in explicit mode "
                         "this also drops the MP preview flag; the game just "
                         "opens 3DEN with the mission)")
    ap.add_argument("--mp", action="store_true",
                    help="start a MULTIPLAYER preview (local dedicated "
                         "server).  In explicit mode the MP preview is "
                         "always on (implicit); with --last this adds "
                         f"{MP_PREVIEW_FLAG}")
    ap.add_argument("--kill", action="store_true",
                    help="kill running Arma 3 processes before starting")
    ap.add_argument("--autotest", action="store_true",
                    help="run the mission directly via -autotest instead of opening "
                         "it in 3DEN (no auto-start mod; combine with --wait to "
                         "get the pass/fail exit code)")
    ap.add_argument("--build", action="store_true",
                    help="run 'hemtt build' first to sync this repo into the mod")
    ap.add_argument("--wait", action="store_true",
                    help="wait for the game to close and exit with its code")
    ap.add_argument("--minimize", action="store_true",
                    help="minimize the game window after start "
                         "(default: window stays visible; a minimized 0x0 "
                         "window can hang the mission preview)")
    ap.add_argument("--minimize-guard", type=int, default=45, metavar="SECONDS",
                    help="with --minimize: keep re-minimizing the window for "
                         "this many seconds, in case Arma restores it during "
                         "loading (default: 45, 0 = minimize once)")
    ap.add_argument("--dry-run", action="store_true",
                    help="print the command line without starting the game")
    ap.add_argument("--no-wait", action="store_true",
                    help="don't wait for the ready report; return right "
                         "after the game starts")
    ap.add_argument("--ready-timeout", type=int, default=None, metavar="SECONDS",
                    help="how long to wait for the mission to be ready before "
                         "reporting a timeout (default: 300 for singleplayer, "
                         "600 for --mp)")
    args = ap.parse_args()

    if args.kill and not args.dry_run:
        killed = kill_game()
        if killed:
            print("killed:", ", ".join(killed))
            time.sleep(2)  # let the OS release the RPT / PBO file handles
        else:
            print("no running Arma 3 processes found")

    if args.last:
        rpt = find_rpt(args.rpt)
        if rpt is None:
            print("error: no RPT to reuse (none found, or --rpt did not "
                  "match); pass --rpt or drop --last", file=sys.stderr)
            return 1
        print(f"using command line from {rpt}")
    else:
        # explicit mode: the RPT is only read for the executable path
        # when --game is not given
        rpt = find_rpt()
        if rpt is None:
            print("warning: no Arma 3 RPT log found; "
                  "pass --game to name the executable", file=sys.stderr)
    rinfo = parse_rpt(rpt) if rpt else {}

    if args.build:
        hemtt = ensure_hemtt()
        if not hemtt:
            print("error: hemtt not found, cannot build", file=sys.stderr)
            return 1
        print(f"building: {hemtt} build")
        rc = subprocess.run([hemtt, "build"], cwd=REPO_ROOT).returncode
        if rc != 0:
            print(f"error: hemtt build failed ({rc})", file=sys.stderr)
            return rc

    mission = None
    if args.mission:
        mission = resolve_mission(args.mission, rinfo)
        if not mission:
            print(f"error: mission not found: {args.mission}", file=sys.stderr)
            return 1
    elif args.last and rinfo.get("mission"):
        m = resolve_mission(rinfo["mission"], rinfo)
        if m:
            mission = m
        else:
            print(f"warning: last session's mission no longer exists: {rinfo['mission']}",
                  file=sys.stderr)
    else:
        # explicit mode default mission
        m = resolve_mission(str(DEFAULT_MISSION), rinfo)
        if m:
            mission = m
        else:
            print(f"error: default mission not found: {DEFAULT_MISSION}\n"
                  f"        use --mission to choose one", file=sys.stderr)
            return 1

    autotest_cfg = None
    if args.autotest:
        if mission is None:
            print("error: --autotest needs a mission (--mission or last session)",
                  file=sys.stderr)
            return 1
        autotest_cfg = write_autotest_cfg(mission)
        print(f"autotest cfg: {autotest_cfg}")

    autostart = None
    if not args.no_autostart and autotest_cfg is None:
        # the auto-start mod only makes sense in 3DEN, not in autotest mode
        exe = args.game or rinfo["exe"]
        autostart = AUTO_START_MOD  # shown in the command even for --dry-run
        if not args.dry_run and exe:
            # a failed sync must abort the launch, not fall back to the
            # previously staged PBO: the game would then run a stale
            # machine while the launcher waits for the new RPT markers
            # and every run would time out
            if sync_autostart_mod(exe) is None:
                print("error: aborting - the auto-start mod could not be "
                      "rebuilt (see error above)", file=sys.stderr)
                return 1

    cmd = build_command(rinfo, args, mission, autostart, autotest_cfg)
    if cmd is None:
        return 1
    print("starting:", " ".join(shlex.quote(c) for c in cmd))
    if args.dry_run:
        return 0

    if args.wait:
        return subprocess.run(cmd, cwd=game_root(cmd[0])).returncode

    start_ts = time.time()
    # RPTs that exist before launch; the new session's RPT is the one that
    # appears afterwards (see wait_for_ready)
    rpt_dir = rpt_log_dir()
    pre_rpts = {p.name for p in rpt_dir.glob("*.rpt")} if rpt_dir.is_dir() else set()
    # cwd is the game folder, not the exe's directory: the engine
    # resolves -mod= against the working directory, and a custom client
    # may run from a subfolder (see game_root)
    proc = subprocess.Popen(cmd, cwd=game_root(cmd[0]))
    print("game started")
    if args.minimize and os.name == "nt":
        if args.minimize_guard > 0:
            print(f"minimizing window (guarding for {args.minimize_guard}s) ...")
        if minimize_game_window(proc.pid, guard=args.minimize_guard):
            print("game window minimized")
        else:
            print("warning: no game window found to minimize", file=sys.stderr)
    # wait for ready whenever the autostart mod is in the final -mod
    # list, not only when this launch staged it: the mod may be reused
    # from the previous session's -mod flag
    mod_flag = next((f for f in cmd if f.startswith("-mod=")), None)
    has_autostart = bool(mod_flag) and AUTO_START_MOD in mod_flag[5:].split(";")
    if has_autostart and not args.no_wait:
        # the default explicit mode is the unattended MP flow; with
        # --last the mode is whatever the reused command line says
        mp = args.mp if args.last else True
        timeout = (args.ready_timeout if args.ready_timeout is not None
                   else (600 if mp else 300))
        return wait_for_ready(proc, start_ts, pre_rpts,
                              timeout=timeout, mp=mp)
    return 0


if __name__ == "__main__":
    sys.exit(main())
