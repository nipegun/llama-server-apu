#!/usr/bin/env -S PYTHONDONTWRITEBYTECODE=1 python3

"""Run this application's unprivileged Apache instance on available ports."""

import errno
import fcntl
import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
import time

cHome = Path('/opt/llama-server-apu')
cRuntime = cHome / 'web'
cPortFile = cRuntime / 'ports.json'
cBackendPort = 18080
cLastPort = 65535
cModules = (
  'mpm_event', 'unixd', 'authz_core', 'authz_host', 'authz_user', 'authn_core',
  'authn_file', 'auth_basic', 'log_config', 'alias', 'rewrite',
  'headers', 'proxy', 'proxy_http', 'socache_shmcb', 'ssl'
)
vChild = None
vStopping = False


def fStop(pSignal, pFrame):
  global vStopping
  vStopping = True
  if vChild is not None and vChild.poll() is None:
    try:
      os.killpg(vChild.pid, signal.SIGTERM)
    except ProcessLookupError:
      pass


def fReservePort(pFirst, pExcluded):
  """Reserve a wildcard IPv4 port and reject IPv6-only conflicts as well."""
  for vPort in range(pFirst, cLastPort + 1):
    if vPort in pExcluded:
      continue
    lSockets = []
    vKeep = False
    try:
      vSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
      lSockets.append(vSocket)
      # Apache uses SO_REUSEADDR too; TIME_WAIT alone must not move the port.
      vSocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
      vSocket.bind(('0.0.0.0', vPort))
      vSocket.listen(1)
      if socket.has_ipv6:
        try:
          vSocket = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
          lSockets.append(vSocket)
          vSocket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
          vSocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
          vSocket.bind(('::', vPort))
          vSocket.listen(1)
        except OSError as vError:
          if vError.errno not in (errno.EAFNOSUPPORT, errno.EPROTONOSUPPORT, errno.EADDRNOTAVAIL):
            raise
      vKeep = True
      return vPort, lSockets
    except OSError as vError:
      if vError.errno not in (errno.EADDRINUSE, errno.EACCES):
        raise
    finally:
      if not vKeep:
        for vSocket in lSockets:
          vSocket.close()
  raise RuntimeError(f'No usable TCP port between {pFirst} and {cLastPort}')


def fWriteConfiguration(pSettings, pHttpPort, pHttpsPort):
  lModules = []
  for vModule in cModules:
    vLibrary = Path(pSettings['moduleDirectory']) / f'mod_{vModule}.so'
    if vLibrary.is_file():
      lModules.extend([
        f'<IfModule !{vModule}_module>',
        f'  LoadModule {vModule}_module "{vLibrary}"',
        '</IfModule>'
      ])
  vText = (cHome / 'config/apache.conf.in').read_text()
  dValues = {
    '@LOAD_MODULES@': '\n'.join(lModules),
    '@DOMAIN@': pSettings['domain'],
    '@HTTP_PORT@': str(pHttpPort),
    '@HTTPS_PORT@': str(pHttpsPort)
  }
  for vName, vValue in dValues.items():
    vText = vText.replace(vName, vValue)
  (cRuntime / 'apache.conf').write_text(vText)


