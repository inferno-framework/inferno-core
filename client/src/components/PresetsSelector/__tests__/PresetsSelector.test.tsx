import React from 'react';
import { describe, expect, test, vi, afterEach } from 'vitest';
import { screen } from '~/test-utils';
import { renderWithProviders } from '~/test-utils';
import PresetsSelector from '../PresetsSelector';
import { presets } from '../__mocked_data__/mockData';
import * as TestSessionApi from '~/api/TestSessionApi';
import { PresetSummary } from '~/models/testSuiteModels';

describe('The PresetsSelector Component', () => {
  afterEach(() => vi.restoreAllMocks());

  test('renders empty PresetsSelector', () => {
    renderWithProviders(<PresetsSelector presets={[]} testSessionId="test-id" getSessionData={() => {}} />);
    expect(screen.getByRole('combobox')).toBeInTheDocument();
  });

  test('renders PresetsSelector with options', () => {
    renderWithProviders(<PresetsSelector presets={presets} testSessionId="test-id" getSessionData={() => {}} />);
    expect(screen.getByRole('combobox')).toBeInTheDocument();
  });

  test('selects a preset', async () => {
    const { user } = renderWithProviders(
      <PresetsSelector presets={presets} testSessionId="test-id" getSessionData={() => {}} />,
    );

    const selectionElement = screen.getByRole('combobox');
    await user.click(selectionElement);

    const presetChoice = screen.getByText('Preset One');
    await user.click(presetChoice);

    expect(selectionElement.textContent).toEqual('Preset One');
  });

  test('sorts presets ascending by title regardless of input order', async () => {
    vi.spyOn(TestSessionApi, 'applyPreset').mockResolvedValue(null);

    const reversedPresets: PresetSummary[] = [
      { id: 'z', title: 'Zeta' },
      { id: 'a', title: 'Alpha' },
    ];

    const { user } = renderWithProviders(
      <PresetsSelector
        presets={reversedPresets}
        testSessionId="test-id"
        getSessionData={() => {}}
      />,
    );

    await user.click(screen.getByRole('combobox'));

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

    const { user } = renderWithProviders(
      <PresetsSelector
        presets={duplicatePresets}
        testSessionId="test-id"
        getSessionData={() => {}}
      />,
    );

    await user.click(screen.getByRole('combobox'));

    const options = screen.getAllByRole('option');
    // "None" + two identical-title presets
    expect(options).toHaveLength(3);
  });
});
