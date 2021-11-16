import { Container, Paper } from '@mui/material';
import React, { FC } from 'react';
import useStyles from './styles';

export interface CodeBlockProps {
  body: string | undefined;
}

const CodeBlock: FC<CodeBlockProps> = ({ body }) => {
  const styles = useStyles();

  if (body && body.length > 0) {
    return (
      <Container component={Paper} variant="outlined" className={styles.codeblock}>
        <pre>
          <code>{body}</code>
        </pre>
      </Container>
    );
  } else {
    return null;
  }
};

export default CodeBlock;
