import { describe, expect, it } from 'vitest';
import { normalizeValue } from '~/components/InputsModal/InputHelpers';

describe('normalizeValue', () => {
  it('returns empty string for null', () => {
    expect(normalizeValue(null)).toBe('');
  });

  it('returns empty string for undefined', () => {
    expect(normalizeValue(undefined)).toBe('');
  });

  it('returns string unchanged', () => {
    expect(normalizeValue('')).toBe('');
    expect(normalizeValue('hello')).toBe('hello');
    expect(normalizeValue('4.0')).toBe('4.0');
  });

  it('converts number to string', () => {
    expect(normalizeValue(0)).toBe('0');
    expect(normalizeValue(42)).toBe('42');
    expect(normalizeValue(-1)).toBe('-1');
    expect(normalizeValue(3.14)).toBe('3.14');
  });

  it('converts boolean to string', () => {
    expect(normalizeValue(true)).toBe('true');
    expect(normalizeValue(false)).toBe('false');
  });

  it('converts bigint to string', () => {
    expect(normalizeValue(BigInt(0))).toBe('0');
    expect(normalizeValue(BigInt(9007199254740991))).toBe('9007199254740991');
  });

  it('converts symbol to string', () => {
    const sym = Symbol('test');
    expect(normalizeValue(sym)).toBe(sym.toString());
  });

  it('JSON-stringifies plain objects', () => {
    expect(normalizeValue({})).toBe('{}');
    expect(normalizeValue({ a: 1, b: 'x' })).toBe('{"a":1,"b":"x"}');
  });

  it('JSON-stringifies arrays', () => {
    expect(normalizeValue([])).toBe('[]');
    expect(normalizeValue([1, 'a', true])).toBe('[1,"a",true]');
  });

  it('returns empty string for function (default case)', () => {
    expect(normalizeValue(() => {})).toBe('');
  });
});
