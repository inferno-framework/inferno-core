import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';

import TestListItem from '../TestListItem';
import { Message, Request, Result, Test, TestInput, TestOutput } from '~/models/testSuiteModels';

describe('The TestListItem component', () => {
  test('it renders a table with the test description as markdown', () => {
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

    const accordion = screen.getByTestId('test_id-summary');
    fireEvent.click(accordion);

    const aboutTab = screen.getByRole('tab', { name: 'About' });
    fireEvent.click(aboutTab);

    expect(screen.getByText('Head1').closest('thead')).toBeInTheDocument();
    expect(screen.getByText('Row1').closest('tbody')).toBeInTheDocument();
  });

  describe('Accordion tab navigation', () => {
    const outputs: TestOutput[] = [{ name: 'One', value: 'one' }];
    const inputs: TestInput[] = [{ name: 'two', value: 'two' }];

    it('navigates to the About tab when no other content', () => {
      const result: Result = {
        id: 'id',
        result: 'result',
        test_run_id: 'test_run_id',
        test_session_id: 'test_session_id',
        updated_at: 'updated_at',
        outputs: [],
      };

      const test: Test = {
        id: 'test_id',
        title: 'Test Title',
        inputs: inputs,
        short_id: 'short_id',
        outputs: outputs,
        user_runnable: false,
        description: `Some Description`,
        result: result,
      };

      render(
        <ThemeProvider>
          <TestListItem test={test} testRunInProgress={false} view="run" />
        </ThemeProvider>
      );

      const target = screen.getByTestId('test_id-summary');
      fireEvent.click(target);

      expect(screen.getByText('Some Description')).toBeInTheDocument();
    });

    it('navigates to the requests tab', () => {
      const request: Request = {
        direction: 'outgoing',
        id: 'id',
        index: 0,
        status: 422,
        timestamp: 'timestamp',
        url: 'http://url',
        verb: 'get',
        result_id: 'result_id',
        response_body: 'response_body',
      };

      const message: Message = {
        message: 'Message One',
        type: 'warning',
      };

      const result: Result = {
        id: 'result_id',
        result: 'result',
        test_run_id: 'test_run_id',
        test_session_id: 'test_session_id',
        updated_at: 'updated_at',
        outputs: [],
        requests: [request],
        messages: [message],
      };

      const test: Test = {
        id: 'test_id',
        title: 'Test Title',
        inputs: inputs,
        short_id: 'short_id',
        outputs: outputs,
        user_runnable: false,
        description: `No Description`,
        result: result,
      };

      render(
        <ThemeProvider>
          <TestListItem test={test} testRunInProgress={false} view="run" />
        </ThemeProvider>
      );

      const target = screen.getByLabelText('View 1 request(s)');
      fireEvent.click(target);

      const requestsTab = screen.getByText('Requests');
      expect(requestsTab.getAttribute('tabindex')).toBe('0');
    });

    it('navigates to the messages tab', () => {
      const request: Request = {
        direction: 'outgoing',
        id: 'id',
        index: 0,
        status: 422,
        timestamp: 'timestamp',
        url: 'http://url',
        verb: 'get',
        result_id: 'result_id',
        response_body: 'response_body',
      };

      const message: Message = {
        message: 'Message One',
        type: 'warning',
      };

      const result: Result = {
        id: 'result_id',
        result: 'result',
        test_run_id: 'test_run_id',
        test_session_id: 'test_session_id',
        updated_at: 'updated_at',
        outputs: [],
        requests: [request],
        messages: [message],
      };

      const test: Test = {
        id: 'test_id',
        title: 'Test Title',
        inputs: inputs,
        short_id: 'short_id',
        outputs: outputs,
        user_runnable: false,
        description: `No Description`,
        result: result,
      };

      render(
        <ThemeProvider>
          <TestListItem test={test} testRunInProgress={false} view="run" />
        </ThemeProvider>
      );

      const target = screen.getByLabelText('View 1 message(s)');
      fireEvent.click(target);

      const requestsTab = screen.getByText('Messages');
      expect(requestsTab.getAttribute('tabindex')).toBe('0');
    });
  });
});
