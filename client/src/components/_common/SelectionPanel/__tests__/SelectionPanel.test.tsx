import React from 'react';
import { renderWithProviders, screen, waitFor } from '~/test-utils';
import { mockedSelectionPanelData } from '../__mocked_data__/mockData';
import SelectionPanel from '../SelectionPanel';
import { describe, expect, test, vi } from 'vitest';

describe('SelectionPanel component', () => {
  test('renders SelectionPanel for list options', () => {
    renderWithProviders(
      <SelectionPanel
        title="Selection Title"
        options={mockedSelectionPanelData.listOptions}
        setSelection={mockedSelectionPanelData.setSelected}
        submitAction={mockedSelectionPanelData.submitAction}
        submitText="Submit"
      />,
    );

    const options = screen.getAllByTestId('list-option');
    expect(options.length).toEqual(mockedSelectionPanelData.listOptions.length);
  });

  test('renders SelectionPanel for radio options', () => {
    renderWithProviders(
      <SelectionPanel
        title="Selection Title"
        options={mockedSelectionPanelData.radioOptions}
        setSelection={mockedSelectionPanelData.setSelected}
        submitAction={mockedSelectionPanelData.submitAction}
        submitText="Submit"
      />,
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

    const { user } = renderWithProviders(
      <SelectionPanel
        title="Selection Title"
        options={mockedSelectionPanelData.listOptions}
        setSelection={mockedSelectionPanelData.setSelected}
        submitAction={mockedSelectionPanelData.submitAction}
        submitText="Submit"
      />,
    );

    const submitButton = screen.getByText('Submit');
    expect(submitButton).toBeDisabled();

    const options = screen.getAllByTestId('list-option');
    await user.click(options[0]);

    expect(submitButton).toBeEnabled();
    await user.click(submitButton);
    await waitFor(() => expect(submitAction).toBeCalled());
  });

  test('clicking a radio option calls setSelection', async () => {
    const setSelection = vi.spyOn(mockedSelectionPanelData, 'setSelected');

    const { user } = renderWithProviders(
      <SelectionPanel
        title="Selection Title"
        options={mockedSelectionPanelData.radioOptions}
        setSelection={mockedSelectionPanelData.setSelected}
        submitAction={mockedSelectionPanelData.submitAction}
        submitText="Submit"
      />,
    );

    const radioButtons = screen.getAllByTestId('radio-option-button');
    await user.click(radioButtons[1]);

    expect(setSelection).toBeCalled();
  });
});
