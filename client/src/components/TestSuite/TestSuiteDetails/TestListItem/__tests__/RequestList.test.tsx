import React, { act } from 'react';
import { describe, expect, test, vi } from 'vitest';
import userEvent from '@testing-library/user-event';
import { render, screen, waitFor } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';

import RequestList from '../RequestList';
import {
  mockedRequest,
  codeResponseWithHtml,
} from '~/components/RequestDetailModal/__mocked_data__/mockData';

describe('The RequestsList component', () => {
  test('it orders requests based on their index', async () => {
    const requests = [codeResponseWithHtml, mockedRequest];

    await act(() =>
      render(
        <ThemeProvider>
          <SnackbarProvider>
            <RequestList requests={requests} resultId="abc" updateRequest={() => {}} view="run" />
          </SnackbarProvider>
        </ThemeProvider>,
      ),
    );

    const renderedRequests = document.querySelectorAll('tbody > tr');

    expect(renderedRequests.length).toEqual(requests.length);
    expect(renderedRequests[0]).toHaveTextContent(mockedRequest.url);
    expect(renderedRequests[1]).toHaveTextContent(codeResponseWithHtml.url);
  });

  test('copies url when button is clicked', async () => {
    const requests = [codeResponseWithHtml, mockedRequest];
    // Keep a copy to restore original clipboard
    const originalClipboard = navigator.clipboard;
    const mockedWriteText = vi.fn();
    mockedWriteText.mockResolvedValue(true);

    Object.assign(navigator, {
      clipboard: {
        writeText: mockedWriteText,
      },
    });

    await act(() =>
      render(
        <ThemeProvider>
          <SnackbarProvider>
            <RequestList requests={requests} resultId="abc" updateRequest={() => {}} view="run" />
          </SnackbarProvider>
        </ThemeProvider>,
      ),
    );

    const buttons = screen.getAllByRole('button');
    const copyButton = buttons[0];
    await userEvent.click(copyButton);

    await waitFor(() => expect(mockedWriteText).toHaveBeenCalledTimes(1));

    // Restore the original clipboard
    Object.assign(navigator, {
      clipboard: originalClipboard,
    });
    vi.resetAllMocks();
  });

  test('shows details when button is clicked', async () => {
    const requests = [codeResponseWithHtml, mockedRequest];

    await act(() =>
      render(
        <ThemeProvider>
          <SnackbarProvider>
            <RequestList requests={requests} resultId="abc" updateRequest={() => {}} view="run" />
          </SnackbarProvider>
        </ThemeProvider>,
      ),
    );

    const buttons = screen.getAllByRole('button');
    const showDetailsButton = buttons[1];

    await userEvent.click(showDetailsButton);
    const modal = screen.getByRole('dialog');
    expect(modal).toBeInTheDocument();
  });
});
