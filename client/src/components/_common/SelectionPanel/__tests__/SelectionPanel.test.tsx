import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { render, screen, waitFor } from '@testing-library/react';
import ThemeProvider from 'components/ThemeProvider';
import { mockedSelectionPanelData } from '../__mocked_data__/mockData';
import SelectionPanel from '../SelectionPanel';
import userEvent from '@testing-library/user-event';
import { vi } from 'vitest';

describe('SelectionPanel component', () => {
  test('renders SelectionPanel for list options', () => {
    render(
      <BrowserRouter>
        <ThemeProvider>
          <SelectionPanel
            title="Selection Title"
            options={mockedSelectionPanelData.listOptions}
            setSelection={mockedSelectionPanelData.setSelected}
            submitAction={mockedSelectionPanelData.submitAction}
            submitText="Submit"
          />
        </ThemeProvider>
      </BrowserRouter>
    );

    const options = screen.getAllByTestId('list-option');
    expect(options.length).toEqual(mockedSelectionPanelData.listOptions.length);
  });

  test('renders SelectionPanel for radio options', () => {
    render(
      <BrowserRouter>
        <ThemeProvider>
          <SelectionPanel
            title="Selection Title"
            options={mockedSelectionPanelData.radioOptions}
            setSelection={mockedSelectionPanelData.setSelected}
            submitAction={mockedSelectionPanelData.submitAction}
            submitText="Submit"
          />
        </ThemeProvider>
      </BrowserRouter>
    );

    const options = screen.getAllByTestId('radio-option-group');
    expect(options.length).toEqual(mockedSelectionPanelData.radioOptions.length);

    const radioButtonCount = mockedSelectionPanelData.radioOptions
      .map((option) => option.list_options)
      .flat().length;
    const buttons = screen.getAllByTestId('radio-option-button');
    expect(buttons.length).toEqual(radioButtonCount);
  });

  test('clicking submit calls submitAction', async () => {
    const submitAction = vi.spyOn(mockedSelectionPanelData, 'submitAction');

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SelectionPanel
            title="Selection Title"
            options={mockedSelectionPanelData.listOptions}
            setSelection={mockedSelectionPanelData.setSelected}
            submitAction={mockedSelectionPanelData.submitAction}
            submitText="Submit"
          />
        </ThemeProvider>
      </BrowserRouter>
    );

    const submitButton = screen.getByText('Submit');
    userEvent.click(submitButton);
    expect(submitButton).toBeDisabled();
    expect(submitAction).toBeCalledTimes(0); // should be disabled with no selection

    const options = screen.getAllByTestId('list-option');
    userEvent.click(options[0]); // select first option
    expect(submitButton).toBeEnabled();
    userEvent.click(submitButton);
    await waitFor(() => expect(submitAction).toBeCalled());
  });
});
