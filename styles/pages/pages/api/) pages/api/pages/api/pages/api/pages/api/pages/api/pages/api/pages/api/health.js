export default async function handler(req, res){
  const env = {
    MARKETCHECK_API_KEY: !!process.env.MARKETCHECK_API_KEY,
    EBAY_CLIENT_ID: !!process.env.EBAY_CLIENT_ID,
    EBAY_CLIENT_SECRET: !!process.env.EBAY_CLIENT_SECRET,
    EBAY_ENABLE_MI: process.env.EBAY_ENABLE_MI || '0',
    OPENAI_API_KEY: !!process.env.OPENAI_API_KEY,
    BAT_ENABLE: process.env.BAT_ENABLE || '0'
  };
  res.status(200).json({ ok:true, env });
}
