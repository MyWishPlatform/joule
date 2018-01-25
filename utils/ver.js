process.stdout.write(process.argv[2]);
const hex = process.argv[3];
const hash = process.argv[5];
const build = parseInt(hex.substr(6, 4), 16) + 1;
process.stdout.write(hex.substr(0, 6) + build.toString(16).padStart(4, "0") + hash.padStart(8, "0"));
process.stdout.write(process.argv[4]);
