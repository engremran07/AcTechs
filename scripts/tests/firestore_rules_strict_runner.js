const { spawn } = require('child_process');

const command =
  'firebase emulators:exec --config ../firebase.json --only firestore --project demo-actechs-rules-test "node tests/firestore_rules_test.js && node tests/firestore_rules_settlement_shared_test.js"';

const disallowedPatterns = [
  /maximum of 1000 expressions/i,
  /Null value error\./i,
];

const child = spawn(command, {
  shell: true,
  stdio: ['inherit', 'pipe', 'pipe'],
  env: {
    ...process.env,
    NODE_OPTIONS: '--no-deprecation',
  },
});

let output = '';

child.stdout.on('data', (chunk) => {
  const text = chunk.toString();
  output += text;
  process.stdout.write(text);
});

child.stderr.on('data', (chunk) => {
  const text = chunk.toString();
  output += text;
  process.stderr.write(text);
});

child.on('close', (code) => {
  if (code !== 0) {
    process.exitCode = code || 1;
    return;
  }

  for (const pattern of disallowedPatterns) {
    if (pattern.test(output)) {
      console.error(`STRICT FIRESTORE RULES GATE FAILED: matched pattern ${pattern}`);
      process.exitCode = 1;
      return;
    }
  }

  console.log('Strict Firestore rules runner passed: no expression-limit or null-eval errors detected.');
});
