import React, { FC } from 'react';
import { Box, Chip, Grid2, Link, Stack, Typography } from '@mui/material';
import { blue, grey, purple, red, teal } from '@mui/material/colors';
import { Requirement } from '~/models/testSuiteModels';
import { useTestSessionStore } from '~/store/testSession';

interface RequirementContentProps {
  requirements: Requirement[];
}

const RequirementContent: FC<RequirementContentProps> = ({ requirements }) => {
  const viewOnly = useTestSessionStore((state) => state.viewOnly);
  const viewOnlyUrl = viewOnly ? '/view' : '';

  const conformanceChip = (text: string) => {
    const conformanceToColor: Record<string, string> = {
      shall: blue[50],
      'shall not': red[100],
      should: teal[50],
      may: purple[50],
      deprecated: grey[300],
    };
    return (
      <Chip
        size="small"
        label={text.toUpperCase()}
        sx={{
          backgroundColor: conformanceToColor[text] || grey[100],
          borderRadius: 1,
          fontWeight: 'bolder',
        }}
      />
    );
  };

  const requirementRow = (requirement: Requirement, index: number) => (
    <Grid2 container spacing={2} key={index}>
      <Grid2 size={{ xs: 4, sm: 3, md: 2 }}>
        <Stack>
          <Typography fontWeight="bold">Requirement {index + 1}:</Typography>
          <Typography>{requirement.actor.toUpperCase()}</Typography>
        </Stack>
      </Grid2>
      <Grid2 size="grow">
        <Stack>
          <Box px={1} pb={1} sx={{ borderLeft: `4px solid ${grey[100]}` }}>
            <Typography>{requirement.description}</Typography>
          </Box>
          <Box display="flex" px={1.5}>
            {conformanceChip(requirement.conformance)}
            <Typography ml={4} fontWeight="bold">
              Test:{' '}
              <Link href={`#${requirement.testId}${viewOnlyUrl}`} color="secondary">
                {requirement.testId}
              </Link>
            </Typography>
          </Box>
        </Stack>
      </Grid2>
    </Grid2>
  );

  return (
    <Box overflow="auto">
      <Typography fontWeight="bold">These scenarios test the following requirements:</Typography>
      <Typography variant="h5" component="p" fontWeight="bold" sx={{ mb: 2 }}>
        test
      </Typography>
      {requirements.map((requirement, i) => requirementRow(requirement, i))}
    </Box>
  );
};

export default RequirementContent;
