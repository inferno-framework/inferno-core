import React from 'react';
import { RouterProvider, createMemoryRouter } from 'react-router-dom';
import { render, waitFor } from '@testing-library/react';
import { testSuites } from '~/components/App/__mocked_data__/mockData';
import Page from '../Page';

describe('The Page Component', () => {
  test('sets page title on render', async () => {
    const pageTitle = 'Inferno Test Suites';
    const routes = [
      {
        path: '/',
        element: (
          <Page title={pageTitle}>
            <div>child component</div>
          </Page>
        ),
        loader: () => testSuites,
      },
    ];

    const router = createMemoryRouter(routes, { initialEntries: ['/'] });
    render(<RouterProvider router={router} />);

    await waitFor(() => expect(document.title).toEqual(pageTitle));
  });
});
