import React from 'react';
import { render, screen } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';
import RequestDetailModal from '../RequestDetailModal';
import { mockedRequest } from '../__mocked_data__/mockData';

const hideModalMock = jest.fn();

test('renders Request List Detail Modal', () => {
  render(
    <ThemeProvider>
      <RequestDetailModal
        request={mockedRequest}
        modalVisible={true}
        hideModal={hideModalMock}
        usedRequest={true}
      />
    </ThemeProvider>
  );

  const modalElement = screen.getByTestId('requestDetailModal');
  expect(modalElement).toBeInTheDocument();
});
