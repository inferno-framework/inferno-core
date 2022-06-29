import { Container, Paper } from '@mui/material';
import React, { FC } from 'react';
import useStyles from './styles';
import { RequestHeader } from '~/models/testSuiteModels';

import { formatBodyIfJSON } from './helpers';

export interface CodeBlockProps {
  body?: string | null;
  headers?: RequestHeader[] | null | undefined;
}

const CodeBlock: FC<CodeBlockProps> = ({ body, headers }) => {
  const styles = useStyles();

  if (body && body.length > 0) {
    return (
      <Container
        component={Paper}
        variant="outlined"
        className={styles.codeblock}
        data-testid="code-block"
      >
        <pre data-testid="pre">
          <code data-testid="code">{formatBodyIfJSON(body, headers)}</code>
        </pre>
      </Container>
    );
  } else {
    return null;
  }
};

export default CodeBlock;
