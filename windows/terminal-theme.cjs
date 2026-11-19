// Apply the shared Ghostty appearance to Windows Terminal's JSON-with-comments settings.
const fs = require("node:fs");
const path = require("node:path");
const { isDeepStrictEqual } = require("node:util");
const { randomUUID } = require("node:crypto");
const [configDir, settingsFile, parserDir] = process.argv.slice(2);
const jsonc = require(parserDir);

function entries(file) {
  return fs.readFileSync(file, "utf8").split(/\r?\n/)
    .map(line => line.trim()).filter(line => line && !line.startsWith("#"))
    .map(line => {
      const at = line.indexOf("=");
      if (at < 1) throw new Error("Invalid Ghostty setting in " + file + ": " + line);
      return [line.slice(0, at).trim(), line.slice(at + 1).trim()];
    });
}

const config = Object.fromEntries(entries(path.join(configDir, "config")));
const themeName = path.parse(config.theme).name.replace(/[-_]+/g, " ").replace(/\b\w/g, c => c.toUpperCase());
const scheme = { name: themeName + " (Ghostty)" };
const palette = "black red green yellow blue purple cyan white brightBlack brightRed brightGreen brightYellow brightBlue brightPurple brightCyan brightWhite".split(" ");
const fields = { background: "background", foreground: "foreground", "cursor-color": "cursorColor", "selection-background": "selectionBackground" };
for (const [key, value] of entries(path.join(configDir, "themes", config.theme))) {
  if (key === "palette") {
    const [index, hex] = value.split("=");
    if (palette[index]) scheme[palette[index]] = hex;
  } else if (fields[key]) {
    scheme[fields[key]] = "#" + value.replace(/^#/, "");
  }
}
for (const key of [...palette, ...Object.values(fields)]) {
  if (!/^#[0-9a-f]{6}$/i.test(scheme[key])) throw new Error("Invalid theme color: " + key);
}
const size = Number(config["font-size"]);
const opacity = Math.round(Number(config["background-opacity"]) * 100);
if (!(size > 0 && opacity >= 0 && opacity <= 100 && config["font-family"])) throw new Error("Invalid Ghostty appearance");

const original = fs.existsSync(settingsFile) ? fs.readFileSync(settingsFile, "utf8") : null;
let content = (original ?? '{\n    "profiles": { "defaults": {}, "list": [] },\n    "schemes": []\n}\n').replace(/^\uFEFF/, "");
const errors = [];
const settings = jsonc.parse(content, errors, { allowTrailingComma: true });
if (errors.length || !settings || typeof settings !== "object" || Array.isArray(settings)) {
  throw new Error("Cannot read Windows Terminal settings: " + settingsFile);
}
const formattingOptions = { insertSpaces: true, tabSize: 4, eol: content.includes("\r\n") ? "\r\n" : "\n" };
function set(keys, oldValue, newValue) {
  if (!isDeepStrictEqual(oldValue, newValue)) {
    content = jsonc.applyEdits(content, jsonc.modify(content, keys, newValue, { formattingOptions }));
  }
}
const schemes = settings.schemes ?? [];
const index = schemes.findIndex(item => item.name === scheme.name);
set(["schemes", index], schemes[index], scheme); // -1 appends in jsonc-parser
const defaults = settings.profiles?.defaults ?? {};
const font = config["font-family"] === "JetBrainsMono Nerd Font" ? "JetBrainsMono NF" : config["font-family"];
set(["profiles", "defaults", "font", "face"], defaults.font?.face, font);
set(["profiles", "defaults", "font", "size"], defaults.font?.size, size);
set(["profiles", "defaults", "colorScheme"], defaults.colorScheme, scheme.name);
set(["profiles", "defaults", "opacity"], defaults.opacity, opacity);
set(["profiles", "defaults", "useAcrylic"], defaults.useAcrylic, Number(config["background-blur-radius"]) > 0);
if (original?.startsWith("\uFEFF")) content = "\uFEFF" + content;
if (content !== original) {
  fs.mkdirSync(path.dirname(settingsFile), { recursive: true });
  const temp = settingsFile + "." + randomUUID() + ".tmp";
  try {
    fs.writeFileSync(temp, content, { flag: "wx" });
    if (original !== null) {
      if (fs.readFileSync(settingsFile, "utf8") !== original) throw new Error("Terminal settings changed during setup. Rerun setup.");
      const backup = settingsFile + "." + randomUUID() + ".bak";
      fs.copyFileSync(settingsFile, backup, fs.constants.COPYFILE_EXCL);
      console.log("Saved previous Terminal settings to " + backup);
    }
    fs.renameSync(temp, settingsFile);
  } finally {
    fs.rmSync(temp, { force: true });
  }
}
