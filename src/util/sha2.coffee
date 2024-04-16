crypto = require "crypto"
module.exports = (t)->crypto.createHash("sha256").update(t).digest()
