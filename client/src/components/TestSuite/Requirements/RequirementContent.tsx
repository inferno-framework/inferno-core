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
  view: 'page' | 'dialog';
  requirementToTests?: Map<string, string[]>;
}

const RequirementContent: FC<RequirementContentProps> = ({
  requirements,
  view = 'page',
  requirementToTests,
}) => {
  const { classes } = useStyles();
  const viewOnly = useTestSessionStore((state) => state.viewOnly);
  const viewOnlyUrl = viewOnly ? '/view' : '';

  // Reduce list of requirements into map of specification -> url -> list of requirements
  const requirementsByUrl = requirements.reduce(
    (acc, current) => {
      const specification = current.specification || current.id.split('@')[0];
      const url = current.url ?? '';
      if (acc[specification]) {
        if (acc[specification][url]) acc[specification][url].push(current);
        else acc[specification][url] = [current];
      } else {
        acc[specification] = { [url]: [current] };
      }
      return acc;
    },
    {} as Record<string, Record<string, Requirement[]>>,
  );

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

  const testLinks = (requirement: Requirement) => {
    const testLinksExist = requirementToTests && requirementToTests.size > 0;
    const testIds = requirementToTests?.get(requirement.id);
    if (testLinksExist) {
      return (
        <Box display="flex" px={1.5}>
          {requirement.not_tested_reason ? (
            <Typography
              display="inherit"
              variant="body2"
              sx={{ color: lightTheme.palette.common.orangeDark }}
            >
              {requirement.not_tested_reason}
            </Typography>
          ) : (
            <Typography ml={0} variant="body2" fontWeight="bold">
              {/* If no test ids, show empty set symbol */}
              Tests: {(!testIds || testIds.length === 0) && '\u2205'}
              {testIds?.map((id, i) => {
                return (
                  <span key={id}>
                    <Link variant="body2" href={`#${id}${viewOnlyUrl}`} color="secondary">
                      {id}
                    </Link>
                    {i !== testIds.length - 1 ? ', ' : ''} {/* Separate values with commas */}
                  </span>
                );
              })}
            </Typography>
          )}
        </Box>
      );
    }
  };

  return Object.entries(requirementsByUrl).map(
    ([specification, urlToRequirementsList], specificationIndex) =>
      Object.entries(urlToRequirementsList).map(([url, requirementsList]) => (
        <Box key={`${specification}-${url}`}>
          <Box>
            <Typography variant="h5" component="p" fontWeight="bold" sx={{ mt: 1 }}>
              {specification}
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
                  {/* If view is 'dialog,' then show nothing */}
                  {view === 'page' && testLinks(requirement)}
                </Stack>
              </Grid2>
            </Grid2>
          ))}
          {/* No divider if last section */}
          {specificationIndex !== Object.keys(requirementsByUrl).length - 1 && (
            <Divider sx={{ mt: 2 }} />
          )}
        </Box>
      )),
  );
};

export default RequirementContent;
