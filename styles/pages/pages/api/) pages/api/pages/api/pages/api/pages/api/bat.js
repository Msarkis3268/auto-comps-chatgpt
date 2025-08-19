export default async function handler(req, res){
  try{
    if (process.env.BAT_ENABLE !== '1'){
      const rows = [
        { title:'Ford GT (Heritage Livery)', sold_price: 530000, date:'2025-06-20', link:'#', photo:'https://via.placeholder.com/180?text=BaT+1' },
        { title:'2005 Ford GT (Red/Stripes)', sold_price: 410000, date:'2025-06-05', link:'#', photo:'https://via.placeholder.com/180?text=BaT+2' }
      ];
      return res.status(200).json({ ok:true, demo:true, rows, message:'Demo; set BAT_ENABLE=1 to attempt live fetch (subject to site terms).' });
    }
    const { spec } = req.body || {};
    const q = encodeURIComponent(`${spec?.make||''} ${spec?.model||''}`.trim());
    const url = `https://bringatrailer.com/search/?q=${q}&listing_ended=1`;
    const r = await fetch(url, { headers: { 'User-Agent':'Mozilla/5.0 (compatible)'} });
    const html = await r.text();
    const itemRegex = /<a[^>]+class=\"search-result-title-link\"[^>]*href=\"([^\"]+)\"[^>]*>([^<]+)<\\/a>/g;
    const rows = []; let m;
    while ((m = itemRegex.exec(html)) && rows.length < 10){
      rows.push({ title: m[2], link: m[1], sold_price: null, date: null, photo: null });
    }
    return res.status(200).json({ ok:true, demo:false, rows });
  }catch(e){
    res.status(500).json({ ok:false, message: e.message || 'BaT error' });
  }
}
