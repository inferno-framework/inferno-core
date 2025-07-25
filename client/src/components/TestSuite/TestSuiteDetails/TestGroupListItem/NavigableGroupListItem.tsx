import React, { FC } from 'react';
import { Box, Divider, Link, List, ListItem, ListItemText, Typography } from '@mui/material';
import FolderIcon from '@mui/icons-material/Folder';
import { TestGroup } from '~/models/testSuiteModels';
import ResultIcon from '~/components/TestSuite/TestSuiteDetails/ResultIcon';
import { useTestSessionStore } from '~/store/testSession';
import theme from '~/styles/theme';
import useStyles from './styles';

interface NavigableGroupListItemProps {
  testGroup: TestGroup;
}

const NavigableGroupListItem: FC<NavigableGroupListItemProps> = ({ testGroup }) => {
  const { classes } = useStyles();
  const readOnly = useTestSessionStore((state) => state.readOnly);

  return (
    <>
      <Box display="flex" alignItems="center" px={2} py={1}>
        <Box display="inline-flex">
          {testGroup.run_as_group ? (
            <ResultIcon result={testGroup.result} isRunning={testGroup.is_running} />
          ) : (
            <FolderIcon sx={{ color: theme.palette.common.gray }} />
          )}
        </Box>
        <List sx={{ padding: '0 8px' }}>
          <ListItem sx={{ padding: 0 }}>
            <ListItemText
              primary={
                <>
                  {testGroup.short_id && (
                    <Typography className={classes.shortId}>{`${testGroup.short_id} `}</Typography>
                  )}
                  <Link
                    color="secondary.dark"
                    fontWeight="bold"
                    href={`${location.pathname}#${testGroup.id}${readOnly ? '/view' : ''}`}
                    data-testid="navigable-group-item"
                  >
                    {testGroup.title}
                  </Link>
                </>
              }
              secondary={testGroup.result?.result_message}
            />
          </ListItem>
        </List>
      </Box>
      <Divider />
    </>
  );
};

export default NavigableGroupListItem;
