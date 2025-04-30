import React, { FC } from 'react';
import { Box, Card, Divider, Typography } from '@mui/material';
import { enqueueSnackbar } from 'notistack';
import { getTestSuiteRequirements } from '~/api/RequirementsApi';
import { Requirement, TestSuite } from '~/models/testSuiteModels';
import useStyles from './styles';
import RequirementContent from './RequirementContent';

interface RequirementsProps {
  testSuite: TestSuite;
}

const Requirements: FC<RequirementsProps> = ({ testSuite }) => {
  const { classes } = useStyles();
  const [requirements, setRequirements] = React.useState<Requirement[]>([]);
  const [triedFetchRequirements, setTriedFetchRequirements] = React.useState<boolean>(false);

  // Fetch requirements from API
  if (!triedFetchRequirements) {
    getTestSuiteRequirements(testSuite.id)
      .then((result) => {
        if (result.length > 0) {
          console.log(result);
          setRequirements(result);
        } else {
          enqueueSnackbar('Failed to fetch specification requirements', { variant: 'error' });
        }
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Error fetching specification requirements: ${e.message}`, {
          variant: 'error',
        });
      });
    setTriedFetchRequirements(true);
  }

  return (
    <Card variant="outlined">
      <Box className={classes.header}>
        <span className={classes.headerText}>
          <Typography color="text.primary" className={classes.currentItem} component="div">
            {testSuite.title} Specification Requirements
          </Typography>
        </span>
      </Box>
      <Box m={2} overflow="auto">
        header
      </Box>
      <Divider />
      <Box m={2} overflow="auto">
        {/* <Typography fontWeight="bold">These scenarios test the following requirements:</Typography>
        <Typography variant="h5" component="p" fontWeight="bold" sx={{ mb: 2 }}>
          test
        </Typography> */}
        <RequirementContent requirements={requirements} />
      </Box>
      <Divider />
    </Card>
  );
};

export default Requirements;
