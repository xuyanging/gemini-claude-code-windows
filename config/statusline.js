let data = '';
process.stdin.on('data', c => (data += c));
process.stdin.on('end', () => {
  let cwd = '', modelId = '';
  try {
    const j = JSON.parse(data);
    cwd = j?.workspace?.current_dir || j?.cwd || '';
    modelId = j?.model?.id || '';
  } catch {}

  const shortModel = modelId
    .replace(/^[a-z]+,/, '')
    .replace(/-preview$/, '')
    .replace(/^gemini-/, '');

  const short = cwd ? cwd.split(/[\\/]/).slice(-2).join('/') : '';
  const tag = shortModel
    ? `\x1b[1;35m🤖 GEMINI\x1b[0m \x1b[2m(via CCR →\x1b[0m \x1b[33m${shortModel}\x1b[0m\x1b[2m)\x1b[0m`
    : '\x1b[1;35m🤖 GEMINI\x1b[0m \x1b[2m(via CCR)\x1b[0m';
  process.stdout.write(short ? `${tag}  \x1b[36m${short}\x1b[0m` : tag);
});
