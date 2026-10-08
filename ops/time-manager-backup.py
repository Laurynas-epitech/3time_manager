#!/usr/bin/env python3
"""Restricted, atomic logical backups of the clean application database only."""
import fcntl
import hashlib
import os
from pathlib import Path
import re
import subprocess
from datetime import datetime, timezone

os.umask(0o077)
root = Path('/var/backups/time-manager-daily')
root.mkdir(mode=0o700, parents=True, exist_ok=True)
if root.is_symlink() or root.resolve() != Path('/var/backups/time-manager-daily'):
    raise RuntimeError('Unexpected backup directory')
os.chmod(root, 0o700)
with (root / '.backup.lock').open('a') as lock:
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    final = root / ('time_manager_dev-' + stamp + '.dump')
    temp = final.with_suffix('.partial')
    try:
        with temp.open('xb') as out:
            subprocess.run(['docker', 'exec', 'time_manager_db_secure', 'pg_dump',
                            '-U', 'postgres', '-d', 'time_manager_dev', '-Fc'],
                           stdout=out, check=True, timeout=1800)
            out.flush()
            os.fsync(out.fileno())
        if temp.stat().st_size == 0:
            raise RuntimeError('Empty backup')
        with temp.open('rb') as source:
            subprocess.run(['docker', 'exec', '-i', 'time_manager_db_secure',
                            'pg_restore', '--list'], stdin=source,
                           stdout=subprocess.DEVNULL, check=True, timeout=60)
        digest = hashlib.sha256(temp.read_bytes()).hexdigest()
        temp.rename(final)
        checksum = final.with_suffix('.dump.sha256')
        with checksum.open('x') as out:
            out.write(digest + '  ' + final.name + '\n')
            out.flush()
            os.fsync(out.fileno())
        pattern = re.compile(r'time_manager_dev-\d{8}T\d{12}Z\.dump')
        backups = sorted(p for p in root.iterdir()
                         if pattern.fullmatch(p.name) and p.is_file() and not p.is_symlink()
                         and p.with_suffix('.dump.sha256').is_file())
        for old in backups[:-30]:
            old.unlink()
            old.with_suffix('.dump.sha256').unlink()
        print('Backup complete: ' + final.name + '; bytes=' + str(final.stat().st_size))
    finally:
        temp.unlink(missing_ok=True)
