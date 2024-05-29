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
  headers?: RequestHeader[] | null | undefined;
  title?: string;
}

const CodeBlock: FC<CodeBlockProps> = ({ body, headers, title }) => {
  const { classes } = useStyles();
  const [collapsed, setCollapsed] = React.useState(true);
  const [jsonBody, setJsonBody] = React.useState<string>('');

  useEffectOnce(() => {
    if (body && body.length > 0) {
      setJsonBody(formatBodyIfJSON(body, headers));
    }
  });

  const bodyLength = body?.split('\n').length || 0;
  const fullTitle = `${title || 'Code'} (${bodyLength} line${bodyLength === 1 ? '' : 's'})`;

  if (body && body.length > 0) {
    return (
      <Card variant="outlined" className={classes.codeBlock} data-testid="code-block">
        <CardHeader
          title={fullTitle}
          titleTypographyProps={{ sx: { fontSize: 20 } }}
          action={
            <Box display="flex">
              <CopyButton copyText={jsonBody} />
              <CollapseButton setCollapsed={setCollapsed} collapsed={collapsed} />
            </Box>
          }
          onClick={() => setCollapsed(!collapsed)}
          className={classes.codeBlockHeader}
          sx={{
            backgroundColor: collapsed ? 'unset' : lightTheme.palette.common.blueLightest,
          }}
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
