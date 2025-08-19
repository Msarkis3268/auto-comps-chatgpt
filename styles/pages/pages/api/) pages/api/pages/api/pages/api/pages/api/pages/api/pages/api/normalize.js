export default async function handler(req, res){
  try{
    const { spec } = req.body || {};
    if (!process.env.OPENAI_API_KEY) return res.status(200).json({ ok:true, spec });
    const prompt = `Normalize this vehicle spec to canonical OEM-style strings. Return JSON with keys year, make, model, trim, mileage.
Input: ${JSON.stringify(spec)}`;
    const r = await fetch('https://api.openai.com/v1/chat/completions',{
      method:'POST',
      headers:{'Content-Type':'application/json', 'Authorization':`Bearer ${process.env.OPENAI_API_KEY}`},
      body: JSON.stringify({ model:'gpt-4o-mini', messages:[{role:'user', content: prompt}], temperature:0 })
    });
    const j = await r.json();
    const text = j?.choices?.[0]?.message?.content || '';
    try{ const parsed = JSON.parse(text); return res.status(200).json({ ok:true, spec: parsed }); }
    catch{ return res.status(200).json({ ok:true, spec }); }
  }catch(e){
    res.status(500).json({ ok:false, message: e.message || 'Normalize error' });
  }
}
