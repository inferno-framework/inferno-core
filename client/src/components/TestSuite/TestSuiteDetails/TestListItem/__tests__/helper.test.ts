import type { Message } from '../../../../../models/testSuiteModels';
import { sortByMessageType, countMessageTypes } from '../helper';

describe('TestListItem helpers', () => {
  const messages = [
    { message: 'Message One', type: 'info' },
    { message: 'Message Two', type: 'info' },
    { message: 'Message Three', type: 'warning' },
    { message: 'Message Four', type: 'error' },
    { message: 'Message Five', type: 'error' },
  ] as Message[];

  it('sorts messages by type', () => {
    const expected = [
      { message: 'Message Four', type: 'error' },
      { message: 'Message Five', type: 'error' },
      { message: 'Message Three', type: 'warning' },
      { message: 'Message One', type: 'info' },
      { message: 'Message Two', type: 'info' },
    ];

    expect(sortByMessageType(messages)).toStrictEqual(expected);
  });

  it('groups messages into count categories for the icon display', () => {
    const expected = { errors: 2, warnings: 1, infos: 2 };
    expect(countMessageTypes(messages)).toEqual(expected);
  });
});
