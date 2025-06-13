import React, { FC, useEffect } from 'react';
import { Autocomplete, Box, Button, Card, Divider, TextField, Typography } from '@mui/material';
import { Requirement } from '~/models/testSuiteModels';
import RequirementContent from '~/components/TestSuite/Requirements/RequirementContent';
import useStyles from './styles';

interface RequirementsProps {
  requirements: Requirement[];
  requirementToTests: Map<string, string[]>;
  testSuiteTitle: string;
}

const Requirements: FC<RequirementsProps> = ({
  requirements,
  requirementToTests,
  testSuiteTitle,
}) => {
  const { classes } = useStyles();
  const [filters, setFilters] = React.useState<Record<string, string>>({});
  const [filteredRequirements, setFilteredRequirements] =
    React.useState<Requirement[]>(requirements);

  const conformances = ['Any', 'MAY', 'SHALL', 'SHALL NOT', 'SHOULD'];

  // Requirements should never change once the session has been loaded, but if it does,
  // reset filters. This is also required to handle effects on session load.
  useEffect(() => {
    setFilters({});
    setFilteredRequirements(requirements);
  }, [requirements]);

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
            {testSuiteTitle} Specification Requirements
          </Typography>
        </span>
      </Box>
      {/* Filters */}
      <Box m={2} display="flex" justifyContent="space-between" overflow="auto">
        <Autocomplete
          value={filters.conformance ?? ''}
          size="small"
          options={conformances}
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
          <RequirementContent
            requirements={filteredRequirements}
            requirementToTests={requirementToTests}
          />
        ) : (
          <Typography fontStyle="italic">No requirements found.</Typography>
        )}
      </Box>
    </Card>
  );
};

export default Requirements;
