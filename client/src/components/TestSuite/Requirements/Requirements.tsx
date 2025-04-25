import React, { FC } from 'react';
import { Box, Card, Divider, Grid2, Typography } from '@mui/material';
import { Requirement, TestSuite } from '~/models/testSuiteModels';
import useStyles from './styles';

interface RequirementsProps {
  testSuite: TestSuite;
}

const Requirements: FC<RequirementsProps> = ({ testSuite }) => {
  const { classes } = useStyles();

  const requirementTestObject: Requirement = {
    actor: 'CLIENT',
    conformance: 'SHALL',
    description: 'test description',
    testId: '1.04',
  };

  const requirementRow = (requirement: Requirement) => (
    <>
      <Grid2 container spacing={2}>
        <Grid2 size={4}>
          <Box>{requirement.actor}</Box>
        </Grid2>
        <Grid2 size="grow">
          <Box>size=grow</Box>
        </Grid2>
      </Grid2>
    </>
  );

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
        {requirementRow(requirementTestObject)}
      </Box>
      <Divider />
    </Card>
  );
};

export default Requirements;
