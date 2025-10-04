#!/bin/bash

echo "=== TaskLock Project Validation ==="
echo "Checking project structure..."

# Check if required files exist
if [ ! -f "TaskLock.xcodeproj/project.pbxproj" ]; then
    echo "ERROR: Xcode project file not found"
    exit 1
fi

if [ ! -f "TaskLock/TaskLockApp.swift" ]; then
    echo "ERROR: TaskLockApp.swift not found"
    exit 1
fi

if [ ! -f "TaskLock/ContentView.swift" ]; then
    echo "ERROR: ContentView.swift not found"
    exit 1
fi

if [ ! -f "TaskLock/Info.plist" ]; then
    echo "ERROR: Info.plist not found"
    exit 1
fi

echo "✓ All required files found"

# Check Swift syntax
echo "Checking Swift syntax..."
if command -v swiftc &> /dev/null; then
    swiftc -parse TaskLock/TaskLockApp.swift
    if [ $? -eq 0 ]; then
        echo "✓ TaskLockApp.swift syntax OK"
    else
        echo "ERROR: TaskLockApp.swift syntax error"
        exit 1
    fi
    
    swiftc -parse TaskLock/ContentView.swift
    if [ $? -eq 0 ]; then
        echo "✓ ContentView.swift syntax OK"
    else
        echo "ERROR: ContentView.swift syntax error"
        exit 1
    fi
else
    echo "⚠ swiftc not available, skipping syntax check"
fi

echo "=== Project validation complete ==="
