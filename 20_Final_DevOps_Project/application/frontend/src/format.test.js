import test from 'node:test';
import assert from 'node:assert/strict';
import { budgetPercent, currentMonth, formatMoney } from './format.js';

test('currentMonth pads the month', () => {
  assert.equal(currentMonth(new Date(2026, 0, 15)), '2026-01');
});

test('budgetPercent is clamped to 0..100', () => {
  assert.equal(budgetPercent(2500, 10000), 25);
  assert.equal(budgetPercent(50000, 10000), 100);
  assert.equal(budgetPercent(10, 0), 0);
});

test('formatMoney renders rupees', () => {
  assert.match(formatMoney('1250.5'), /1,250\.5/);
});
