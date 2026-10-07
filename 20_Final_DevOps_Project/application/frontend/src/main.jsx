import React, { useCallback, useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { budgetPercent, currentMonth, formatMoney } from './format.js';
import './styles.css';

const CATEGORIES = ['FOOD', 'TRANSPORT', 'RENT', 'UTILITIES', 'SHOPPING', 'ENTERTAINMENT', 'HEALTH', 'OTHER'];
const METHODS = ['UPI', 'CARD', 'CASH', 'NETBANKING'];

async function api(path, options) {
  const res = await fetch(`/api${path}`, options);
  if (!res.ok) throw new Error(`${options?.method || 'GET'} /api${path} -> ${res.status}`);
  return res.status === 204 ? null : res.json();
}

function Kpi({ label, value, hint }) {
  return (
    <div className="kpi">
      <span>{label}</span>
      <strong>{value}</strong>
      {hint && <small>{hint}</small>}
    </div>
  );
}

function AddExpense({ onAdded }) {
  const [busy, setBusy] = useState(false);
  const submit = async (e) => {
    e.preventDefault();
    const form = e.currentTarget;
    const data = Object.fromEntries(new FormData(form));
    setBusy(true);
    try {
      await api('/expenses', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) });
      form.reset();
      onAdded();
    } finally {
      setBusy(false);
    }
  };
  return (
    <form className="panel add" onSubmit={submit}>
      <h2>Add expense</h2>
      <input name="title" placeholder="What was it?" required maxLength={200} />
      <input name="amount" type="number" step="0.01" min="0.01" placeholder="Amount" required />
      <div className="row">
        <select name="category" defaultValue="FOOD">{CATEGORIES.map((c) => <option key={c}>{c}</option>)}</select>
        <select name="payment_method" defaultValue="UPI">{METHODS.map((m) => <option key={m}>{m}</option>)}</select>
      </div>
      <input name="spent_on" type="date" defaultValue={new Date().toISOString().slice(0, 10)} required />
      <button className="primary" disabled={busy}>{busy ? 'Saving…' : 'Add expense'}</button>
    </form>
  );
}

function App() {
  const [month, setMonth] = useState(currentMonth());
  const [category, setCategory] = useState('');
  const [config, setConfig] = useState({ currency: 'INR', environment: '' });
  const [summary, setSummary] = useState(null);
  const [expenses, setExpenses] = useState([]);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    try {
      setError('');
      const q = `?month=${month}${category ? `&category=${category}` : ''}`;
      const [cfg, sum, list] = await Promise.all([api('/config'), api(`/expenses/summary?month=${month}`), api(`/expenses${q}`)]);
      setConfig(cfg);
      setSummary(sum);
      setExpenses(list);
    } catch (e) {
      setError(e.message);
    }
  }, [month, category]);

  useEffect(() => { load(); }, [load]);

  const remove = async (id) => { await api(`/expenses/${id}`, { method: 'DELETE' }); load(); };
  const cur = config.currency;
  const used = summary ? budgetPercent(summary.total, summary.budget) : 0;
  const top = summary?.by_category?.[0];

  return (
    <div className="page">
      <header>
        <div>
          <p className="eyebrow">SPENDBOARD {config.environment && <span className="env">{config.environment}</span>}</p>
          <h1>Where did the money go?</h1>
        </div>
        <input type="month" value={month} onChange={(e) => setMonth(e.target.value)} aria-label="Month" />
      </header>

      {error && <div className="alert">Backend unavailable: {error}</div>}

      <section className="kpis">
        <Kpi label="Spent this month" value={formatMoney(summary?.total, cur)} hint={`${summary?.count ?? 0} transactions`} />
        <Kpi label="Budget left" value={formatMoney(summary?.budget_remaining, cur)} hint={`of ${formatMoney(summary?.budget, cur)}`} />
        <Kpi label="Top category" value={top ? top.category : '—'} hint={top ? formatMoney(top.total, cur) : ''} />
      </section>

      <div className={`meter ${used >= 90 ? 'hot' : ''}`}><div style={{ width: `${used}%` }} /><span>{used}% of budget used</span></div>

      <section className="grid">
        <div className="panel">
          <div className="panel-head">
            <h2>Expenses</h2>
            <select value={category} onChange={(e) => setCategory(e.target.value)} aria-label="Category filter">
              <option value="">All categories</option>
              {CATEGORIES.map((c) => <option key={c}>{c}</option>)}
            </select>
          </div>
          <table>
            <thead><tr><th>Date</th><th>Title</th><th>Category</th><th>Paid via</th><th className="num">Amount</th><th /></tr></thead>
            <tbody>
              {expenses.map((e) => (
                <tr key={e.id}>
                  <td>{e.spent_on}</td><td>{e.title}</td>
                  <td><span className={`tag ${e.category.toLowerCase()}`}>{e.category}</span></td>
                  <td>{e.payment_method}</td>
                  <td className="num">{formatMoney(e.amount, cur)}</td>
                  <td><button className="ghost" onClick={() => remove(e.id)} aria-label={`Delete ${e.title}`}>✕</button></td>
                </tr>
              ))}
              {!expenses.length && <tr><td colSpan={6} className="empty">No expenses for this month yet.</td></tr>}
            </tbody>
          </table>
        </div>
        <div className="side">
          <AddExpense onAdded={load} />
          <div className="panel">
            <h2>By category</h2>
            {summary?.by_category?.map((c) => (
              <div className="bar" key={c.category}>
                <span>{c.category}</span>
                <div><i style={{ width: `${budgetPercent(c.total, summary.total)}%` }} /></div>
                <b>{formatMoney(c.total, cur)}</b>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}

createRoot(document.getElementById('root')).render(<App />);
