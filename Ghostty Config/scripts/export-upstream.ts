// SPDX-License-Identifier: Apache-2.0
// Native extraction and license-policy adaptation: Copyright 2026 Damon Lu (@WhatDamon).
// Based on Ghostty Config, Copyright 2024 Zerebos; see LICENSE and NOTICE.

// Evaluate checked-in data modules only; no package install, initializers or fetch.
// The source checkout and exact revision are provided by sync-web-settings.py.
const [root, revision] = process.argv.slice(2);
const transpiler = new Bun.Transpiler({loader: "ts"});
function evaluate(source: string, args: Record<string, unknown>, result: string) {
    source = source.replace(/^import .*;.*$/gm, "").replace(/^export default .*;$/gm, "").replaceAll("export ", "");
    return new Function(...Object.keys(args), transpiler.transformSync(source) + "\nreturn " + result + ";")(...Object.values(args));
}
const themes = evaluate(await Bun.file(root + "/src/lib/data/themes.ts").text(), {}, "themes");
const iconNames = ["official", "blueprint", "chalkboard", "microchip", "glass", "holographic", "paper", "retro", "xray"];
const options = {
    themeOptions: Object.keys(themes).map(name => ({name, value: name})),
    macosIconOptions: [...iconNames, "custom", "custom-style"].map(value => ({name: value, value})),
    macosIconFrameOptions: ["aluminum", "beige", "plastic", "chrome"].map(value => ({name: value, value}))
};
const registry = evaluate(await Bun.file(root + "/src/lib/settings/registry.ts").text(), {dev: false, ...options}, "registry");
// Native app targets macOS; initialize its platform-dependent defaults explicitly.
registry.quitAfterLastWindowClosed.default = "false";
registry.clipboardCodepointMap = {key: "clipboard-codepoint-map", name: "Clipboard codepoint remapping", default: [], repeatable: true, description: "Map codepoints when copying text. Each entry uses Ghostty's clipboard-codepoint-map syntax."};
const navSource = await Bun.file(root + "/src/lib/settings/navigation.ts").text();
const imageNames = [...navSource.matchAll(/^import (\w+) from [^;]+images[^;]+;.*$/gm)].map(m => m[1]);
const allNavigation = evaluate(navSource, {dev:false, registry, ...Object.fromEntries(imageNames.map(n => [n,n]))}, "navigation");
const navigation = allNavigation.filter((p: {id: string}) => !["gtk", "linux"].includes(p.id));
navigation.find((p: {id: string}) => p.id === "clipboard").groups[0].settings.push("clipboardCodepointMap");
const source = {repository: "https://github.com/zerebos/ghostty-config", revision, platform: "macos"};
console.log(JSON.stringify({source, registry, navigation, themes}, null, 2));
