// Temu order extractor — paste into the Chrome DevTools MCP `evaluate_script`
// while on the orders page (https://www.temu.com/<locale>/bgt_orders.html, logged in).
// Scrolls to lazy-load all orders, then returns de-duped products: {name, img}.
// The `img` is the clean catalogue photo (good as an inventory thumbnail), bumped
// to w/500 q/70. Save the result to a file via evaluate_script's filePath arg.
async () => {
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  let last = 0, stable = 0;
  for (let i = 0; i < 40 && stable < 3; i++) {           // scroll until height settles
    window.scrollTo(0, document.body.scrollHeight);
    await sleep(700);
    const h = document.body.scrollHeight;
    if (h === last) stable++; else { stable = 0; last = h; }
  }
  window.scrollTo(0, 0);
  const seen = new Map();
  for (const img of document.querySelectorAll('img[alt^="item picture"]')) {
    const name = (img.alt || '').replace(/^item picture\s*/, '').replace(/\s+/g, ' ').trim();
    const src = img.currentSrc || img.src || '';
    const m = src.match(/\/product\/[^?]*?([0-9a-f-]{16,})/i) || src.match(/\/([0-9a-f-]{20,})\.(?:jpe?g|png)/i);
    const key = m ? m[1] : name.slice(0, 40);
    const hi = src.replace(/w\/150/, 'w/500').replace(/q\/50/, 'q/70');
    if (!seen.has(key) || name.length > seen.get(key).name.length) seen.set(key, { name, img: hi });
  }
  return { count: seen.size, products: [...seen.values()] };
};
