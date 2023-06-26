import React from 'react';
import { render } from '@testing-library/react';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';

import { TestInput, TestOutput } from '~/models/testSuiteModels';
import InputOutputList from '../InputOutputList';

describe('The InputOutputsList component', () => {
  test('it renders all inputs', () => {
    const inputs: TestInput[] = [
      { name: 'one', value: 1 },
      { name: 'two', value: 2 },
    ];

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputOutputList inputOutputs={inputs} noValuesMessage="No Inputs" headerName="Input" />
        </SnackbarProvider>
      </ThemeProvider>
    );

    const renderedMessages = document.querySelectorAll('tbody > tr');
    expect(renderedMessages.length).toEqual(inputs.length);
  });

  test('it renders all outputs', () => {
    const outputs: TestOutput[] = [
      { name: 'one', value: '1' },
      { name: 'two', value: '2' },
    ];

    render(
      <ThemeProvider>
        <SnackbarProvider>
          <InputOutputList
            inputOutputs={outputs}
            noValuesMessage="No Outputs"
            headerName="Output"
          />
        </SnackbarProvider>
      </ThemeProvider>
    );

    const renderedMessages = document.querySelectorAll('tbody > tr');
    expect(renderedMessages.length).toEqual(outputs.length);
  });
});
