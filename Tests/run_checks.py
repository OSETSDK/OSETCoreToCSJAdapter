#!/usr/bin/env python3
"""Run actual adapter sources against controlled macOS doubles and optional cached iOS headers.

These checks do not validate device presentation, live fill, server delivery, or billing.
Usage: python3 Tests/run_checks.py [--real-sdk] [--oset-xcframework PATH]
"""
import argparse
import pathlib
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--real-sdk', action='store_true', help='also compile against cached matching BUAdSDK and OSETSDK')
parser.add_argument('--oset-xcframework', type=pathlib.Path)
args = parser.parse_args()
repo = pathlib.Path(__file__).resolve().parents[1]
source = repo / repo.name
tests = repo / 'Tests'
output = pathlib.Path(tempfile.mkdtemp(prefix=repo.name + '-checks-', dir='/private/tmp'))
print('Artifacts:', output, flush=True)

def run(command, log_name):
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (output / log_name).write_text(result.stdout)
    if result.stdout:
        print(result.stdout, end='', flush=True)
    if result.returncode:
        raise SystemExit(result.returncode)

for module in ('BUAdSDK', 'OSETSDK'):
    directory = output / 'include' / module
    directory.mkdir(parents=True)
    (directory / (module + '.h')).write_text('#import "' + str(tests / 'FakeSDK.h') + '"\n')
run(['xcrun', 'clang', '-fobjc-arc', '-fblocks', '-Werror=format', '-Werror=protocol',
     '-I', str(output / 'include'), '-I', str(source), '-I', str(tests),
     '-framework', 'Foundation', '-framework', 'CoreGraphics',
     str(tests / 'FakeSDK.m'), str(tests / 'AdapterBehaviorTests.m'),
     *[str(source / ('OSETCustomerGm' + name + 'Adapter.m')) for name in ('Splash', 'Interstitial', 'Reward', 'Native')],
     '-o', str(output / 'behavior-tests')], 'behavior-build.log')
run([str(output / 'behavior-tests')], 'behavior-run.log')

if args.real_sdk:
    pod = 'Ads-CN-Beta' if repo.name == 'OSETCoreToGMAdapter' else 'Ads-CN'
    cache = pathlib.Path.home() / 'Library/Caches/CocoaPods/Pods/Release' / pod
    versions = [p for p in cache.iterdir() if p.is_dir()]
    latest = max(versions, key=lambda p: tuple(int(part) for part in p.name.split('-')[0].split('.')))
    framework = latest / 'SDK/BUAdSDK.xcframework/ios-arm64'
    oset = args.oset_xcframework or repo.parent / 'OSETCoreAd/OSETSDK.xcframework'
    sdk = subprocess.check_output(['xcrun', '--sdk', 'iphoneos', '--show-sdk-path'], text=True).strip()
    print('iOS headers:', latest, oset, flush=True)
    for path in sorted(source.glob('*.m')):
        run(['xcrun', 'clang', '-fsyntax-only', '-fobjc-arc', '-fmodules',
             '-fmodules-cache-path=' + str(output / 'modules'), '-target', 'arm64-apple-ios12.0',
             '-isysroot', sdk, '-F', str(oset / 'ios-arm64'), '-F', str(framework),
             '-Werror=format', '-Werror=protocol', str(path)], path.stem + '.log')
    print('PASS: 5 adapter files compiled against actual iOS SDK headers', flush=True)
