export default async function handler(req, res) {
  try {
    if (process.env.EBAY_ENABLE_MI !== '1') {
      const rows = [
        { title: '2006 Ford GT', sold_price: 395000, miles: 10400, date: '2025-07-28', source:'Demo (eBay MI)', link: '#', photo: 'https://via.placeholder.com/180?text=Sold+1' },
        { title: '2005 Ford GT', sold_price: 402000, miles: 9800, date: '2025-07-12', source:'Demo (BaT)', link: '#', photo: 'https://via.placeholder.com/180?text=Sold+2' }
      ]
      return res.status(200).json({ ok:true, demo:true, rows })
    }

    const tokenResp = await fetch(`${process.env.NEXT_PUBLIC_BASE || ''}/api/ebay-token`)
    const token = await tokenResp.json()
    if (!token.ok) return res.status(200).json({ ok:false, message: token.message || 'Token error' })

    // TODO: Implement Marketplace Insights query per your approved access
    return res.status(200).json({ ok:true, demo:false, message: 'eBay MI token acquired. Implement MI query.' })
  } catch (e) {
    res.status(500).json({ ok:false, message: e.message || 'Sold comps error' })
  }
}
