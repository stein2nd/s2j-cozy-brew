#!/usr/bin/env node
/**
 * package.json の version / buildNumber を CozyBrewApp の Xcode 版情報に反映する (アプローチ B)。
 *
 * 使用方法:
 *   node scripts/sync-app-version.mjs          # project.yml と Info.plist を更新
 *   node scripts/sync-app-version.mjs --check      # 未同期なら exit 1
 *   node scripts/sync-app-version.mjs --bump-build # buildNumber++ のあと同期
 *
 * npm:
 *   npm run version:sync       # 同期 + xcodegen
 *   npm run version:check      # 同期済みか確認
 *   npm run version:bump-build # buildNumber++ → 同期 + xcodegen
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");

const PATHS = {
  packageJson: path.join(ROOT, "package.json"),
  projectYml: path.join(ROOT, "project.yml"),
  infoPlist: path.join(ROOT, "CozyBrewApp", "Info.plist"),
};

const VERSIONING_KEYS = {
  marketing: "MARKETING_VERSION",
  build: "CURRENT_PROJECT_VERSION",
  versioningSystem: "VERSIONING_SYSTEM",
};

const PLIST_MARKETING = "$(MARKETING_VERSION)";
const PLIST_BUILD = "$(CURRENT_PROJECT_VERSION)";

function loadPackage() {
  const pkg = JSON.parse(fs.readFileSync(PATHS.packageJson, "utf8"));
  const version = pkg.version;
  const buildNumber = pkg.buildNumber;

  if (!version || typeof version !== "string") {
    throw new Error("package.json に version がありません");
  }
  if (!/^\d+\.\d+\.\d+(-[\w.]+)?$/.test(version)) {
    throw new Error(`package.json version の形式が不正です: ${version}`);
  }
  if (buildNumber === undefined || buildNumber === null || buildNumber === "") {
    throw new Error(
      "package.json に buildNumber がありません (例: \"buildNumber\": 4)。CFBundleVersion に相当します",
    );
  }
  const build = String(buildNumber);
  if (!/^\d+$/.test(build)) {
    throw new Error(`buildNumber は非負の整数にしてください: ${build}`);
  }

  return { version, build };
}

function upsertYamlSetting(settingsBlock, key, value) {
  const line = `      ${key}: "${value}"`;
  const re = new RegExp(`^      ${key}:.*$`, "m");
  if (re.test(settingsBlock)) {
    return settingsBlock.replace(re, line);
  }
  return `${settingsBlock}${line}\n`;
}

function syncProjectYml({ version, build }) {
  let yml = fs.readFileSync(PATHS.projectYml, "utf8");

  const marker = "  CozyBrewApp:";
  const start = yml.indexOf(marker);
  if (start === -1) {
    throw new Error("project.yml に CozyBrewApp ターゲットがありません");
  }

  const nextTarget = yml.indexOf("\n  CozyBrewCore:", start);
  const end = nextTarget === -1 ? yml.length : nextTarget;
  let block = yml.slice(start, end);

  const settingsMatch = block.match(/    settings:\n((?:      [^\n]+\n)*)/);
  if (!settingsMatch) {
    throw new Error("CozyBrewApp.settings が見つかりません");
  }

  let settingsBody = settingsMatch[1];
  settingsBody = upsertYamlSetting(settingsBody, VERSIONING_KEYS.marketing, version);
  settingsBody = upsertYamlSetting(settingsBody, VERSIONING_KEYS.build, build);
  settingsBody = upsertYamlSetting(
    settingsBody,
    VERSIONING_KEYS.versioningSystem,
    "apple-generic",
  );

  block = block.replace(settingsMatch[0], `    settings:\n${settingsBody}`);

  block = block.replace(
    /        CFBundleShortVersionString:.*\n/,
    `        CFBundleShortVersionString: ${PLIST_MARKETING}\n`,
  );
  block = block.replace(
    /        CFBundleVersion:.*\n/,
    `        CFBundleVersion: ${PLIST_BUILD}\n`,
  );

  const updated = yml.slice(0, start) + block + yml.slice(end);
  return updated;
}

function syncInfoPlist() {
  let plist = fs.readFileSync(PATHS.infoPlist, "utf8");

  plist = plist.replace(
    /(<key>CFBundleShortVersionString<\/key>\s*<string>)[^<]+(<\/string>)/,
    `$1${PLIST_MARKETING}$2`,
  );
  plist = plist.replace(
    /(<key>CFBundleVersion<\/key>\s*<string>)[^<]+(<\/string>)/,
    `$1${PLIST_BUILD}$2`,
  );

  return plist;
}

function expectedFromFiles() {
  const yml = fs.readFileSync(PATHS.projectYml, "utf8");
  const mVer = yml.match(/^\s+MARKETING_VERSION: "([^"]+)"/m);
  const mBuild = yml.match(/^\s+CURRENT_PROJECT_VERSION: "([^"]+)"/m);

  const short = yml.match(/^\s+CFBundleShortVersionString: (.+)$/m);
  const bundle = yml.match(/^\s+CFBundleVersion: (.+)$/m);

  const plist = fs.readFileSync(PATHS.infoPlist, "utf8");
  const pShort = plist.match(
    /<key>CFBundleShortVersionString<\/key>\s*<string>([^<]+)<\/string>/,
  );
  const pBuild = plist.match(/<key>CFBundleVersion<\/key>\s*<string>([^<]+)<\/string>/);

  return {
    ymlMarketing: mVer?.[1] ?? null,
    ymlBuild: mBuild?.[1] ?? null,
    ymlShortRef: short?.[1]?.trim() ?? null,
    ymlBundleRef: bundle?.[1]?.trim() ?? null,
    plistShort: pShort?.[1] ?? null,
    plistBuild: pBuild?.[1] ?? null,
  };
}

function isInSync(expected, { version, build }) {
  const refsOk =
    expected.ymlShortRef === PLIST_MARKETING &&
    expected.ymlBundleRef === PLIST_BUILD &&
    expected.plistShort === PLIST_MARKETING &&
    expected.plistBuild === PLIST_BUILD;

  return (
    refsOk &&
    expected.ymlMarketing === version &&
    expected.ymlBuild === build
  );
}

function bumpBuildNumberInPackageJson() {
  const raw = fs.readFileSync(PATHS.packageJson, "utf8");
  const pkg = JSON.parse(raw);
  const current = pkg.buildNumber;
  if (current === undefined || current === null || current === "") {
    throw new Error("package.json に buildNumber がありません");
  }
  const next = Number(current) + 1;
  if (!Number.isFinite(next) || next < 0 || !Number.isInteger(next)) {
    throw new Error(`buildNumber をインクリメントできません: ${current}`);
  }
  pkg.buildNumber = next;
  fs.writeFileSync(PATHS.packageJson, `${JSON.stringify(pkg, null, 2)}\n`);
  console.log(`buildNumber: ${current} → ${next}`);
  return { version: pkg.version, build: String(next) };
}

function main() {
  const checkOnly = process.argv.includes("--check");
  const bumpBuild = process.argv.includes("--bump-build");

  if (bumpBuild && checkOnly) {
    throw new Error("--bump-build と --check は同時に指定できません");
  }

  if (bumpBuild) {
    bumpBuildNumberInPackageJson();
  }

  const { version, build } = loadPackage();

  const nextYml = syncProjectYml({ version, build });
  const nextPlist = syncInfoPlist();
  const current = expectedFromFiles();

  if (checkOnly) {
    if (!isInSync(current, { version, build })) {
      console.error(
        `version:check 失敗: package.json は ${version} (${build}) ですが、project.yml / Info.plist が未同期です。npm run version:sync を実行してください。`,
      );
      process.exit(1);
    }
    console.log(`OK: CozyBrewApp ${version} (build ${build})`);
    return;
  }

  const ymlChanged = nextYml !== fs.readFileSync(PATHS.projectYml, "utf8");
  const plistChanged = nextPlist !== fs.readFileSync(PATHS.infoPlist, "utf8");

  if (ymlChanged) {
    fs.writeFileSync(PATHS.projectYml, nextYml);
  }
  if (plistChanged) {
    fs.writeFileSync(PATHS.infoPlist, nextPlist);
  }

  if (ymlChanged || plistChanged) {
    console.log(`Updated: MARKETING_VERSION=${version}, CURRENT_PROJECT_VERSION=${build}`);
    console.log("  project.yml, CozyBrewApp/Info.plist → $(MARKETING_VERSION) / $(CURRENT_PROJECT_VERSION)");
  } else if (isInSync(current, { version, build })) {
    console.log(`Already synced: CozyBrewApp ${version} (build ${build})`);
  } else {
    console.log(`Synced metadata: CozyBrewApp ${version} (build ${build})`);
  }
}

main();
