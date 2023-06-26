import React from 'react';
import { render } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';

import RequestList from '../RequestList';
import {
  mockedRequest,
  codeResponseWithHTML,
} from '~/components/RequestDetailModal/__mocked_data__/mockData';

describe('The RequestsList component', () => {
  test('it orders requests based on their index', () => {
    const requests = [codeResponseWithHTML, mockedRequest];

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <RequestList requests={requests} resultId="abc" updateRequest={() => {}} view="run" />
        </SnackbarProvider>
      </ThemeProvider>
    );

    const renderedRequests = document.querySelectorAll('tbody > tr');

    expect(renderedRequests.length).toEqual(requests.length);
    expect(renderedRequests[0]).toHaveTextContent(mockedRequest.url);
    expect(renderedRequests[1]).toHaveTextContent(codeResponseWithHTML.url);
  });
});
