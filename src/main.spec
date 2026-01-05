# -*- mode: python ; coding: utf-8 -*-

# 소스 파일 포함
datas = [
    ('backend', 'backend'),
    ('src', 'src'),
    ('windows', 'windows'),
]

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=datas,
    hiddenimports=[
        'PySide6.QtWebEngineCore',
        'PySide6.QtMultimedia',
        'PySide6.QtLocation',
        'PySide6.QtPositioning'
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure, a.zipped_data)

# EXE 객체: 핵심 실행 파일을 정의합니다.
# console=True -> 터미널 창이 뜨는 앱
# console=False -> 창만 뜨는 GUI 앱 (.app 번들에 해당)
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='NALDA',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='frontend/assets/app.ico',
)

# BUNDLE 객체: EXE를 감싸서 .app 번들을 만듭니다.
# 이 객체가 있으면 onedir 모드로 .app이 생성됩니다.
app = BUNDLE(
    exe,
    name='NALDA.app',
    icon='frontend/assets/app.ico',
    bundle_identifier=None,
)
