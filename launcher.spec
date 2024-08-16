# -*- mode: python ; coding: utf-8 -*-

import sys
import platform

# Default name if not provided
os_plat = platform.platform().lower()
os_name = platform.system().lower()  # This gives a clearer response ('Windows', 'Linux', 'Darwin')

output_name = f'dl4MicEverywhere_{os_plat}'


a = Analysis(
    ['launcher.py'],
    pathex=[],
    binaries=[],
    datas=[('./', './')],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name=output_name,
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
app = BUNDLE(
    exe,
    name='{output_name}.app',
    icon=None,
    bundle_identifier=None,
)
