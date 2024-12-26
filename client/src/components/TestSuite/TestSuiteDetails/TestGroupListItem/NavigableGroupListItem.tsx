import React, { FC } from 'react';
import { Box, Divider, List, ListItem, ListItemText, Typography } from '@mui/material';
import FolderIcon from '@mui/icons-material/Folder';
import { Link } from 'react-router-dom';
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
  const viewOnly = useTestSessionStore((state) => state.viewOnly);

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
                    to={`#${testGroup.id}${viewOnly ? '/view' : ''}`}
                    data-testid="navigable-group-item"
                    className={classes.groupLink}
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
