import React from 'react';
import { render, screen } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';
import { Request } from 'models/testSuiteModels';
import RequestDetailModal from '../RequestDetailModal';

test('renders Request List Detail Modal', () => {
  render(
    <ThemeProvider>
      <RequestDetailModal
        request={
          {
            direction: 'direction',
            id: 'id',
            status: 1,
            timestamp: 'timestamp',
            url: 'url',
            verb: 'verb',
          } as Request
        }
        modalVisible={true}
        hideModal={() => undefined}
        usedRequest={true}
      />
    </ThemeProvider>
  );

  const modalElement = screen.getByTestId('requestDetailModal');
  expect(modalElement).toBeInTheDocument();
});
