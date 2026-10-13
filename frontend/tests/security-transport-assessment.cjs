const net = require('node:net');
const http = require('node:http');
const https = require('node:https');
const fs = require('node:fs');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const certificate = fs.readFileSync(process.env.SECURITY_ASSESSMENT_CERT);
const marker = 'disposable-wire-marker-' + crypto.randomBytes(16).toString('hex');

async function capture(targetPort, tls, ca) {
  const chunks = [];
  const sockets = new Set();
  const server = net.createServer(incoming => {
    const outgoing = net.connect(targetPort, '127.0.0.1');
    sockets.add(incoming); sockets.add(outgoing);
    incoming.on('data', data => chunks.push(data));
    incoming.on('error', () => outgoing.destroy());
    outgoing.on('error', () => incoming.destroy());
    incoming.pipe(outgoing).pipe(incoming);
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  try {
    const response = await new Promise((resolve, reject) => {
      const request = (tls ? https : http).request({ hostname:'127.0.0.1',
        port:server.address().port, method:'POST', path:'/api/auth/login',
        headers:{'Content-Type':'application/json', Connection:'close'}, ...(ca ? {ca} : {}) }, response => {
          response.resume(); response.on('end', () => resolve(response.statusCode));
        });
      request.on('error', reject);
      request.end(JSON.stringify({email:'invalid-transport-probe@assessment.invalid', password:marker}));
    });
    assert.equal(response, 401);
    return Buffer.concat(chunks).includes(Buffer.from(marker));
  } finally {
    for (const socket of sockets) socket.destroy();
    await new Promise(resolve => server.close(resolve));
  }
}
(async () => {
  assert.equal(await capture(5173, false), true);
  await assert.rejects(capture(8443, true), error => /certificate|self.signed/i.test(error.message));
  assert.equal(await capture(8443, true, certificate), false);
  console.log(JSON.stringify({ http_credential_visible_to_tcp_observer:true,
    tls_credential_visible_to_tcp_observer:false, untrusted_certificate_rejected:true,
    certificate_scope:'ephemeral localhost CA explicitly trusted for the controlled TLS test' }));
})().catch(error => { console.error(error); process.exitCode=1; });
