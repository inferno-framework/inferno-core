import React, { FC, useEffect } from 'react';
import { Autocomplete, Box, Button, Card, Divider, TextField, Typography } from '@mui/material';
import { enqueueSnackbar } from 'notistack';
import { getTestSuiteRequirements } from '~/api/RequirementsApi';
import { Requirement, TestSuite } from '~/models/testSuiteModels';
import RequirementContent from '~/components/TestSuite/Requirements/RequirementContent';
import useStyles from './styles';

interface RequirementsProps {
  testSuite: TestSuite;
}

const Requirements: FC<RequirementsProps> = ({ testSuite }) => {
  const { classes } = useStyles();
  const [requirements, setRequirements] = React.useState<Requirement[]>([]);
  const [filters, setFilters] = React.useState<Record<string, string>>({});
  const [filteredRequirements, setFilteredRequirements] = React.useState<Requirement[]>([]);

  useEffect(() => {
    // Fetch requirements from API
    getTestSuiteRequirements(testSuite.id)
      .then((result) => {
        if (result.length > 0) {
          setRequirements(result);
          setFilteredRequirements(result);
        }
      })
      .catch((e: Error) => {
        enqueueSnackbar(`Error fetching specification requirements: ${e.message}`, {
          variant: 'error',
        });
      });
  }, []);

  const filterRequirements = (filters: Record<string, string>) => {
    let requirementsCopy = requirements;
    Object.entries(filters).forEach(([filterName, value]) => {
      if (!value || value === 'Any') return;
      requirementsCopy = requirementsCopy.filter(
        (requirement) => requirement[filterName as keyof Requirement] === value,
      );
    });
    setFilteredRequirements(requirementsCopy);
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
      {/* Filters */}
      <Box m={2} display="flex" justifyContent="space-between" overflow="auto">
        <Autocomplete
          value={filters.conformance ?? ''}
          size="small"
          options={['Any', 'MAY', 'SHALL', 'SHALL NOT', 'SHOULD', 'DEPRECATED']}
          renderInput={(params) => (
            <TextField {...params} label="Conformance" variant="standard" color="secondary" />
          )}
          onChange={(event, value) => {
            const newFilters = { ...filters, conformance: value || '' };
            setFilters(newFilters);
            filterRequirements(newFilters);
          }}
          sx={{ width: 200 }}
        />
        <Button
          color="secondary"
          variant="outlined"
          onClick={() => {
            setFilters({});
            setFilteredRequirements(requirements);
          }}
        >
          Reset Filters
        </Button>
      </Box>
      <Divider />
      <Box m={2} overflow="auto">
        {filteredRequirements.length > 0 ? (
          <RequirementContent requirements={filteredRequirements} />
        ) : (
          <Typography fontStyle="italic">No requirements found.</Typography>
        )}
      </Box>
      <Divider />
    </Card>
  );
};

export default Requirements;
