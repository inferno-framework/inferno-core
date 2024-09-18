import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { SnackbarProvider } from 'notistack';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ThemeProvider from '~/components/ThemeProvider';
import PresetsSelector from '../PresetsSelector';
import { presets } from '../__mocked_data__/mockData';
import { describe, expect, test } from 'vitest';

describe('The PresetsSelector Component', () => {
  test('renders empty PresetsSelector', () => {
    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <PresetsSelector presets={[]} testSessionId="test-id" getSessionData={() => {}} />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>,
    );

    const selectionElement = screen.getByRole('combobox');
    expect(selectionElement).toBeInTheDocument();
  });

  test('renders PresetsSelector with options', () => {
    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <PresetsSelector presets={presets} testSessionId="test-id" getSessionData={() => {}} />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>,
    );

    const selectionElement = screen.getByRole('combobox');
    expect(selectionElement).toBeInTheDocument();
  });

  test('selects a preset', async () => {
    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <PresetsSelector presets={presets} testSessionId="test-id" getSessionData={() => {}} />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>,
    );

    const selectionElement = screen.getByRole('combobox');
    await userEvent.click(selectionElement);

    const presetChoice = screen.getByText('Preset One');
    await userEvent.click(presetChoice);

    expect(selectionElement.textContent).toEqual('Preset One');
  });
});
