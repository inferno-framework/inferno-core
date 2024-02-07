import React, { FC } from 'react';
import { Box, Card, CardContent, CardHeader, Collapse, Divider } from '@mui/material';
import { RequestHeader } from '~/models/testSuiteModels';
import CopyButton from '~/components/_common/CopyButton';

import { formatBodyIfJSON } from './helpers';
import useStyles from './styles';
import CollapseButton from '../_common/CollapseButton';

export interface CodeBlockProps {
  body?: string | null;
  collapsedState?: boolean;
  headers?: RequestHeader[] | null | undefined;
  title: string;
}

const CodeBlock: FC<CodeBlockProps> = ({ body, collapsedState = false, headers, title }) => {
  const { classes } = useStyles();
  const [collapsed, setCollapsed] = React.useState(collapsedState);

  if (body && body.length > 0) {
    return (
      <Card variant="outlined" className={classes.codeblock} data-testid="code-block">
        <CardHeader
          subheader={title}
          action={
            <Box display="flex">
              <CopyButton copyText={formatBodyIfJSON(body, headers)} size="small" />
              <CollapseButton
                setCollapsed={setCollapsed}
                startState={collapsedState}
                size="small"
              />
            </Box>
          }
        />
        <Collapse in={!collapsed}>
          <Divider />
          <CardContent sx={{ pt: 0 }}>
            <pre data-testid="pre">
              <code data-testid="code" className={classes.code}>
                {formatBodyIfJSON(body, headers)}
              </code>
            </pre>
          </CardContent>
        </Collapse>
      </Card>
    );
  } else {
    return null;
  }
};

export default CodeBlock;
