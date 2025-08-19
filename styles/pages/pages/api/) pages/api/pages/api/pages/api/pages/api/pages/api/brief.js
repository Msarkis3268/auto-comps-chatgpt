export default async function handler(req, res){
  try{
    const { metrics, vehicle } = req.body || {};
    if (!process.env.OPENAI_API_KEY) return res.status(200).json({ok:false, message:'Add OPENAI_API_KEY'});
    const prompt = `Write a 3-5 sentence pricing brief for a ${vehicle?.year||''} ${vehicle?.make||''} ${vehicle?.model||''} ${vehicle?.trim||''}.
Use these metrics (JSON): ${JSON.stringify(metrics)}.
Explain current market level, spread between list and sold, and give a buy target range with confidence. Keep it concise and professional.`;
    const r = await fetch('https://api.openai.com/v1/chat/completions',{
      method:'POST',
      headers:{'Content-Type':'application/json', 'Authorization':`Bearer ${process.env.OPENAI_API_KEY}`},
      body: JSON.stringify({ model:'gpt-4o-mini', messages:[{role:'user', content: prompt}], temperature:0.3 })
    });
    const j = await r.json();
    const text = j?.choices?.[0]?.message?.content?.trim() || '';
    return res.status(200).json({ok:true, text});
  }catch(e){
    res.status(500).json({ok:false, message:e.message||'Brief error'});
  }
}
