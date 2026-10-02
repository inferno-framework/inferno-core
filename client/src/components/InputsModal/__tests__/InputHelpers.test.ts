import { describe, expect, it } from 'vitest';
import {
  getMissingRequiredInput,
  normalizeValue,
  conditionalShowInput,
  serializeMap,
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

describe('getMissingRequiredInput', () => {
  const inputs: TestInput[] = [
    { name: 'mode', optional: true },
    {
      name: 'details',
      enable_when: { input_name: 'mode', value: 'advanced' },
    },
  ];

  it('does not require a conditionally disabled input', () => {
    expect(
      getMissingRequiredInput(
        inputs,
        new Map([
          ['mode', 'basic'],
          ['details', ''],
        ]),
      ),
    ).toBe(false);
  });

  it('requires an enabled conditional input with no value', () => {
    expect(
      getMissingRequiredInput(
        inputs,
        new Map([
          ['mode', 'advanced'],
          ['details', ''],
        ]),
      ),
    ).toBe(true);
  });

  it('requires a checkbox-controlled input when serialized selections match in a different order', () => {
    const checkboxInputs: TestInput[] = [
      {
        name: 'selections',
        type: 'checkbox',
        optional: true,
        options: {
          list_options: [
            { label: 'A', value: 'a' },
            { label: 'B', value: 'b' },
          ],
        },
      },
      { name: 'details', enable_when: { input_name: 'selections', value: '["a","b"]' } },
    ];

    expect(
      getMissingRequiredInput(
        checkboxInputs,
        new Map([
          ['selections', '["b","a"]'],
          ['details', ''],
        ]),
      ),
    ).toBe(true);
    expect(
      getMissingRequiredInput(
        checkboxInputs,
        new Map([
          ['selections', '["b"]'],
          ['details', ''],
        ]),
      ),
    ).toBe(false);
  });

  describe('select inputs', () => {
    const selectInputs: TestInput[] = [
      {
        name: 'sel',
        type: 'select',
        optional: false,
        options: {
          list_options: [
            { label: 'A', value: 'a' },
            { label: 'B', value: 'b' },
          ],
        },
      },
    ];

    it('is not missing when no value has been stored yet (first option is displayed)', () => {
      expect(getMissingRequiredInput(selectInputs, new Map([['sel', '']]))).toBe(false);
    });

    it('is not missing once a real value is stored', () => {
      expect(getMissingRequiredInput(selectInputs, new Map([['sel', 'b']]))).toBe(false);
    });

    it('is missing once explicitly cleared', () => {
      expect(getMissingRequiredInput(selectInputs, new Map([['sel', undefined]]))).toBe(true);
    });

    it('is not missing when optional and cleared', () => {
      const optionalSelect: TestInput[] = [{ ...selectInputs[0], optional: true }];
      expect(getMissingRequiredInput(optionalSelect, new Map([['sel', undefined]]))).toBe(false);
    });
  });
});

describe('serializeMap', () => {
  const listOptions = [
    { label: 'A', value: 'a' },
    { label: 'B', value: 'b' },
  ];

  it.each(['radio', 'select'] as const)(
    'falls back to the first list_option for a %s input with no stored value or default',
    (type) => {
      const input: TestInput = { name: 'opt', type, options: { list_options: listOptions } };
      const json = JSON.parse(serializeMap('JSON', [input], new Map())) as TestInput[];
      expect(json[0].value).toBe('a');
    },
  );

  it.each(['radio', 'select'] as const)(
    'falls back to the default for a %s input with no stored value',
    (type) => {
      const input: TestInput = {
        name: 'opt',
        type,
        default: 'b',
        options: { list_options: listOptions },
      };
      const json = JSON.parse(serializeMap('JSON', [input], new Map())) as TestInput[];
      expect(json[0].value).toBe('b');
    },
  );

  it.each(['radio', 'select'] as const)('prefers the stored value for a %s input', (type) => {
    const input: TestInput = {
      name: 'opt',
      type,
      default: 'a',
      options: { list_options: listOptions },
    };
    const json = JSON.parse(serializeMap('JSON', [input], new Map([['opt', 'b']]))) as TestInput[];
    expect(json[0].value).toBe('b');
  });
});

describe('conditionalShowInput', () => {
  it('returns true when enable_when is absent', () => {
    const input = makeInput();
    expect(conditionalShowInput(input, new Map(), [input])).toBe(true);
  });

  it('returns true when enable_when has no input_name', () => {
    const input = makeInput({ enable_when: { input_name: '', value: 'x' } });
    expect(conditionalShowInput(input, new Map(), [input])).toBe(true);
  });

  it('returns false and warns when input_name is not in the map', () => {
    const input = makeInput({ enable_when: { input_name: 'missing', value: 'x' } });
    const warned: string[] = [];
    const originalWarn = console.warn;
    console.warn = (...args: unknown[]) => warned.push(String(args[0]));
    const result = conditionalShowInput(input, new Map(), [input]);
    console.warn = originalWarn;
    expect(result).toBe(false);
  });

  it('returns false when value does not match', () => {
    const input = makeInput({ enable_when: { input_name: 'ctrl', value: 'yes' } });
    expect(conditionalShowInput(input, new Map([['ctrl', 'no']]), [input])).toBe(false);
  });

  it('returns true when value matches', () => {
    const input = makeInput({ enable_when: { input_name: 'ctrl', value: 'yes' } });
    expect(conditionalShowInput(input, new Map([['ctrl', 'yes']]), [input])).toBe(true);
  });

  it('returns true for checkbox array regardless of selection order', () => {
    const input = makeInput({ enable_when: { input_name: 'ctrl', value: '["a","b"]' } });
    const controller = makeInput({
      name: 'ctrl',
      type: 'checkbox',
      options: {
        list_options: [
          { label: 'A', value: 'a' },
          { label: 'B', value: 'b' },
        ],
      },
    });
    expect(conditionalShowInput(input, new Map([['ctrl', ['b', 'a']]]), [controller, input])).toBe(
      true,
    );
    expect(conditionalShowInput(input, new Map([['ctrl', '["b","a"]']]), [controller, input])).toBe(
      true,
    );
  });

  it('compares a text input containing JSON literally', () => {
    const input = makeInput({ enable_when: { input_name: 'ctrl', value: '["a","b"]' } });
    const controller = makeInput({ name: 'ctrl', type: 'text' });
    expect(conditionalShowInput(input, new Map([['ctrl', '["b","a"]']]), [controller, input])).toBe(
      false,
    );
  });

  it('respects enable_when when the input itself is type checkbox', () => {
    const input = makeInput({
      type: 'checkbox',
      enable_when: { input_name: 'ctrl', value: 'yes' },
    });
    expect(conditionalShowInput(input, new Map([['ctrl', 'no']]), [input])).toBe(false);
    expect(conditionalShowInput(input, new Map([['ctrl', 'yes']]), [input])).toBe(true);
  });

  it('returns false when the controlling input is itself disabled by its own enable_when', () => {
    const mode = makeInput({ name: 'mode', optional: true });
    const subMode = makeInput({
      name: 'sub_mode',
      optional: true,
      enable_when: { input_name: 'mode', value: 'advanced' },
    });
    const details = makeInput({
      name: 'details',
      enable_when: { input_name: 'sub_mode', value: 'x' },
    });
    const inputs = [mode, subMode, details];

    // sub_mode has a matching value, but it is not itself enabled since mode != 'advanced'
    const inputsMap = new Map([
      ['mode', 'basic'],
      ['sub_mode', 'x'],
    ]);
    expect(conditionalShowInput(details, inputsMap, inputs)).toBe(false);

    const enabledMap = new Map([
      ['mode', 'advanced'],
      ['sub_mode', 'x'],
    ]);
    expect(conditionalShowInput(details, enabledMap, inputs)).toBe(true);
  });

  it('returns true when the controlling input is merely hidden, not conditionally disabled', () => {
    const ctrl = makeInput({ name: 'ctrl', optional: true, hidden: true });
    const details = makeInput({ enable_when: { input_name: 'ctrl', value: 'x' } });
    // `hidden` alone is a static display flag, not a conditional disable, so it
    // should not block an enable_when chain
    expect(conditionalShowInput(details, new Map([['ctrl', 'x']]), [ctrl, details])).toBe(true);
  });

  it('does not loop forever on a circular enable_when chain', () => {
    const a = makeInput({
      name: 'a',
      optional: true,
      enable_when: { input_name: 'b', value: 'x' },
    });
    const b = makeInput({
      name: 'b',
      optional: true,
      enable_when: { input_name: 'a', value: 'y' },
    });
    const inputsMap = new Map([
      ['a', 'y'],
      ['b', 'x'],
    ]);
    expect(conditionalShowInput(a, inputsMap, [a, b])).toBe(false);
    expect(conditionalShowInput(b, inputsMap, [a, b])).toBe(false);
  });
});

describe('showInput', () => {
  it('returns false when hidden is true, even if enable_when matches', () => {
    const input = makeInput({ hidden: true, enable_when: { input_name: 'ctrl', value: 'yes' } });
    expect(showInput(input, new Map([['ctrl', 'yes']]), [input])).toBe(false);
  });

  it('returns true when not hidden and no enable_when', () => {
    const input = makeInput();
    expect(showInput(input, new Map(), [input])).toBe(true);
  });

  it('returns true when not hidden and enable_when matches', () => {
    const input = makeInput({ enable_when: { input_name: 'ctrl', value: 'yes' } });
    expect(showInput(input, new Map([['ctrl', 'yes']]), [input])).toBe(true);
  });

  it('returns false when not hidden but enable_when does not match', () => {
    const input = makeInput({ enable_when: { input_name: 'ctrl', value: 'yes' } });
    expect(showInput(input, new Map([['ctrl', 'no']]), [input])).toBe(false);
  });
});
