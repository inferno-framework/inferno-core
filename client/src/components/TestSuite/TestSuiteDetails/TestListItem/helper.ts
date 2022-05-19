import type { Message } from '../../../../models/testSuiteModels';

export type MessageCounts = {
  errors: number;
  warnings: number;
  infos: number;
};

export const sortByMessageType = (messages: Message[]): Message[] => {
  const sortOrder = ['error', 'warning', 'info'];

  const sorted = messages.sort((a, b) => {
    return sortOrder.indexOf(a.type) - sortOrder.indexOf(b.type);
  });
  return sorted;
};

const countType = (messages: Message[], type: string): number => {
  return messages.filter((message) => message.type === type).length;
};

export const countMessageTypes = (messages: Message[]): MessageCounts => {
  const error_count = countType(messages, 'error');
  const warning_count = countType(messages, 'warning');
  const info_count = countType(messages, 'info');

  return {
    errors: error_count,
    warnings: warning_count,
    infos: info_count,
  };
};
