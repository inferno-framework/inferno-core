import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';

import TestGroupListItem from '../TestGroupListItem';
import { TestGroup } from '~/models/testSuiteModels';

describe('The expandable TestGroupListItem component', () => {
  test('it renders an accordion for expandable tests and test groups', () => {
    const testGroup: TestGroup = {
      id: 'test_group_id',
      title: 'Test Group',
      inputs: [],
      short_id: 'test_group_short_id',
      test_groups: [],
      outputs: [],
      tests: [],
      expanded: true,
    };
    render(
      <ThemeProvider>
        <TestGroupListItem testGroup={testGroup} view="run" />
      </ThemeProvider>
    );

    const accordion = screen.getByTestId('test_group_id-summary');
    fireEvent.click(accordion);

    expect(screen.getByText('Test Group')).toBeInTheDocument();
    expect(screen.getByTestId('test_group_id-detail')).toBeInTheDocument();
  });
});

describe('The navigable TestGroupListItem component', () => {
  test('it renders a container for linked tests and test groups', () => {
    const testGroup: TestGroup = {
      id: 'test_group_id',
      title: 'Test Group',
      inputs: [],
      short_id: 'test_group_short_id',
      test_groups: [],
      outputs: [],
      tests: [],
    };
    render(
      <ThemeProvider>
        <TestGroupListItem testGroup={testGroup} view="run" />
      </ThemeProvider>
    );

    expect(screen.getByText('Test Group').closest('a'));
  });
});
