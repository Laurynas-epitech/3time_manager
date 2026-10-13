// Fetch bounded pages sequentially. Never return a silently incomplete list.
export async function collectPages(fetchPage, { reversePages = false, maxPages = 2000 } = {}) {
  const limit = 50;
  const pages = [];
  const seen = new Set();
  for (let pageIndex = 0; pageIndex < maxPages; pageIndex++) {
    const page = await fetchPage({ limit, offset: pageIndex * limit });
    if (!Array.isArray(page)) throw new Error('Invalid list response. Please reload.');
    const fresh = page.filter(row => {
      if (row.id == null) throw new Error('Invalid record in list response.');
      if (seen.has(row.id)) return false;
      seen.add(row.id);
      return true;
    });
    if (page.length && !fresh.length) throw new Error('List changed while loading. Please reload.');
    pages.push(fresh);
    if (page.length < limit) return (reversePages ? pages.reverse() : pages).flat();
  }
  throw new Error('This list is too large to download safely. Narrow the requested period.');
}
