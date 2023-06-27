import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { render, screen } from '@testing-library/react';
import { describe, vi } from 'vitest';
import { SnackbarProvider } from 'notistack';
import * as testSessionApi from '~/api/TestSessionApi';
import ThemeProvider from '~/components/ThemeProvider';
import LandingPage from '~/components/LandingPage/LandingPage';
import { mockedTestSuitesReturnValue } from '../__mocked_data__/mockData';
import { singleTestSuite, testSession } from '~/components/App/__mocked_data__/mockData';

describe('The Landing Page Component', () => {
  it('renders Inferno Landing Page', () => {
    const testSuites = mockedTestSuitesReturnValue;

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <LandingPage testSuites={testSuites} />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>
    );

    const headerElements = screen.getAllByRole('heading');
    expect(headerElements[0]).toHaveTextContent('FHIR Testing with Inferno');
  });

  it('Start Testing button should be disabled when test suite is not selected', () => {
    const testSuites = mockedTestSuitesReturnValue;

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <LandingPage testSuites={testSuites} />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>
    );

    const buttonElement = screen.getByTestId('go-button');
    expect(buttonElement).toBeDisabled();
  });

  it('sets the Test Session if there is a single Test Suite', () => {
    const postTestSessions = vi.spyOn(testSessionApi, 'postTestSessions');
    postTestSessions.mockResolvedValue(testSession);

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <LandingPage testSuites={singleTestSuite} />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>
    );
    expect(postTestSessions).toBeCalledTimes(1);
  });
});
