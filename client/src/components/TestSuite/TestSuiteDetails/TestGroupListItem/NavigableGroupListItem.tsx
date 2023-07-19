import React, { FC } from 'react';
import useStyles from './styles';
import { Box, Divider, Link, List, ListItem, ListItemText, Typography } from '@mui/material';
import FolderIcon from '@mui/icons-material/Folder';
import { TestGroup } from '~/models/testSuiteModels';
import ResultIcon from '../ResultIcon';
import theme from '~/styles/theme';

interface NavigableGroupListItemProps {
  testGroup: TestGroup;
}

const NavigableGroupListItem: FC<NavigableGroupListItemProps> = ({ testGroup }) => {
  const { classes } = useStyles();

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
                    color="secondary"
                    href={`${location.pathname}#${testGroup.id}`}
                    data-testid="navigable-group-item"
                    sx={{ fontWeight: 'bold' }}
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
