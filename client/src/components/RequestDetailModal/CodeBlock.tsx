import React, { FC } from 'react';
import { Box, Card, CardContent, CardHeader, Collapse, Divider } from '@mui/material';
import { useEffectOnce } from '~/hooks/useEffectOnce';
import { RequestHeader } from '~/models/testSuiteModels';
import CollapseButton from '~/components/_common/CollapseButton';
import CopyButton from '~/components/_common/CopyButton';

import { formatBodyIfJSON } from './helpers';
import useStyles from './styles';
import lightTheme from '~/styles/theme';

export interface CodeBlockProps {
  body?: string | null;
  collapsedState?: boolean;
  headers?: RequestHeader[] | null | undefined;
  title?: string;
}

const CodeBlock: FC<CodeBlockProps> = ({ body, collapsedState = false, headers, title }) => {
  const { classes } = useStyles();
  const [collapsed, setCollapsed] = React.useState(collapsedState);
  const [jsonBody, setJsonBody] = React.useState<string>('');

  useEffectOnce(() => {
    if (body && body.length > 0) {
      setJsonBody(formatBodyIfJSON(body, headers));
    }
  });

  if (body && body.length > 0) {
    return (
      <Card variant="outlined" className={classes.codeblock} data-testid="code-block">
        <CardHeader
          subheader={title || 'Code'}
          sx={{ backgroundColor: lightTheme.palette.common.blueLightest, fontSize: 20 }}
          action={
            <Box display="flex">
              <CopyButton copyText={jsonBody} />
              <CollapseButton setCollapsed={setCollapsed} startState={collapsedState} />
            </Box>
          }
        />
        <Collapse in={!collapsed}>
          <Divider />
          <CardContent sx={{ pt: 0 }}>
            <pre data-testid="pre">
              <code data-testid="code" className={classes.code}>
                {jsonBody}
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
