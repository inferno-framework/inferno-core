import React from 'react';
import { render } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';

import RequestsList from '../RequestsList';
import {
  mockedRequest,
  codeResponseWithHTML,
} from '~/components/RequestDetailModal/__mocked_data__/mockData';

describe('The RequestsList component', () => {
  test('it orders requests based on their index', () => {
    const requests = [codeResponseWithHTML, mockedRequest];

    render(
      <ThemeProvider>
        <RequestsList requests={requests} resultId="abc" updateRequest={() => {}} />
      </ThemeProvider>
    );

    const renderedRequests = document.querySelectorAll('tbody > tr');

    expect(renderedRequests.length).toEqual(requests.length);
    expect(renderedRequests[0]).toHaveTextContent(mockedRequest.url);
    expect(renderedRequests[1]).toHaveTextContent(codeResponseWithHTML.url);
  });
});
