// Pure helpers, kept separate from React so `node --test` can cover them without a browser.
export function formatMoney(value, currency = 'INR') {
  return new Intl.NumberFormat('en-IN', { style: 'currency', currency, maximumFractionDigits: 2 }).format(Number(value || 0));
}

export function currentMonth(now = new Date()) {
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

export function budgetPercent(total, budget) {
  if (!budget || Number(budget) <= 0) return 0;
  return Math.min(100, Math.round((Number(total) / Number(budget)) * 100));
}
