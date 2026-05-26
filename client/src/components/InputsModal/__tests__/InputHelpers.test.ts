import { describe, expect, it } from 'vitest';
import {
  normalizeValue,
  conditionalShowInput,
  showInput,
} from '~/components/InputsModal/InputHelpers';
import { TestInput } from '~/models/testSuiteModels';

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

  it('JSON-stringifies arrays in sorted order', () => {
    expect(normalizeValue([])).toBe('[]');
    expect(normalizeValue(['a', 'b', 'c'])).toBe('["a","b","c"]');
    expect(normalizeValue(['c', 'b', 'a'])).toBe('["a","b","c"]');
  });

  it('returns empty string for function (default case)', () => {
    expect(normalizeValue(() => {})).toBe('');
  });
});

const makeInput = (overrides: Partial<TestInput> = {}): TestInput => ({
  name: 'dep',
  type: 'text',
  ...overrides,
});

describe('conditionalShowInput', () => {
  it('returns true when enable_when is absent', () => {
    expect(conditionalShowInput(makeInput(), new Map())).toBe(true);
  });

  it('returns true when enable_when has no input_name', () => {
    const input = makeInput({ enable_when: { input_name: '', value: 'x' } });
    expect(conditionalShowInput(input, new Map())).toBe(true);
  });

  it('returns false and warns when input_name is not in the map', () => {
    const input = makeInput({ enable_when: { input_name: 'missing', value: 'x' } });
    const warned: string[] = [];
    const originalWarn = console.warn;
    console.warn = (...args: unknown[]) => warned.push(String(args[0]));
    const result = conditionalShowInput(input, new Map());
    console.warn = originalWarn;
    expect(result).toBe(false);
  });

  it('returns false when value does not match', () => {
    const input = makeInput({ enable_when: { input_name: 'ctrl', value: 'yes' } });
    expect(conditionalShowInput(input, new Map([['ctrl', 'no']]))).toBe(false);
  });

  it('returns true when value matches', () => {
    const input = makeInput({ enable_when: { input_name: 'ctrl', value: 'yes' } });
    expect(conditionalShowInput(input, new Map([['ctrl', 'yes']]))).toBe(true);
  });

  it('returns true for checkbox array regardless of selection order', () => {
    const input = makeInput({ enable_when: { input_name: 'ctrl', value: '["a","b"]' } });
    expect(conditionalShowInput(input, new Map([['ctrl', ['b', 'a']]]))).toBe(true);
  });
});

describe('showInput', () => {
  it('returns false when hidden is true, even if enable_when matches', () => {
    const input = makeInput({ hidden: true, enable_when: { input_name: 'ctrl', value: 'yes' } });
    expect(showInput(input, new Map([['ctrl', 'yes']]))).toBe(false);
  });

  it('returns true when not hidden and no enable_when', () => {
    expect(showInput(makeInput(), new Map())).toBe(true);
  });

  it('returns true when not hidden and enable_when matches', () => {
    const input = makeInput({ enable_when: { input_name: 'ctrl', value: 'yes' } });
    expect(showInput(input, new Map([['ctrl', 'yes']]))).toBe(true);
  });

  it('returns false when not hidden but enable_when does not match', () => {
    const input = makeInput({ enable_when: { input_name: 'ctrl', value: 'yes' } });
    expect(showInput(input, new Map([['ctrl', 'no']]))).toBe(false);
  });
});
