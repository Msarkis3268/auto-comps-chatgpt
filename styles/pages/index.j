import { useState, useMemo } from 'react'

function avg(nums){ if(!nums?.length) return null; return Math.round(nums.reduce((a,b)=>a+b,0)/nums.length); }
function parse(d){ try{return d?new Date(d):null}catch{return null} }
function withinDays(d,days){ return d && ((Date.now()-d.getTime())/(1000*60*60*24) <= days) }

export default function Home() {
  const [mode, setMode] = useState('vin')
  const [vin, setVin] = useState('')
  const [manual, setManual] = useState({ year:'', make:'', model:'', trim:'', mileage:'' })
  const [vehicle, setVehicle] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [activeRows, setActiveRows] = useState([])
  const [soldRows, setSoldRows] = useState([])
  const [batRows, setBatRows] = useState([])
  const [brief, setBrief] = useState('')
  const [tab, setTab] = useState('active')

  const metrics = useMemo(()=>{
    const out = {
      activeCount: activeRows?.length || 0,
      listAvgCurrent: null, listAvg30:null, listAvg60:null, listAvg90:null,
      soldAvg30:null, soldAvg60:null, soldAvg90:null
    }
    const actPrices = activeRows?.map(r=>r.price).filter(x=>typeof x==='number') || []
    out.listAvgCurrent = avg(actPrices)

    const actWithDates = activeRows?.filter(r=>r.listed_at)?.map(r=>({p:r.price, d:parse(r.listed_at)})) || []
    if (actWithDates.length){
      out.listAvg30 = avg(actWithDates.filter(x=>withinDays(x.d,30)).map(x=>x.p).filter(Number.isFinite))
      out.listAvg60 = avg(actWithDates.filter(x=>withinDays(x.d,60)).map(x=>x.p).filter(Number.isFinite))
      out.listAvg90 = avg(actWithDates.filter(x=>withinDays(x.d,90)).map(x=>x.p).filter(Number.isFinite))
    }

    const soldWithDates = soldRows?.map(r=>({p:r.sold_price, d:parse(r.date)})) || []
    out.soldAvg30 = avg(soldWithDates.filter(x=>withinDays(x.d,30)).map(x=>x.p).filter(Number.isFinite))
    out.soldAvg60 = avg(soldWithDates.filter(x=>withinDays(x.d,60)).map(x=>x.p).filter(Number.isFinite))
    out.soldAvg90 = avg(soldWithDates.filter(x=>withinDays(x.d,90)).map(x=>x.p).filter(Number.isFinite))
    return out
  }, [activeRows, soldRows])

  const handleGetComps = async () => {
    setError(''); setLoading(true); setBrief('')
    try {
      let spec = null
      if (mode === 'vin') {
        if (!vin || vin.length < 11) throw new Error('Enter a valid VIN (at least 11 chars).')
        const v = await fetch('/api/vin?v=' + encodeURIComponent(vin)).then(r=>r.json())
        if (!v || !v.ok) throw new Error(v?.message || 'VIN decode failed.')
        spec = { year: v.decoded.year, make: v.decoded.make, model: v.decoded.model, trim: v.decoded.trim || '', mileage: v.decoded.mileage || '' }
      } else {
        const {year, make, model, trim, mileage} = manual
        if (!year || !make || !model || !trim || !mileage) throw new Error('Fill Year, Make, Model, Trim, Mileage.')
        spec = { year, make, model, trim, mileage: Number(mileage) }
      }

      const norm = await fetch('/api/normalize', {
        method: 'POST', headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ spec })
      }).then(r=>r.json())
      const normalized = norm?.ok ? norm.spec : spec
      setVehicle(normalized)

      const act = await fetch('/api/active', {
        method: 'POST', headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ spec: normalized, days: 90 })
      }).then(r=>r.json())
      if (!act.ok) throw new Error(act.message || 'Could not fetch active listings.')
      setActiveRows(act.rows || [])

      const sold = await fetch('/api/sold', {
        method: 'POST', headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ spec: normalized, days: 90 })
      }).then(r=>r.json())
      if (sold?.ok) setSoldRows(sold.rows || [])

      const bat = await fetch('/api/bat', {
        method: 'POST', headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ spec: normalized, days: 180 })
      }).then(r=>r.json())
      if (bat?.ok) setBatRows(bat.rows || [])

    } catch(e) {
      setError(e.message || 'Something went wrong.')
    } finally {
      setLoading(false)
    }
  }

  const handleBrief = async () => {
    setBrief('')
    const resp = await fetch('/api/brief', {
      method:'POST',
      headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ metrics, vehicle })
    }).then(r=>r.json())
    if (resp?.ok) setBrief(resp.text || '')
  }

  return (
    <div className="container">
      <div className="card">
        <h1>Auto Comps — ChatGPT Powered (No MMR/KBB)</h1>
        <p>Enter a VIN or manual details (Year, Make, Model, Trim, Mileage). Active listings use MarketCheck (or Demo). Sold comps use eBay MI + Bring a Trailer (or Demo).</p>
        <div className="grid" style={{marginTop:12}}>
          <button onClick={()=>setMode('vin')} style={{background: mode==='vin'?'#111':'#f5f5f5', color: mode==='vin'?'#fff':'#111'}}>VIN</button>
          <button onClick={()=>setMode('manual')} style={{background: mode==='manual'?'#111':'#f5f5f5', color: mode==='manual'?'#fff':'#111'}}>Manual</button>
        </div>

        {mode==='vin' ? (
          <div style={{marginTop:12}}>
            <label>VIN</label>
            <input value={vin} onChange={e=>setVin(e.target.value)} placeholder="e.g., 1FAFP90S76Y400777" />
          </div>
        ) : (
          <div className="grid" style={{marginTop:12}}>
            <div><label>Year</label><input value={manual.year} onChange={e=>setManual({...manual, year:e.target.value})} placeholder="2006" /></div>
            <div><label>Make</label><input value={manual.make} onChange={e=>setManual({...manual, make:e.target.value})} placeholder="Ford" /></div>
            <div><label>Model</label><input value={manual.model} onChange={e=>setManual({...manual, model:e.target.value})} placeholder="GT" /></div>
            <div><label>Trim</label><input value={manual.trim} onChange={e=>setManual({...manual, trim:e.target.value})} placeholder="Base / Heritage / etc." /></div>
            <div><label>Mileage</label><input value={manual.mileage} onChange={e=>setManual({...manual, mileage:e.target.value})} placeholder="11250" /></div>
          </div>
        )}

        <div style={{marginTop:12}}>
          <button onClick={handleGetComps} disabled={loading}>{loading?'Working…':'Get Comps'}</button>
        </div>

        {error && <div className="notice" style={{marginTop:12}}>{error}</div>}
      </div>

      {vehicle && (
        <div className="card">
          <h2>Vehicle</h2>
          <pre style={{whiteSpace:'pre-wrap', overflowX:'auto'}}>{JSON.stringify(vehicle, null, 2)}</pre>
        </div>
      )}

      <div className="card">
        <h2>Market Snapshot</h2>
        <div className="grid">
          <div><strong>Active for Sale:</strong><br/>{metrics.activeCount}</div>
          <div><strong>Avg List (current):</strong><br/>{metrics.listAvgCurrent ? `$${metrics.listAvgCurrent.toLocaleString()}` : '—'}</div>
          <div><strong>Avg List (30d):</strong><br/>{metrics.listAvg30 ? `$${metrics.listAvg30.toLocaleString()}` : '—'}</div>
          <div><strong>Avg List (60d):</strong><br/>{metrics.listAvg60 ? `$${metrics.listAvg60.toLocaleString()}` : '—'}</div>
          <div><strong>Avg List (90d):</strong><br/>{metrics.listAvg90 ? `$${metrics.listAvg90.toLocaleString()}` : '—'}</div>
          <div><strong>Avg Sold (30d):</strong><br/>{metrics.soldAvg30 ? `$${metrics.soldAvg30.toLocaleString()}` : '—'}</div>
          <div><strong>Avg Sold (60d):</strong><br/>{metrics.soldAvg60 ? `$${metrics.soldAvg60.toLocaleString()}` : '—'}</div>
          <div><strong>Avg Sold (90d):</strong><br/>{metrics.soldAvg90 ? `$${metrics.soldAvg90.toLocaleString()}` : '—'}</div>
        </div>
      </div>

      <div className="card">
        <div className="tabs">
          <div className={`tab ${tab==='active'?'active':''}`} onClick={()=>setTab('active')}>Active</div>
          <div className={`tab ${tab==='sold'?'active':''}`} onClick={()=>setTab('sold')}>Sold</div>
          <div className={`tab ${tab==='bat'?'active':''}`} onClick={()=>setTab('bat')}>Bring a Trailer</div>
        </div>

        {tab==='active' && (
          <div>
            {activeRows?.length>0 ? (
              <table className="table">
                <thead><tr><th>Photo</th><th>Title</th><th>Price</th><th>Miles</th><th>Source</th><th>Link</th><th>Listed</th></tr></thead>
                <tbody>
                  {activeRows.map((r, i)=> (
                    <tr key={i}>
                      <td>{r.photo ? <img src={r.photo} alt="Listing photo" width={100} loading="lazy" /> : '—'}</td>
                      <td>{r.title || `${r.year} ${r.make} ${r.model}`}</td>
                      <td>{typeof r.price==='number' ? `$${r.price.toLocaleString()}` : '—'}</td>
                      <td>{r.miles ?? '—'}</td>
                      <td>{r.source || '—'}</td>
                      <td>{r.link ? <a href={r.link} target="_blank" rel="noopener noreferrer">Open</a> : '—'}</td>
                      <td>{r.listed_at ? new Date(r.listed_at).toLocaleDateString() : '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : <div className="notice">No active listings yet. Tap Get Comps.</div>}
          </div>
        )}

        {tab==='sold' && (
          <div>
            {soldRows?.length>0 ? (
              <table className="table">
                <thead><tr><th>Photo</th><th>Title</th><th>Sold $</th><th>Miles</th><th>Date</th><th>Source</th><th>Link</th></tr></thead>
                <tbody>
                  {soldRows.map((r, i)=> (
                    <tr key={i}>
                      <td>{r.photo ? <img src={r.photo} alt="Sold listing" width={100} loading="lazy" /> : '—'}</td>
                      <td>{r.title}</td>
                      <td>{typeof r.sold_price==='number' ? `$${r.sold_price.toLocaleString()}` : '—'}</td>
                      <td>{r.miles ?? '—'}</td>
                      <td>{r.date ?? '—'}</td>
                      <td>{r.source ?? '—'}</td>
                      <td>{r.link ? <a href={r.link} target="_blank" rel="noopener noreferrer">Open</a> : '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : <div className="notice">No sold listings yet. Tap Get Comps.</div>}
          </div>
        )}

        {tab==='bat' && (
          <div>
            {batRows?.length>0 ? (
              <table className="table">
                <thead><tr><th>Photo</th><th>Title</th><th>Sold $</th><th>Date</th><th>Link</th></tr></thead>
                <tbody>
                  {batRows.map((r, i)=> (
                    <tr key={i}>
                      <td>{r.photo ? <img src={r.photo} alt="BaT" width={100} loading="lazy" /> : '—'}</td>
                      <td>{r.title}</td>
                      <td>{typeof r.sold_price==='number' ? `$${r.sold_price.toLocaleString()}` : '—'}</td>
                      <td>{r.date ?? '—'}</td>
                      <td>{r.link ? <a href={r.link} target="_blank" rel="noopener noreferrer">Open</a> : '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : <div className="notice">No BaT results yet. Tap Get Comps.</div>}
          </div>
        )}
      </div>

      <div className="card">
        <h2>Pricing Brief (ChatGPT)</h2>
        <button onClick={handleBrief}>Generate Brief</button>
        {brief && <div style={{marginTop:10}}><textarea readOnly value={brief}/></div>}
        {!brief && <div className="notice" style={{marginTop:10}}>Add OPENAI_API_KEY in Vercel to enable.</div>}
      </div>

      <footer>Auto Comps — ChatGPT • Photos + Links enabled • Add API keys in Vercel</footer>
    </div>
  )
}
