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

  return requirements.map((requirement, index) => (
    <Grid2 container spacing={2} pb={2} key={index}>
      <Grid2 size={{ xs: 4, sm: 3, md: 2 }}>
        <Stack>
          <Typography fontWeight="bold">Requirement {index + 1}:</Typography>
          <Typography>{requirement.actor.toUpperCase()}</Typography>
        </Stack>
      </Grid2>
      <Grid2 size="grow">
        <Stack>
          <Box px={1} pb={1} sx={{ borderLeft: `4px solid ${grey[100]}` }}>
            <Typography>{requirement.requirement}</Typography>
          </Box>
          <Box display="flex" px={1.5}>
            {conformanceChip(requirement.conformance)}
            <Typography ml={4} fontWeight="bold">
              Test:{' '}
              <Link href={`#${requirement.id}${viewOnlyUrl}`} color="secondary">
                {requirement.id}
              </Link>
            </Typography>
          </Box>
        </Stack>
      </Grid2>
    </Grid2>
  ));
};

export default RequirementContent;
