import React, { FC } from 'react';
import {
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableRow,
  Typography,
} from '@mui/material';
import ResultIcon from '~/components/TestSuite/TestSuiteDetails/ResultIcon';
import { Result } from '~/models/testSuiteModels';

export interface HelpModalProps {
  modalVisible: boolean;
  hideModal: () => void;
}

interface IconLegendRow {
  icon: string;
  label: string;
  description: string;
  optional?: boolean;
  pending?: boolean;
}

const HelpModal: FC<HelpModalProps> = ({ hideModal, modalVisible }) => {
  const iconLegend: IconLegendRow[] = [
    {
      icon: 'pass',
      label: 'Pass',
      description: 'A test passed',
    },
    {
      icon: 'pass',
      label: 'Pass - optional test',
      description: 'An optional test passed',
      optional: true,
    },
    {
      icon: 'fail',
      label: 'Fail',
      description: 'A test failed',
    },
    {
      icon: 'fail',
      label: 'Fail - optional test',
      description: 'An optional test failed - this will not affect overall count of passed tests',
      optional: true,
    },
    {
      icon: 'cancel',
      label: 'Cancel',
      description: 'Test was cancelled',
    },
    {
      icon: 'error',
      label: 'Error',
      description: 'An error occurred while running test',
    },
    {
      icon: 'skip',
      label: 'Skip',
      description: 'A test was skipped',
    },
    {
      icon: 'omit',
      label: 'Omit',
      description: 'A test was omitted and does not affect passed or failed scores',
    },
    {
      icon: 'wait',
      label: 'Wait',
      description: 'A test is waiting for user interaction',
    },
    {
      icon: 'pending',
      label: 'Pending',
      description: 'A test is being run',
      pending: true,
    },
    {
      icon: 'no result',
      label: 'No Result',
      description: 'A test has not been run',
    },
  ];

  return (
    <Dialog
      open={modalVisible}
      fullWidth={true}
      maxWidth="md"
      onClose={hideModal}
      data-testid="HelpModal"
      onKeyDown={(e) => e.stopPropagation()}
    >
      <DialogTitle>Help</DialogTitle>
      <Divider />
      <DialogContent>
        <Box pb={3}>
          <Typography component="h3" fontWeight="bold" sx={{ mb: 2 }}>
            Test Icon Legend
          </Typography>
          <Divider />
          <TableContainer component={Paper} elevation={0}>
            <Table size="small" aria-label="icon legend">
              <TableBody>
                {iconLegend.map((row) => (
                  <TableRow
                    key={row.label}
                    sx={{ '&:last-child td, &:last-child th': { border: 0 } }}
                  >
                    <TableCell sx={{ display: 'flex', alignItems: 'center', fontWeight: 'bold' }}>
                      <ResultIcon
                        result={
                          // Since we only need the icon appearance, the other required fields
                          // here are unnecessary
                          {
                            id: row.icon,
                            result: row.icon,
                            test_run_id: '',
                            test_session_id: '',
                            updated_at: '',
                            outputs: [],
                            optional: row.optional,
                          } as Result
                        }
                        isRunning={row.pending}
                      />
                      <Box px={1}>{row.label}</Box>
                    </TableCell>
                    <TableCell>{row.description}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button
          color="secondary"
          variant="contained"
          data-testid="cancel-button"
          onClick={hideModal}
          sx={{ fontWeight: 'bold' }}
        >
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default HelpModal;
