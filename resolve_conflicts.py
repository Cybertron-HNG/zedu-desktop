import os
import re

def resolve_file(filepath, strategy):
    with open(filepath, 'r') as f:
        content = f.read()
    
    if strategy == 'ours':
        # Keep HEAD
        content = re.sub(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> [^\n]+\n', r'\1\n', content, flags=re.DOTALL)
    elif strategy == 'theirs':
        # Keep incoming
        content = re.sub(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> [^\n]+\n', r'\2\n', content, flags=re.DOTALL)
    elif strategy == 'both':
        # Keep both
        content = re.sub(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> [^\n]+\n', r'\1\n\2\n', content, flags=re.DOTALL)
        
    with open(filepath, 'w') as f:
        f.write(content)

# Resolve pubspec.yaml by keeping both dependencies
resolve_file('pubspec.yaml', 'both')

# Resolve .gitignore keeping both
resolve_file('.gitignore', 'both')

# For generated plugins/locks, accept theirs
generated_files = [
    'pubspec.lock',
    'linux/flutter/generated_plugin_registrant.cc',
    'linux/flutter/generated_plugins.cmake',
    'macos/Flutter/GeneratedPluginRegistrant.swift',
    'windows/flutter/generated_plugin_registrant.cc',
    'windows/flutter/generated_plugins.cmake'
]
for f in generated_files:
    if os.path.exists(f):
        resolve_file(f, 'theirs')

# For Dart files, accept ours since we have the latest refactored barrel exports
dart_files = [
    'lib/core/core.dart',
    'lib/features/auth/data/datasource/auth_remote_datasource.dart',
    'lib/features/auth/data/models/plan_details_model.dart',
    'lib/features/features.dart',
    'lib/features/home/home.dart',
    'lib/features/home/home_view.dart',
    'lib/features/workspaces/presentation/providers/workspace_provider.dart',
    'lib/main.dart'
]
for f in dart_files:
    if os.path.exists(f):
        resolve_file(f, 'ours')

print("Conflicts resolved.")
