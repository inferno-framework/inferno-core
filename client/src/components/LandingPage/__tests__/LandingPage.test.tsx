import React from 'react';
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import LandingPage from '../LandingPage';
import { getTestSuites, postTestSessions } from 'api/infernoApiService';
import { mocked } from 'ts-jest/utils';
import {
  mockedPostTestSuiteResponse,
  mockedTestSuitesReturnValue,
} from '../__mocked_data__/mockData';

const presets = [
  {
    name: 'None',
    fhirServer: '',
    testSet: '',
  },
  {
    name: 'SMART Bulk Tests',
    fhirServer:
      'https://bulk-data.smarthealthit.org/eyJlcnIiOiIiLCJwYWdlIjoxMDAwLCJkdXIiOjEwLCJ0bHQiOjE1LCJtIjoxLCJzdHUiOjR9/fhir',
    testSet: 'Bulk data tests (via BDT)',
  },
  {
    name: 'US Core v3.1.1 with Inferno Reference Server',
    fhirServer: 'https://inferno.healthit.gov/reference-server/r4',
    testSet: 'US Core v3.1.1',
  },
];

jest.mock('api/infernoApiService');
const mockedGetTestSuites = mocked(getTestSuites, true);
const mockedPostTestSessions = mocked(postTestSessions, true);
// need to mock resolved value in each test for some reason

test('renders landing page', () => {
  mockedGetTestSuites.mockResolvedValue(mockedTestSuitesReturnValue);
  render(<LandingPage presets={presets} />);
  const titleText = screen.getByText('FHIR Testing with Inferno');
  expect(titleText).toBeVisible();
});

test('test suites are displayed in the select options when clicked', async () => {
  mockedGetTestSuites.mockResolvedValue(mockedTestSuitesReturnValue);
  render(<LandingPage presets={presets} />);
  expect(mockedGetTestSuites).toHaveBeenCalled();

  // options are not shown at first
  const firstOption = screen.queryByText(mockedTestSuitesReturnValue[0].title);
  expect(firstOption).toBeNull();

  const trigger = within(screen.getByTestId('testSuite-select')).getByRole('button');

  // need to wait for menu options to be populated
  await waitFor(() => {
    fireEvent.mouseDown(trigger);
    mockedTestSuitesReturnValue.forEach((testSuite) => {
      const option = screen.getByText(testSuite.title);
      expect(option).toBeVisible();
    });
  });
});

test('test suite is fetched and launched', async () => {
  mockedGetTestSuites.mockResolvedValue(mockedTestSuitesReturnValue);
  mockedPostTestSessions.mockResolvedValue(mockedPostTestSuiteResponse);
  render(<LandingPage presets={presets} />);
  const trigger = within(screen.getByTestId('testSuite-select')).getByRole('button');
  fireEvent.mouseDown(trigger);
  await waitFor(() => {
    mockedTestSuitesReturnValue.forEach((testSuite) => {
      const option = screen.getByText(testSuite.title);
      expect(option).toBeVisible();
    });
  });
  const demonstrationSuite = screen.getByText('Demonstration Suite');
  fireEvent.click(demonstrationSuite);
  await waitFor(() => {
    const otherOption = screen.queryByText('Infrastructure Test');
    expect(otherOption).toBeNull();
  });
  const goButton = screen.getByTestId('go-button');
  fireEvent.click(goButton);
  await waitFor(() => {
    expect(mockedPostTestSessions).toHaveBeenCalled();
  });
});
