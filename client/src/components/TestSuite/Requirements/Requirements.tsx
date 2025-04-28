import React, { FC } from 'react';
import { Box, Card, Divider, Typography } from '@mui/material';
import { Requirement, TestSuite } from '~/models/testSuiteModels';
import useStyles from './styles';
import RequirementContent from './RequirementContent';

interface RequirementsProps {
  testSuite: TestSuite;
}

const Requirements: FC<RequirementsProps> = ({ testSuite }) => {
  const { classes } = useStyles();

  const requirementTestObject: Requirement = {
    actor: 'client',
    conformance: 'deprecated',
    description: 'test description',
    testId: '1.1',
  };

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
        <RequirementContent requirements={[requirementTestObject]} />
      </Box>
      <Divider />
    </Card>
  );
};

export default Requirements;
