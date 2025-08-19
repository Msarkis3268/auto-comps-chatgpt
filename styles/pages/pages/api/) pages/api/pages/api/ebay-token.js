export default async function handler(req, res) {
  try {
    const id = process.env.EBAY_CLIENT_ID
    const secret = process.env.EBAY_CLIENT_SECRET
    const scope = process.env.EBAY_SCOPE || 'https://api.ebay.com/oauth/api_scope'
    if (!id || !secret) return res.status(200).json({ ok:false, message:'Add EBAY_CLIENT_ID and EBAY_CLIENT_SECRET' })
    const auth = Buffer.from(`${id}:${secret}`).toString('base64')
    const r = await fetch('https://api.ebay.com/identity/v1/oauth2/token', {
      method:'POST',
      headers:{ 'Content-Type':'application/x-www-form-urlencoded', 'Authorization':`Basic ${auth}` },
      body: new URLSearchParams({ grant_type:'client_credentials', scope })
    })
    const j = await r.json()
    if (!r.ok) return res.status(200).json({ ok:false, message: j.error_description || 'eBay token error', raw:j })
    return res.status(200).json({ ok:true, access_token: j.access_token, expires_in: j.expires_in })
  } catch (e) {
    res.status(500).json({ ok:false, message: e.message || 'eBay token error' })
  }
}
