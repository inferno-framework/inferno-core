import React from 'react';
import { BrowserRouter } from 'react-router';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { SnackbarProvider } from 'notistack';
import ThemeProvider from 'components/ThemeProvider';
import RequirementsModalButton from '../RequirementsModalButton';
import * as RequirementsApi from '~/api/RequirementsApi';
import { Requirement, Runnable } from '~/models/testSuiteModels';

const mockRequirement: Requirement = {
  id: 'req-1',
  requirement: 'SHALL do something',
  conformance: 'SHALL',
  actor: 'Client',
  conditionality: 'false',
  subrequirements: [],
};

const runnableWithRequirements: Runnable = {
  id: 'runnable-1',
  title: 'Test Group',
  inputs: [],
  verifies_requirements: ['req-1'],
};

function wrap(runnable: Runnable) {
  return render(
    <BrowserRouter>
      <ThemeProvider>
        <SnackbarProvider>
          <RequirementsModalButton runnable={runnable} />
        </SnackbarProvider>
      </ThemeProvider>
    </BrowserRouter>,
  );
}

describe('RequirementsModalButton', () => {
  afterEach(() => vi.restoreAllMocks());

  it('renders the link button', () => {
    wrap(runnableWithRequirements);
    expect(screen.getByText('View Specification Requirements')).toBeInTheDocument();
  });

  it('fetches requirements and opens the modal on click', async () => {
    vi.spyOn(RequirementsApi, 'getSingleRequirement').mockResolvedValue(mockRequirement);

    wrap(runnableWithRequirements);
    await userEvent.click(screen.getByText('View Specification Requirements'));

    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument();
    });
    expect(RequirementsApi.getSingleRequirement).toHaveBeenCalledWith('req-1');
  });

  it('displays fetched requirement text in the modal', async () => {
    vi.spyOn(RequirementsApi, 'getSingleRequirement').mockResolvedValue(mockRequirement);

    wrap(runnableWithRequirements);
    await userEvent.click(screen.getByText('View Specification Requirements'));

    await waitFor(() => {
      expect(screen.getByText('SHALL do something')).toBeInTheDocument();
    });
  });

  it('shows "No requirements found." when fetch returns null', async () => {
    vi.spyOn(RequirementsApi, 'getSingleRequirement').mockResolvedValue(null);

    wrap(runnableWithRequirements);
    await userEvent.click(screen.getByText('View Specification Requirements'));

    await waitFor(() => {
      expect(screen.getByText('No requirements found.')).toBeInTheDocument();
    });
  });

  it('closes the modal when the Close button is clicked', async () => {
    vi.spyOn(RequirementsApi, 'getSingleRequirement').mockResolvedValue(mockRequirement);

    wrap(runnableWithRequirements);
    await userEvent.click(screen.getByText('View Specification Requirements'));
    await waitFor(() => expect(screen.getByRole('dialog')).toBeInTheDocument());

    await userEvent.click(screen.getByTestId('cancel-button'));
    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
  });

  it('shows an error snackbar when the API call rejects', async () => {
    vi.spyOn(RequirementsApi, 'getSingleRequirement').mockRejectedValue(new Error('API failure'));

    wrap(runnableWithRequirements);
    await userEvent.click(screen.getByText('View Specification Requirements'));

    await waitFor(() => {
      expect(screen.getByText(/Error fetching specification requirements/)).toBeInTheDocument();
    });
  });
});
