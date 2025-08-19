export default async function handler(req, res) {
  try {
    const vin = req.query.v
    if (!vin) return res.status(400).json({ ok:false, message:'Missing VIN' })
    const url = `https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues/${encodeURIComponent(vin)}?format=json`
    const r = await fetch(url)
    const j = await r.json()
    const row = j?.Results?.[0] || {}
    const decoded = {
      vin,
      year: Number(row.ModelYear) || null,
      make: row.Make || null,
      model: row.Model || null,
      trim: row.Trim || null,
      body: row.BodyClass || null,
      engine: row.DisplacementL ? row.DisplacementL + 'L' : (row.EngineModel || null),
      transmission: row.TransmissionStyle || null,
      color: null,
      mileage: null
    }
    return res.status(200).json({ ok:true, decoded })
  } catch (e) {
    return res.status(500).json({ ok:false, message: e.message || 'VIN decode failed' })
  }
}
