const crypto = require('crypto');

function sha256Hex(input) {
  return crypto.createHash('sha256').update(input, 'utf8').digest('hex');
}

function rsaSignSha256(input, privateKeyPem) {
  const signer = crypto.createSign('RSA-SHA256');
  signer.update(input, 'utf8');
  signer.end();
  return signer.sign(privateKeyPem, 'base64');
}

function rsaVerifySha256(input, signatureBase64, publicKeyPem) {
  const verifier = crypto.createVerify('RSA-SHA256');
  verifier.update(input, 'utf8');
  verifier.end();
  return verifier.verify(publicKeyPem, signatureBase64, 'base64');
}

function aes256GcmDecrypt({ apiV3Key, associatedData, nonce, ciphertext }) {
  const data = Buffer.from(ciphertext, 'base64');
  const authTag = data.subarray(data.length - 16);
  const encrypted = data.subarray(0, data.length - 16);
  const decipher = crypto.createDecipheriv(
    'aes-256-gcm',
    Buffer.from(apiV3Key, 'utf8'),
    Buffer.from(nonce, 'utf8'),
  );
  decipher.setAAD(Buffer.from(associatedData, 'utf8'));
  decipher.setAuthTag(authTag);
  const result = Buffer.concat([decipher.update(encrypted), decipher.final()]);
  return result.toString('utf8');
}

function randomString(size = 32) {
  return crypto.randomBytes(size).toString('hex');
}

module.exports = {
  sha256Hex,
  rsaSignSha256,
  rsaVerifySha256,
  aes256GcmDecrypt,
  randomString,
};
