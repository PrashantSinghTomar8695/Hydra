# Phase 1 — Next Steps & Manual Actions Required

## Critical: Android SDK Installation

The Android build is blocked because the Android SDK is not installed in WSL.

### Option 1: Install via Android Studio (Recommended)

1. Download Android Studio for Linux
2. Install to `/opt/android-sdk` or user directory
3. Update `android/local.properties`:
   ```
   sdk.dir=/opt/android-sdk
   ```

### Option 2: Command-Line Tools Only

Run in WSL:
```bash
wsl --distribution kali-linux -- bash -lc "
cd /tmp &&
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip &&
unzip commandlinetools-linux-*.zip &&
mkdir -p /opt/android-sdk/cmdline-tools &&
mv cmdline-tools /opt/android-sdk/cmdline-tools/latest &&
export ANDROID_HOME=/opt/android-sdk &&
/opt/android-sdk/cmdline-tools/latest/bin/sdkmanager 'platform-tools' 'platforms;android-34' 'build-tools;34.0.0' 'ndk;25.1.8937393'
"
```

Then update `android/local.properties`:
```
sdk.dir=/opt/android-sdk
```

## After SDK Installation

1. **Re-run Android build:**
   ```bash
   cd android && ./gradlew assembleDebug
   ```

2. **Copy APK to artifacts:**
   ```bash
   cp android/app/build/outputs/apk/debug/*.apk build_artifacts/phase1/apk/
   ```

3. **Run Android tests:**
   ```bash
   cd android && ./gradlew testDebugUnitTest
   ```

## Git Operations

**Review changes:**
```bash
cd /mnt/c/Users/prash/OneDrive/Documents/test_project
git log hydra/phase1-auto-fixes-*
git diff origin/main
```

**Push branch (after review):**
```bash
git push origin hydra/phase1-auto-fixes-<timestamp>
```

**Create PR (if using GitHub/GitLab):**
- Push branch to remote
- Create pull request from branch to main
- Review automated fixes
- Merge after approval

## Testing Recommendations

1. **Add Rust unit tests:**
   - Create `android/rust/src/store_test.rs`
   - Test put/get/delete operations
   - Test checksum validation
   - Test LRU eviction

2. **Add Android unit tests:**
   - Test `RAMObjectStore` wrapper
   - Test `JobLedger` operations
   - Test service lifecycle

3. **Integration tests:**
   - Test JNI bridge
   - Test end-to-end job flow

## iOS Build Setup

Since macOS is not available in WSL, create GitHub Actions workflow:

1. **Create `.github/workflows/ios-build.yml`**
2. **Use `macos-latest` runners**
3. **Build and test iOS project**

See `build_artifacts/phase1/ios_ci_workflow.yml` (if generated)

## Performance Benchmarks

Once builds succeed:

1. **Benchmark RAM store:**
   - Throughput (ops/sec)
   - Memory usage
   - Latency

2. **Benchmark JNI:**
   - Call overhead
   - Data transfer speed

3. **Profile Android app:**
   - Memory usage
   - CPU usage
   - Battery impact

---

**Last Updated:** 2025-11-16

