import React, { FC } from 'react';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { Box, Chip, Divider, Grid2, Link, Stack, Typography } from '@mui/material';
import { blue, grey, purple, red, teal } from '@mui/material/colors';
import { Requirement } from '~/models/testSuiteModels';
import lightTheme from '~/styles/theme';
import { useTestSessionStore } from '~/store/testSession';
import useStyles from './styles';

interface RequirementContentProps {
  requirements: Requirement[];
  requirementToTests?: Map<string, string[]>;
}

const RequirementContent: FC<RequirementContentProps> = ({ requirements, requirementToTests }) => {
  const { classes } = useStyles();
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
  const viewOnly = useTestSessionStore((state) => state.viewOnly);
  const viewOnlyUrl = viewOnly ? '/view' : '';

  // Nested components
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

  /* Subrequirements and test links */
  const requirementDetails = (requirement: Requirement) => {
    const testLinksExist = requirementToTests && requirementToTests?.size > 0;
    const testIds = requirementToTests?.get(requirement.id);
    if (testLinksExist && testIds)
      return (
        <Box display="flex" px={1.5}>
          <Typography ml={0} variant="body2" fontWeight="bold">
            Test:{' '}
            {testIds?.map((id, i) => (
              <span key={id}>
                <Link variant="body2" href={`#${id}${viewOnlyUrl}`} color="secondary">
                  {id}
                </Link>
                {i !== testIds.length - 1 ? ', ' : ''} {/* Separate values with commas */}
              </span>
            ))}
          </Typography>
        </Box>
      );
    return (
      <Box display="flex" px={1.5}>
        <Typography ml={0} variant="body2" sx={{ color: lightTheme.palette.common.orangeDark }}>
          Not tested
        </Typography>
      </Box>
    );
  };

  return Object.entries(requirementsByUrl).map(([url, requirementsList], index) => (
    <Box key={url}>
      <Box>
        {requirementsList[0] && (
          <Typography variant="h5" component="p" fontWeight="bold" sx={{ mt: 1 }}>
            {/* Pull the specification out from the first requirement */}
            {requirementsList[0].id.split('@')[0]}
          </Typography>
        )}
        {url ? (
          <Link href={url} color="secondary">
            {url}
          </Link>
        ) : (
          <Typography color={lightTheme.palette.common.gray}>(no link available)</Typography>
        )}
      </Box>
      {requirementsList.map((requirement) => (
        <Grid2 container spacing={2} mt={2} key={requirement.id}>
          <Grid2>
            <Typography fontWeight="bold">{requirement.id.split('@').slice(-1)}</Typography>
          </Grid2>
          <Grid2>{conformanceChip(requirement.conformance)}</Grid2>
          <Grid2 size="grow">
            <Stack>
              <Box px={1} mb={1} sx={{ borderLeft: `4px solid ${grey[100]}` }}>
                <Markdown remarkPlugins={[remarkGfm]} className={classes.markdown}>
                  {requirement.requirement}
                </Markdown>
              </Box>
              {requirementDetails(requirement)}
            </Stack>
          </Grid2>
        </Grid2>
      ))}
      {/* No divider if last section */}
      {index !== Object.keys(requirementsByUrl).length - 1 && <Divider sx={{ mt: 2 }} />}
    </Box>
  ));
};

export default RequirementContent;
