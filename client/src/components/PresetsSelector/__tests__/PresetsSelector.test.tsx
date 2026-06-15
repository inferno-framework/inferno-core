import React from 'react';
import { BrowserRouter } from 'react-router';
import { SnackbarProvider } from 'notistack';
import { describe, expect, test, vi, afterEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ThemeProvider from '~/components/ThemeProvider';
import PresetsSelector from '../PresetsSelector';
import { presets } from '../__mocked_data__/mockData';
import * as TestSessionApi from '~/api/TestSessionApi';
import { PresetSummary } from '~/models/testSuiteModels';

describe('The PresetsSelector Component', () => {
  afterEach(() => vi.restoreAllMocks());
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

  test('sorts presets ascending by title regardless of input order', async () => {
    vi.spyOn(TestSessionApi, 'applyPreset').mockResolvedValue(null);

    const reversedPresets: PresetSummary[] = [
      { id: 'z', title: 'Zeta' },
      { id: 'a', title: 'Alpha' },
    ];

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <PresetsSelector
              presets={reversedPresets}
              testSessionId="test-id"
              getSessionData={() => {}}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>,
    );

    await userEvent.click(screen.getByRole('combobox'));

    const options = screen.getAllByRole('option');
    // options[0] is always "None"; then ascending: Alpha before Zeta
    expect(options[1]).toHaveTextContent('Alpha');
    expect(options[2]).toHaveTextContent('Zeta');
  });

  test('renders all presets when titles are equal (sort comparator returns 0)', async () => {
    const duplicatePresets: PresetSummary[] = [
      { id: '1', title: 'Same Preset' },
      { id: '2', title: 'Same Preset' },
    ];

    render(
      <BrowserRouter>
        <ThemeProvider>
          <SnackbarProvider>
            <PresetsSelector
              presets={duplicatePresets}
              testSessionId="test-id"
              getSessionData={() => {}}
            />
          </SnackbarProvider>
        </ThemeProvider>
      </BrowserRouter>,
    );

    await userEvent.click(screen.getByRole('combobox'));

    const options = screen.getAllByRole('option');
    // "None" + two identical-title presets
    expect(options).toHaveLength(3);
  });
});