def fRunWeb(pSettings):
  global vChild
  for vAttempt in range(10):
    if vStopping:
      return 0
    lReservations = []
    try:
      vHttpPort, lHttpSockets = fReservePort(11080, {cBackendPort})
      lReservations.extend(lHttpSockets)
      vHttpsPort, lHttpsSockets = fReservePort(11443, {cBackendPort, vHttpPort})
      lReservations.extend(lHttpsSockets)
      fWriteConfiguration(pSettings, vHttpPort, vHttpsPort)
    finally:
      # Release only our own sockets immediately before Apache binds them.
      for vSocket in lReservations:
        vSocket.close()
    if vStopping:
      return 0
    with (cRuntime / 'startup.log').open('a+', errors='replace') as vLog:
      vLog.seek(0, os.SEEK_END)
      vStart = vLog.tell()
      vErrorLog = Path(f'/var/www/{pSettings["domain"]}-logs/error.log')
      vErrorStart = vErrorLog.stat().st_size if vErrorLog.exists() else 0
      try:
        vChild = subprocess.Popen(
          [pSettings['apacheBinary'], '-f', str(cRuntime / 'apache.conf'), '-D', 'FOREGROUND'],
          stderr=vLog,
          start_new_session=True,
          env={**os.environ, 'LC_ALL': 'C'}
        )
        if vStopping:
          fStop(signal.SIGTERM, None)
        try:
          vStatus = vChild.wait(timeout=1)
        except subprocess.TimeoutExpired:
          dPorts = {
            'httpPort': vHttpPort,
            'httpsPort': vHttpsPort,
            'httpUrl': f'http://{pSettings["domain"]}:{vHttpPort}/',
            'httpsUrl': f'https://{pSettings["domain"]}:{vHttpsPort}/'
          }
          cPortFile.write_text(json.dumps(dPorts, indent=2) + '\n')
          print(f'HTTP: {dPorts["httpUrl"]}\nHTTPS: {dPorts["httpsUrl"]}', flush=True)
          while True:
            if vStopping:
              return 0
            try:
              vStatus = vChild.wait(timeout=1)
              break
            except subprocess.TimeoutExpired:
              continue
        if vStopping:
          return 0
        vLog.seek(0, os.SEEK_END)
        vLog.seek(max(vStart, vLog.tell() - 8192))
        vErrorText = vLog.read()
        if vErrorLog.exists():
          with vErrorLog.open(errors='replace') as vApacheLog:
            vApacheLog.seek(0, os.SEEK_END)
            vApacheLog.seek(max(vErrorStart, vApacheLog.tell() - 8192))
            vErrorText += vApacheLog.read()
        if vStatus and 'Address already in use' in vErrorText:
          print('A selected port was taken during startup; selecting again.', file=sys.stderr, flush=True)
          continue
        if vStatus:
          print(vErrorText, file=sys.stderr)
        return vStatus
      finally:
        cPortFile.unlink(missing_ok=True)
        if vChild is not None:
          try:
            os.killpg(vChild.pid, signal.SIGTERM)
          except ProcessLookupError:
            pass
          try:
            vChild.wait(timeout=30)
          except subprocess.TimeoutExpired:
            os.killpg(vChild.pid, signal.SIGKILL)
            vChild.wait()
          vChild = None
  raise RuntimeError('Ports were repeatedly taken during Apache startup; see web/startup.log')


def fShowUrls():
  for vAttempt in range(300):
    try:
      dPorts = json.loads(cPortFile.read_text())
      print(f'Web UI: {dPorts["httpsUrl"]}\nAPI documentation: {dPorts["httpsUrl"]}api/doc/')
      return 0
    except (FileNotFoundError, json.JSONDecodeError):
      time.sleep(0.1)
  raise RuntimeError('Web service did not publish its ports; see web/startup.log')


def fMain():
  if sys.version_info < (3, 13):
    raise RuntimeError('Python 3.13 or newer is required')
  if sys.argv[1:] == ['--show-urls']:
    return fShowUrls()
  if sys.argv[1:]:
    raise RuntimeError('Only --show-urls is supported')
  if os.geteuid() == 0:
    raise RuntimeError('Run the web service as llama-server-apu, not root')
  os.umask(0o027)
  with (cRuntime / 'launch.lock').open('a') as vLock:
    fcntl.flock(vLock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    cPortFile.unlink(missing_ok=True)
    dSettings = json.loads((cHome / 'config/web.json').read_text())
    signal.signal(signal.SIGTERM, fStop)
    signal.signal(signal.SIGINT, fStop)
    return fRunWeb(dSettings)


if __name__ == '__main__':
  try:
    sys.exit(fMain())
  except (OSError, ValueError, RuntimeError) as vError:
    print(f'Web service failed: {vError}', file=sys.stderr)
    sys.exit(1)
  finally:
    pass
