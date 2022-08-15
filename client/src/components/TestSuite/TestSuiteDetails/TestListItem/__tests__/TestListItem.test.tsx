import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';

import TestListItem from '../TestListItem';
import { Test, TestInput, TestOutput } from '~/models/testSuiteModels';

describe('The TestListItem component', () => {
  test('it renders a table with the test description is markdown', () => {
    // If you indent this with four spaces as whitespace indent,
    // markdown will think this is <code>.  If javascript had
    // heredocs then it might be able to strip whitespace.  So,
    // just add newlines to the string.
    const markDownTable = `| Head1 | Head2 |\n| --- | --- |\n| Row1 | Row2 |`;

    const outputs: TestOutput[] = [{ name: 'One', value: 'one' }];
    const inputs: TestInput[] = [{ name: 'two', value: 'two' }];
    const test: Test = {
      id: 'test_id',
      title: 'Test Title',
      inputs: inputs,
      short_id: 'short_id',
      outputs: outputs,
      user_runnable: false,
      description: markDownTable,
    };

    render(
      <ThemeProvider>
        <TestListItem test={test} testRunInProgress={false} view="run" />
      </ThemeProvider>
    );

    const accordion = screen.getByTitle('test_id-summary');
    fireEvent.click(accordion);

    const aboutTab = screen.getByRole('tab', { name: 'About' });
    fireEvent.click(aboutTab);

    // a table is rendered with markdown
    expect(screen.getByText('Head1').closest('thead')).toBeInTheDocument();
    expect(screen.getByText('Row1').closest('tbody')).toBeInTheDocument();
  });
});
