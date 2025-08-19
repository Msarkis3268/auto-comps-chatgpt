export default async function handler(req, res) {
  try {
    const key = process.env.MARKETCHECK_API_KEY
    const spec = req.body?.spec || {}
    const { year, make, model } = spec

    if (!key) {
      const now = new Date().toISOString()
      const demoRows = [
        { title: `${year||2006} ${make||'Ford'} ${model||'GT'}`, price: 415000, miles: 9800, source: 'Demo', link: '#', photo: 'https://via.placeholder.com/180?text=Listing+1', year: year||2006, make: make||'Ford', model: model||'GT', listed_at: now },
        { title: `${year||2006} ${make||'Ford'} ${model||'GT'} Tungsten`, price: 429000, miles: 12000, source: 'Demo', link: '#', photo: 'https://via.placeholder.com/180?text=Listing+2', year: year||2006, make: make||'Ford', model: model||'GT', listed_at: now },
        { title: `${year||2005} ${make||'Ford'} ${model||'GT'}`, price: 399000, miles: 13500, source: 'Demo', link: '#', photo: 'https://via.placeholder.com/180?text=Listing+3', year: year||2005, make: make||'Ford', model: model||'GT', listed_at: now }
      ]
      return res.status(200).json({ ok:true, total: demoRows.length, rows: demoRows, message: 'Demo Mode (add MARKETCHECK_API_KEY for live data)' })
    }

    if (!year || !make || !model) {
      return res.status(400).json({ ok:false, message: 'Missing year/make/model' })
    }

    const params = new URLSearchParams({
      year: String(year),
      make: make,
      model: model,
      car_type: 'used',
      api_key: key,
      rows: '100',
      sort_by: 'price_desc'
    })
    if (spec.trim) params.set('trim', spec.trim)

    const url = `https://marketcheck-prod.apigee.net/v2/search/car/active?${params.toString()}`
    const r = await fetch(url)
    if (!r.ok) {
      const txt = await r.text()
      return res.status(200).json({ ok:false, message: 'MarketCheck error: ' + txt.slice(0,180) })
    }
    const j = await r.json()

    const rows = (j.listings || []).map(li => {
      const listedAt =
        li.list_date ||
        li.first_seen_at ||
        (typeof li.dom === 'number' ? new Date(Date.now() - li.dom*86400000).toISOString() : null)

      const photo =
        (li.media?.photo_links && li.media.photo_links.find(Boolean)) ||
        li.media?.photo_link ||
        (li.media?.photos && li.media.photos[0]?.url) ||
        null

      const link = li.vdp_url || li.deep_link || li.media?.photo_link || null

      return {
        title: li.build ? `${li.build.year} ${li.build.make} ${li.build.model} ${li.build.trim||''}`.trim() : li.heading || '',
        price: li.price ?? null,
        miles: li.miles ?? null,
        source: li.source || 'MarketCheck',
        link,
        photo,
        year: li.build?.year,
        make: li.build?.make,
        model: li.build?.model,
        trim: li.build?.trim || null,
        listed_at: listedAt
      }
    })
    return res.status(200).json({ ok:true, total: j.num_found || rows.length, rows })
  } catch (e) {
    return res.status(500).json({ ok:false, message: e.message || 'Active listings failed' })
  }
}
