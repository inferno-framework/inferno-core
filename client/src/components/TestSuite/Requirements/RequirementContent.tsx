import React, { FC } from 'react';
import { Box, Chip, Divider, Grid2, Link, Stack, Typography } from '@mui/material';
import { blue, grey, purple, red, teal } from '@mui/material/colors';
import { Requirement } from '~/models/testSuiteModels';
import lightTheme from '~/styles/theme';
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
        <Typography variant="h5" component="p" fontWeight="bold" sx={{ mb: 1 }}>
          {/* Pull the specification out from the first requirement */}
          {requirementsList[0].id.split('@')[0]}
        </Typography>
        {url ? (
          <Link href={url} color="secondary">
            {url}
          </Link>
        ) : (
          <Typography color={lightTheme.palette.common.gray}>(no link available)</Typography>
        )}
      </Box>
      {requirementsList.map((requirement) => (
        <Grid2 container spacing={2} mb={2} key={requirement.id}>
          <Grid2>
            <Typography fontWeight="bold">{requirement.id.split('@').slice(-1)}</Typography>
          </Grid2>
          <Grid2>{conformanceChip(requirement.conformance)}</Grid2>
          <Grid2 size="grow">
            <Stack>
              <Box px={1} mb={1} sx={{ borderLeft: `4px solid ${grey[100]}` }}>
                <Typography>{requirement.requirement}</Typography>
              </Box>
              {/* <Typography ml={1.5} fontWeight="bold">
                Test:{' '}
                <Link href={`#${requirement.id}${viewOnlyUrl}`} color="secondary">
                  test url placeholder
                </Link>
              </Typography> */}
              {/* Subrequirements */}
              {requirement.sub_requirements.length > 0 && (
                <Box display="flex" px={1.5}>
                  <Typography variant="body2">
                    <b>Sub-requirements:</b>{' '}
                    {requirement.sub_requirements
                      .map((subRequirement) => subRequirement.split('@').slice(-1))
                      .join(', ')}
                  </Typography>
                </Box>
              )}
            </Stack>
          </Grid2>
        </Grid2>
      ))}
      {/* Empty URL is always last */}
      {url && <Divider sx={{ mb: 2 }} />}
    </Box>
  ));
};

export default RequirementContent;
