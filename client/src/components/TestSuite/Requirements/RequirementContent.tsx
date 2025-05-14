import React, { FC } from 'react';
import { Box, Chip, Divider, Grid2, Link, Stack, Typography } from '@mui/material';
import { blue, grey, purple, red, teal } from '@mui/material/colors';
import { Requirement } from '~/models/testSuiteModels';
// import { useTestSessionStore } from '~/store/testSession';

interface RequirementContentProps {
  requirements: Requirement[];
}

const RequirementContent: FC<RequirementContentProps> = ({ requirements }) => {
  const requirementsByUrl = requirements.reduce(
    // Reduce list of requirements into map of url -> list of requirements
    (acc, current) => {
      const key = current.url ?? '';
      if (acc[key]) acc[key].push(current);
      else acc[key] = [current];
      return acc;
    },
    {} as Record<string, Requirement[]>,
  );
  // const viewOnly = useTestSessionStore((state) => state.viewOnly);
  // const viewOnlyUrl = viewOnly ? '/view' : '';

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
          backgroundColor: conformanceToColor[text.toLowerCase()] || grey[100],
          borderRadius: 1,
          fontWeight: 'bolder',
        }}
      />
    );
  };

  return Object.entries(requirementsByUrl).map(([url, requirementsList]) => (
    <Box key={url}>
      <Box pb={2}>
        <Link href={url} color="secondary">
          {url}
        </Link>
      </Box>
      {requirementsList.map((requirement) => (
        <Grid2 container spacing={2} mb={2} key={requirement.id}>
          <Grid2 size={{ xs: 4, sm: 3, md: 2 }}>
            <Stack>
              <Typography fontWeight="bold">{requirement.id}</Typography>
            </Stack>
          </Grid2>
          <Grid2 size="grow">
            <Stack>
              <Box px={1} mb={1} sx={{ borderLeft: `4px solid ${grey[100]}` }}>
                <Typography>{requirement.requirement}</Typography>
              </Box>
              <Box display="flex" px={1.5} mb={requirement.sub_requirements.length > 0 ? 1 : 0}>
                {conformanceChip(requirement.conformance)}
                {/* <Typography ml={4} fontWeight="bold">
                  Test:{' '}
                  <Link href={`#${requirement.id}${viewOnlyUrl}`} color="secondary">
                    {requirement.id}
                  </Link>
                </Typography> */}
              </Box>
              {/* Subrequirements */}
              {requirement.sub_requirements.length > 0 && (
                <Box display="flex" px={1.5}>
                  <Typography variant="body2">
                    <b>Sub-requirements:</b> {requirement.sub_requirements.join(', ')}
                  </Typography>
                </Box>
              )}
            </Stack>
          </Grid2>
        </Grid2>
      ))}
      {/* Empty URL is always last */}
      {url && <Divider />}
    </Box>
  ));
};

export default RequirementContent;
